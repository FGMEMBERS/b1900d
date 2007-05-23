####    Two Generator electrical system    #### 
####    Syd Adams    ####
#### Based on Curtis Olson's nasal electrical code ####

var last_time = 0.0;
var vbus_volts = 0.0;
var ammeter_ave = 0.0;

FDM = 0;
OutPuts = props.globals.getNode("/systems/electrical/outputs",1); 
Volts = props.globals.getNode("/systems/electrical/volts",1);
Amps = props.globals.getNode("/systems/electrical/amps",1);
BATT = props.globals.getNode("/controls/electric/battery-switch",1);
L_ALT = props.globals.getNode("/controls/electric/engine[0]/generator",1);
R_ALT = props.globals.getNode("/controls/electric/engine[1]/generator",1);
EXT  = props.globals.getNode("/controls/electric/external-power",1); 
NORM = 0.0357;
INSTR_DIMMER = props.globals.getNode("/controls/lighting/instruments-norm",1);
EFIS_DIMMER = props.globals.getNode("/controls/lighting/efis-norm",1);
ENG_DIMMER = props.globals.getNode("/controls/lighting/engines-norm",1);
PANEL_DIMMER = props.globals.getNode("/controls/lighting/panel-norm",1);

strobe_switch = props.globals.getNode("controls/lighting/strobe", 1);
aircraft.light.new("controls/lighting/strobe-state", [0.05, 1.30], strobe_switch);
beacon_switch = props.globals.getNode("controls/lighting/beacon", 1);
aircraft.light.new("controls/lighting/beacon-state", [1.0, 1.0], beacon_switch);

Battery = {
    new : func {
    m = { parents : [Battery] };
            m.ideal_volts = arg[0];
            m.ideal_amps = arg[1];
            m.amp_hours = arg[2];
            m.charge_percent = arg[3]; 
            m.charge_amps = arg[4];
    return m;
    },
    
    apply_load : func {
        var amphrs_used = arg[0] * arg[1] / 3600.0;
        percent_used = amphrs_used / me.amp_hours;
        me.charge_percent -= percent_used;
        if ( me.charge_percent < 0.0 ) {
            me.charge_percent = 0.0;
        } elsif ( me.charge_percent > 1.0 ) {
        me.charge_percent = 1.0;
        }
        return me.amp_hours * me.charge_percent;
    },

    get_output_volts : func {
    x = 1.0 - me.charge_percent;
    tmp = -(3.0 * x - 1.0);
    factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
    return me.ideal_volts * factor;
    },

    get_output_amps : func {
    x = 1.0 - me.charge_percent;
    tmp = -(3.0 * x - 1.0);
    factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
    return me.ideal_amps * factor;
    }
};	

Alternator = {
    new : func {
    m = { parents : [Alternator] };
            m.rpm_source =  props.globals.getNode(arg[0],1);
            m.rpm_threshold = arg[1];
            m.ideal_volts = arg[2];
            m.ideal_amps = arg[3];
          return m;
    },

    apply_load : func( amps, dt) {
    var factor = me.rpm_source.getValue() / me.rpm_threshold;
    if ( factor > 1.0 ){factor = 1.0;}
    available_amps = me.ideal_amps * factor;
    return available_amps - amps;
    },

    get_output_volts : func {
    var factor = me.rpm_source.getValue() / me.rpm_threshold;
    if ( factor > 1.0 ) {
        factor = 1.0;
        }
    return me.ideal_volts * factor;
    },

    get_output_amps : func {
    var factor = me.rpm_source.getValue() / me.rpm_threshold;
    if ( factor > 1.0 ) {
        factor = 1.0;
        }
    return me.ideal_amps * factor;
    }
};
#var battery = Battery.new(volts,amps,amp_hours,charge_percent,charge_amps);

var battery = Battery.new(24,30,34,1.0,7.0);

# var alternator = Alternator.new("rpm-source",rpm_threshold,volts,amps);

alternator1 = Alternator.new("/engines/engine[0]/rpm",500.0,28.0,60.0);
alternator2 = Alternator.new("/engines/engine[1]/rpm",500.0,28.0,60.0);

