####	B1900d systems	
#### Syd Adams
#### Barber pole code - K. Hoercher

aircraft.livery.init("Aircraft/b1900d/Models/Liveries");
var cabin_door = aircraft.door.new("/controls/cabin-door", 4);

var Wiper = {
    new : func(prop,power,settings){
        m = { parents : [Wiper] };
        m.direction = 1;
        m.delay_count = 0;
        m.spd_factor = 0;
        m.speed_prop=[];
        m.delay_prop=[];
        m.node = props.globals.getNode(prop,1);
        m.power = props.globals.getNode(power,1);
        if(m.power.getValue()==nil)m.power.setDoubleValue(0);
        m.position = m.node.getNode("position-norm", 1);
        m.position.setDoubleValue(0);
        m.switch = m.node.getNode("switch", 1);
        m.switch.setIntValue(0);
        for(var i=0; i<settings; i+=1) {
            append(m.speed_prop,m.node.getNode("arc-sec["~i~"]",1));
            if(m.speed_prop[i].getValue()==nil)m.speed_prop[i].setDoubleValue(i);
            append(m.delay_prop,m.node.getNode("delay-sec["~i~"]",1));
            if(m.delay_prop[i].getValue()==nil)m.delay_prop[i].setDoubleValue(i * 0.5);
        }
        return m;
    },
    active: func{
    if(me.power.getValue()<=5)return;
    var sw=me.switch.getValue();
    var sec =getprop("/sim/time/delta-sec");
    var spd_factor = 1/me.speed_prop[sw].getValue();
    var pos = me.position.getValue();
    if(sw==0){
        spd_factor = 1/me.speed_prop[1].getValue();
        if(pos <=0){
        me.position.setValue(0);
        return;
        }
    } 

    if(pos >=1.000){
        me.direction=-1;
        }elsif(pos <=0){
            me.direction=1;
            var dly=me.delay_prop[sw].getValue();
            if(dly>0){
                me.direction=0;
                me.delay_count+=sec;
                if(me.delay_count >= dly){
                    me.delay_count=0;
                    me.direction=1;
                }
            }
        }
    var wiper_time = spd_factor*sec;
    pos =pos+(wiper_time * me.direction);
    me.position.setValue(pos);
    }
};

###### warning panel ########

var millibars = 0.0;
var power = nil;
var eadi = nil;
var engines = nil;
var instruments = nil;
var panel = nil;
var volts = 0.0;
var eyepoint = 0.0;
var force = 0.0;
var ViewNum = 0.0;
var stall = 0.0;
S_volume = props.globals.getNode("/sim/sound/E_volume",1);
C_volume = props.globals.getNode("/sim/sound/cabin",1);
var MB = props.globals.getNode("/instrumentation/altimeter/millibars",1);
var wiper = Wiper.new("controls/electric/wipers","systems/electrical/volts",3);
var FHmeter = aircraft.timer.new("/instrumentation/clock/flight-meter-sec", 10);
FHmeter.stop();

#http://www.pprune.org/forums/archive/index.php/t-166572.html
#http://www.airweb.faa.gov/Regulatory_and_Guidance_Library/rgMakeModel.nsf/0/4bd70d173cbc5f4586256fb80048f054/$FILE/A24CE.pdf
var LIMIT_VIAS=248.0;
var LIMIT_MACH=0.48;
var LIMIT_CHANGE=13200.0;
var CURR_HP_NODEP="instrumentation/altimeter/pressure-alt-ft";
var CURR_KIAS_NODEP="instrumentation/airspeed-indicator/indicated-speed-kt";
var CURR_MACH_NODEP="velocities/mach";
var CURR_LIMIT_NODEP="instrumentation/airspeed-indicator/limit-indicated-speed-kt";
props.globals.getNode(CURR_LIMIT_NODEP,1).setValue(LIMIT_VIAS);