#####################################
setlistener("/sim/signals/fdm-initialized", func {
    props.globals.getNode("/controls/electric/external-power",1).setBoolValue(0);
    props.globals.getNode("/controls/anti-ice/prop-heat",1).setBoolValue(0);
    props.globals.getNode("/controls/anti-ice/pitot-heat",1).setBoolValue(0);
    props.globals.getNode("/controls/lighting/landing-lights[0]",1).setBoolValue(0);
    props.globals.getNode("/controls/lighting/landing-lights[1]",1).setBoolValue(0);
    props.globals.getNode("/controls/lighting/beacon",1).setBoolValue(0);
    props.globals.getNode("/controls/lighting/nav-lights",1).setBoolValue(0);
    props.globals.getNode("/controls/lighting/cabin-lights",1).setBoolValue(0);
    props.globals.getNode("/controls/lighting/wing-lights",1).setBoolValue(0);
    props.globals.getNode("/controls/lighting/recog-lights",1).setBoolValue(0);
    props.globals.getNode("/controls/lighting/logo-lights",1).setBoolValue(0);
    props.globals.getNode("/controls/lighting/strobe",1).setBoolValue(0);
    props.globals.getNode("/controls/lighting/taxi-lights",1).setBoolValue(0);
    props.globals.getNode("/controls/cabin/fan",1).setBoolValue(0);
    props.globals.getNode("/controls/cabin/heat",1).setBoolValue(0);
    INSTR_DIMMER.setDoubleValue(0.6);
    ENG_DIMMER.setDoubleValue(0.6);
    EFIS_DIMMER.setDoubleValue(0.9);
    PANEL_DIMMER.setDoubleValue(0.6);
    FDM = 1;
    settimer(update_electrical,1);
    print("Electrical System ... ok");
});


update_virtual_bus = func( dt ) {
    if(FDM != 1 ){return;}
    var PWR = props.globals.getNode("systems/electrical/serviceable",1).getBoolValue();
    var engine0_state = props.globals.getNode("/engines/engine[0]/running").getBoolValue();
    var engine1_state = props.globals.getNode("/engines/engine[1]/running").getBoolValue();
    var alternator1_volts = 0.0;
    var alternator2_volts = 0.0;
    battery_volts = battery.get_output_volts();
    
    if (engine0_state){
    alternator1_volts = alternator1.get_output_volts();
    }
    props.globals.getNode("/engines/engine[0]/amp-v",1).setValue(alternator1_volts);

    if (engine1_state){
    alternator2_volts = alternator2.get_output_volts();
    }
    props.globals.getNode("/engines/engine[1]/amp-v",1).setValue(alternator2_volts);

    external_volts = 0.0;
    load = 0.0;

    bus_volts = 0.0;
    power_source = nil;
    if ( BATT.getBoolValue()) {
        if(PWR){bus_volts = battery_volts;}
        power_source = "battery";
        }
   if ( L_ALT.getBoolValue() and (alternator1_volts > bus_volts) ) {
        if(PWR){bus_volts = alternator1_volts;}
        power_source = "alternator1";
        }
    if ( R_ALT.getBoolValue() and (alternator2_volts > bus_volts) ) {
        if(PWR){bus_volts = alternator2_volts;}
        power_source = "alternator2";
        }
    if ( EXT.getBoolValue() and ( external_volts > bus_volts) ) {
        if(PWR){bus_volts = external_volts;}
        }
   
    load += electrical_bus(bus_volts);
    load += avionics_bus(bus_volts);

    ammeter = 0.0;
    if ( bus_volts > 1.0 ) {
        load += 15.0;

        if ( power_source == "battery" ) {
            ammeter = -load;
            } else {
            ammeter = battery.charge_amps;
            }
        }
    if ( power_source == "battery" ) {
        battery.apply_load( load, dt );
        } elsif ( bus_volts > battery_volts ) {
        battery.apply_load( -battery.charge_amps, dt );
        }

    ammeter_ave = 0.8 * ammeter_ave + 0.2 * ammeter;

   Amps.setValue(ammeter_ave);
   Volts.setValue(bus_volts);
   return load;
}

electrical_bus = func() {
    bus_volts = arg[0]; 
    load = 0.0;
    var starter_switch = props.globals.getNode("/controls/engines/engine[0]/starter").getBoolValue();
    var starter_switch1 = props.globals.getNode("/controls/engines/engine[1]/starter").getBoolValue(); 
    starter_volts = 0.0;
    if ( starter_switch or starter_switch1) {
        starter_volts = bus_volts;
        }
    OutPuts.getNode("starter",1).setValue(starter_volts); 

    OutPuts.getNode("instr-ignition-switch",1).setValue(bus_volts); 

    var f_pump0 = props.globals.getNode("/controls/engines/engine[0]/fuel-pump").getBoolValue();
    var f_pump1 = props.globals.getNode("/controls/engines/engine[0]/fuel-pump").getBoolValue();
    if ( f_pump0 or f_pump1 ) {
        OutPuts.getNode("fuel-pump",1).setValue(bus_volts); 
        } else {
        OutPuts.getNode("fuel-pump",1).setValue(0.0);
        }

    if ( props.globals.getNode("/controls/anti-ice/pitot-heat").getBoolValue()){
    OutPuts.getNode("pitot-heat",1).setValue(bus_volts);  
        } else {
    OutPuts.getNode("pitot-heat",1).setValue(0.0); 
        }

    if ( props.globals.getNode("/controls/lighting/landing-lights[0]").getBoolValue()){
    OutPuts.getNode("landing-lights[0]",1).setValue(bus_volts * NORM);  
        } else {
    OutPuts.getNode("landing-lights[0]",1).setValue(0.0); 
    }

    if ( props.globals.getNode("/controls/lighting/landing-lights[1]").getBoolValue()){
    OutPuts.getNode("landing-lights[1]",1).setValue(bus_volts * NORM);  
        } else {
    OutPuts.getNode("landing-lights[1]",1).setValue(0.0); 
    }

    if ( props.globals.getNode("/controls/lighting/cabin-lights").getBoolValue()){
    OutPuts.getNode("cabin-lights",1).setValue(bus_volts);  
        } else {
    OutPuts.getNode("cabin-lights",1).setValue(0.0); 
    }

    if ( props.globals.getNode("/controls/lighting/wing-lights").getBoolValue()){
    OutPuts.getNode("wing-lights",1).setValue(bus_volts * NORM);  
        } else {
    OutPuts.getNode("wing-lights",1).setValue(0.0); 
    }

    if ( props.globals.getNode("/controls/lighting/nav-lights").getBoolValue()){
    OutPuts.getNode("nav-lights",1).setValue(bus_volts * NORM);  
        } else {
    OutPuts.getNode("nav-lights",1).setValue(0.0); 
    }

    if ( props.globals.getNode("/controls/lighting/logo-lights").getBoolValue()){
    OutPuts.getNode("logo-lights",1).setValue(bus_volts * NORM);  
        } else {
    OutPuts.getNode("logo-lights",1).setValue(0.0); 
    }

    if ( props.globals.getNode("/controls/lighting/taxi-lights").getBoolValue()){
    OutPuts.getNode("taxi-lights",1).setValue(bus_volts * NORM);  
        } else {
    OutPuts.getNode("taxi-lights",1).setValue(0.0); 
    }

    var Bcn = props.globals.getNode("/controls/lighting/beacon-state/state").getValue();
    OutPuts.getNode("beacon",1).setValue((bus_volts * NORM) * Bcn);  

    var Strb = props.globals.getNode("/controls/lighting/strobe-state/state").getValue();
    OutPuts.getNode("strobe",1).setValue((bus_volts * NORM) * Strb);  

    OutPuts.getNode("flaps",1).setValue(bus_volts); 
    
    ebus1_volts = bus_volts;
    return load;
}

#### used in Instruments/source code 
# adf : dme : encoder : gps : DG : transponder  
# mk-viii : MRG : tacan : turn-coordinator
# nav[0] : nav [1] : comm[0] : comm[1]
####