var set_barber_pole = func {
  if (getprop(CURR_HP_NODEP)>LIMIT_CHANGE) {
    setprop(CURR_LIMIT_NODEP,getprop(CURR_KIAS_NODEP)/getprop(CURR_MACH_NODEP)*LIMIT_MACH);
  } else {
    if (!(getprop(CURR_LIMIT_NODEP)==LIMIT_VIAS))
      setprop(CURR_LIMIT_NODEP,LIMIT_VIAS);
  }
  settimer(set_barber_pole,0);
}

setlistener("/sim/signals/fdm-initialized", func {
    S_volume.setValue(0.3);
    C_volume.setValue(0.3);
    MB.setDoubleValue(0.0);
    setprop("/instrumentation/heading-indicator/offset-deg",-1 * getprop("/environment/magnetic-variation-deg"));
    setprop("/instrumentation/clock/flight-meter-hour",0);
    set_barber_pole();
    print("system  ...Check");
    setprop("controls/engines/engine/condition",0);
    setprop("controls/engines/engine[1]/condition",0);
    settimer(update_systems, 2);
    });

setlistener("/engines/engine/out-of-fuel", func(nf){
    if(nf.getValue() != 0){
        fueltanks = props.globals.getNode("consumables/fuel").getChildren("tank");
        foreach(f; fueltanks) {
            if(f.getNode("selected", 1).getBoolValue()){
                if(f.getNode("level-lbs").getValue() > 0.01){
                    setprop("/engines/engine/out-of-fuel",0);
                }
            }
        }
    }
},0,0);

setlistener("/sim/current-view/view-number", func(vw){
    ViewNum = vw.getValue();
    if(ViewNum == 0){
        S_volume.setValue(0.3);
        C_volume.setValue(0.3);
        }else{
            S_volume.setValue(0.9);
            C_volume.setValue(0.05);
        }
},0,0);

setlistener("/sim/model/start-idling", func(idle){
    var run= idle.getBoolValue();
    if(run){
    Startup();
    }else{
    Shutdown();
    }
},0,0);

setlistener("/gear/gear[1]/wow", func(gr){
    if(gr.getBoolValue()){
    FHmeter.stop();
    }else{FHmeter.start();}
},0,0);

setlistener("/instrumentation/adf/func-knob", func(btn){
    var tst = btn.getValue();
    if(tst ==0){
    setprop("instrumentation/adf/serviceable",0);
    setprop("instrumentation/adf/mode","off");
    }elsif(tst==1){
    setprop("instrumentation/adf/ident-audible",0);
    setprop("instrumentation/adf/mode","bfo");
    setprop("instrumentation/adf/serviceable",1);
    }elsif(tst==2){
    setprop("instrumentation/adf/ident-audible",0);
    setprop("instrumentation/adf/mode","adf");
    }elsif(tst==3){
    setprop("instrumentation/adf/ident-audible",1);
    }
},1,0);

setlistener("/instrumentation/comm/func-knob", func(btn){
    var tst = btn.getValue();
    if(tst ==0){
    setprop("instrumentation/comm/serviceable",0);
    }elsif(tst==1){
    setprop("instrumentation/comm/serviceable",1);
    }
},1,0);

setlistener("/instrumentation/comm[1]/func-knob", func(btn){
    var tst = btn.getValue();
    if(tst ==0){
    setprop("instrumentation/comm[1]/serviceable",0);
    }elsif(tst==1){
    setprop("instrumentation/comm[1]/serviceable",1);
    }
},1,0);

setlistener("/instrumentation/nav/func-knob", func(btn){
    var tst = btn.getValue();
    if(tst ==0){
    setprop("instrumentation/nav/serviceable",0);
    }elsif(tst==1){
    setprop("instrumentation/nav/serviceable",1);
    }
},1,0);

setlistener("/instrumentation/nav[1]/func-knob", func(btn){
    var tst = btn.getValue();
    if(tst ==0){
    setprop("instrumentation/nav[1]/serviceable",0);
    }elsif(tst==1){
    setprop("instrumentation/nav[1]/serviceable",1);
    }
},1,0);