avionics_bus = func() {
    var bus_volts = arg[0];
    var load = 0.0;
    var out = 0;
    var INSTR = props.globals.getNode("/instrumentation");

    if ( props.globals.getNode("/controls/electric/avionics-switch").getBoolValue()){
        load +=bus_volts* 0.05;
        out = bus_volts * NORM;
        OutPuts.getNode("efis-lights",1).setValue(out *EFIS_DIMMER.getValue());
    }else{
        OutPuts.getNode("efis-lights",1).setValue(0.0);
    }

    if ( props.globals.getNode("/controls/lighting/instrument-lights").getBoolValue()){
        load +=bus_volts* 0.05;
        out = bus_volts * NORM;
       OutPuts.getNode("instrument-lights",1).setValue(out *INSTR_DIMMER.getValue());
       OutPuts.getNode("eng-lights",1).setValue(out *ENG_DIMMER.getValue());
       OutPuts.getNode("panel-lights",1).setValue(out *PANEL_DIMMER.getValue());
    }else{
        OutPuts.getNode("instrument-lights",1).setValue(0.0);
        OutPuts.getNode("eng-lights",1).setValue(0.0);
        OutPuts.getNode("panel-lights",1).setValue(0.0);
    }

    if(INSTR.getNode("adf/serviceable").getBoolValue()){
        load +=bus_volts* 0.05;
        OutPuts.getNode("adf",1).setValue(bus_volts);
    }else{
        OutPuts.getNode("adf",1).setValue(0.0);
    }

    if(INSTR.getNode("dme/serviceable").getBoolValue()){
        load +=bus_volts* 0.05;
        OutPuts.getNode("dme",1).setValue(bus_volts);
    }else{
        OutPuts.getNode("dme",1).setValue(0.0);
    }

    if(INSTR.getNode("encoder/serviceable").getBoolValue()){
        load +=bus_volts* 0.05;
        OutPuts.getNode("encoder",1).setValue(bus_volts);
    }else{
        OutPuts.getNode("encoder",1).setValue(0.0);
    }

    if(INSTR.getNode("gps/serviceable").getBoolValue()){
        load +=bus_volts* 0.05;
        OutPuts.getNode("gps",1).setValue(bus_volts);
    }else{
        OutPuts.getNode("gps",1).setValue(0.0);
    }

    if(INSTR.getNode("heading-indicator/serviceable").getBoolValue()){
        load +=bus_volts* 0.05;
        OutPuts.getNode("DG",1).setValue(bus_volts);
    }else{
        OutPuts.getNode("DG",1).setValue(0.0);
    }

    if(INSTR.getNode("transponder/serviceable").getBoolValue()){
        load +=bus_volts* 0.05;
        OutPuts.getNode("transponder",1).setValue(bus_volts);
    }else{
        OutPuts.getNode("transponder",1).setValue(0.0);
    }

    if(INSTR.getNode("mk-viii/serviceable").getBoolValue()){
        load +=bus_volts* 0.05;
        OutPuts.getNode("mk-viii",1).setValue(bus_volts);
    }else{
        OutPuts.getNode("mk-viii",1).setValue(0.0);
    }

#    if(INSTR.getNode("master-reference-gyro/serviceable").getBoolValue()){
#        load +=bus_volts* 0.05;
#        OutPuts.getNode("MRG",1).setValue(bus_volts);
#    }else{
#        OutPuts.getNode("MRG",1).setValue(0.0);
#    }

    if(INSTR.getNode("tacan/serviceable").getBoolValue()){
        load +=bus_volts* 0.05;
        OutPuts.getNode("tacan",1).setValue(bus_volts);
    }else{
        OutPuts.getNode("tacan",1).setValue(0.0);
    }

    if(INSTR.getNode("turn-indicator/serviceable").getBoolValue()){
        load +=bus_volts* 0.05;
        OutPuts.getNode("turn-coordinator",1).setValue(bus_volts);
    }else{
        OutPuts.getNode("turn-coordinator",1).setValue(0.0);
    }

    if(INSTR.getNode("nav[0]/serviceable").getBoolValue()){
        load +=bus_volts* 0.05;
        OutPuts.getNode("nav[0]",1).setValue(bus_volts);
    }else{
        OutPuts.getNode("nav[0]",1).setValue(0.0);
    }

    if(INSTR.getNode("nav[1]/serviceable").getBoolValue()){
        load +=bus_volts* 0.05;
        OutPuts.getNode("nav[1]",1).setValue(bus_volts);
    }else{
        OutPuts.getNode("nav[1]",1).setValue(0.0);
    }

    if(INSTR.getNode("comm[0]/serviceable").getBoolValue()){
        load +=bus_volts* 0.05;
        OutPuts.getNode("comm[0]",1).setValue(bus_volts);
    }else{
        OutPuts.getNode("comm[0]",1).setValue(0.0);
    }

    if(INSTR.getNode("comm[1]/serviceable").getBoolValue()){
        load +=bus_volts* 0.05;
        OutPuts.getNode("comm[1]",1).setValue(bus_volts);
    }else{
        OutPuts.getNode("comm[1]",1).setValue(0.0);
    }

    return load;
}

update_electrical = func {
    if(FDM == 1){
    time = getprop("/sim/time/elapsed-sec");
    dt = time - last_time;
    last_time = time;
    update_virtual_bus( dt );
    }
settimer(update_electrical, 0);
}