var Startup = func{
setprop("controls/electric/engine[0]/generator",1);
setprop("controls/electric/engine[1]/generator",1);
setprop("controls/electric/avionics-switch",1);
setprop("controls/electric/battery-switch",1);
setprop("controls/electric/inverter-switch",1);
setprop("controls/lighting/instrument-lights",1);
setprop("controls/lighting/nav-lights",1);
setprop("controls/lighting/beacon",1);
setprop("controls/lighting/strobe",1);
setprop("controls/engines/engine[0]/condition",1);
setprop("controls/engines/engine[1]/condition",1);
setprop("controls/engines/engine[0]/mixture",1);
setprop("controls/engines/engine[1]/mixture",1);
setprop("controls/engines/engine[0]/propeller-pitch",1);
setprop("controls/engines/engine[1]/propeller-pitch",1);
setprop("engines/engine[0]/running",1);
setprop("engines/engine[1]/running",1);
setprop("controls/electric/RH-AC-bus",1);
setprop("controls/electric/LH-AC-bus",1);
}

var Shutdown = func{
setprop("controls/electric/engine[0]/generator",0);
setprop("controls/electric/engine[1]/generator",0);
setprop("controls/electric/avionics-switch",0);
setprop("controls/electric/battery-switch",0);
setprop("controls/electric/inverter-switch",0);
setprop("controls/lighting/instrument-lights",0);
setprop("controls/lighting/nav-lights",0);
setprop("controls/lighting/beacon",0);
setprop("controls/lighting/strobe",0);
setprop("controls/engines/engine[0]/condition",0);
setprop("controls/engines/engine[1]/condition",0);
setprop("controls/engines/engine[0]/mixture",0);
setprop("controls/engines/engine[1]/mixture",0);
setprop("controls/engines/engine[0]/propeller-pitch",0);
setprop("controls/engines/engine[1]/propeller-pitch",0);
setprop("engines/engine[0]/running",0);
setprop("engines/engine[1]/running",0);
setprop("controls/electric/RH-AC-bus",0);
setprop("controls/electric/LH-AC-bus",0);
}

var flight_meter = func{
var fmeter = getprop("/instrumentation/clock/flight-meter-sec");
var fminute = fmeter * 0.016666;
var fhour = fminute * 0.016666;
setprop("/instrumentation/clock/flight-meter-hour",fhour);
}

var gear_toggle = func(dir){
    var grdir =dir;
    if(grdir==-1){
        grdir=0;
        if(getprop("controls/gear/gear-down")){
            if(getprop("gear/gear[1]/wow"))grdir=1;
            if(getprop("controls/gear/gear-lock"))grdir=1;
        }
    }
    setprop("controls/gear/gear-down", grdir);
}

var update_systems = func {
        var mb = 33.8637526 * getprop("/instrumentation/altimeter/setting-inhg");
        power = getprop("/controls/switches/master-panel");
        volts = getprop("/systems/electrical/volts");
        if(volts == nil){volts = 0.0;}
        MB.setDoubleValue(mb);
        setprop("/sim/model/b1900d/material/panel/factor", 0.0);
        setprop("/sim/model/b1900d/material/radiance/factor", 0.0);
    flight_meter();
    if(getprop("controls/gear/gear-lock")){
        if(getprop("controls/gear/gear-down") !=1)setprop("controls/gear/gear-down",1);
    }
    if(getprop("controls/cabin-door/position-norm")>0.0){
        if(!getprop("controls/gear/brake-parking"))cabin_door.close();
        if(getprop("engines/engine/running"))cabin_door.close();
        if(!getprop("gear/gear[1]/wow"))cabin_door.close();
    }
    var testwarn =getprop("sim/alarms/stall-warning");
    if(getprop("orientation/alpha-deg")>10.0){
        setprop("sim/alarms/stall-warning",1);
    }else{
        setprop("sim/alarms/stall-warning",testwarn);
    }
    wiper.active();
    settimer(update_systems, 0);
}
