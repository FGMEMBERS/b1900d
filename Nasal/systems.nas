####	B1900d systems	####
aircraft.livery.init("Aircraft/b1900d/Models/Liveries", "sim/model/livery/name", "sim/model/livery/index");
var millibars = 0.0;
var pph1 = 0.0;
var pph2 = 0.0;
var power = nil;
var eadi = nil;
var engines = nil;
var instruments = nil;
var panel = nil;
var volts = 0.0;
var eyepoint = 0.0;
var force = 0.0;
var fuel_density=0.0;
var ViewNum = 0.0;
var stall = 0.0;
S_volume = props.globals.getNode("/sim/sound/E_volume",1);
C_volume = props.globals.getNode("/sim/sound/cabin",1);
var MB = props.globals.getNode("/instrumentation/altimeter/millibars",1);


var FHmeter = aircraft.timer.new("/instrumentation/clock/flight-meter-sec", 10);
FHmeter.stop();

setlistener("/sim/signals/fdm-initialized", func {
    S_volume.setValue(0.3);
    C_volume.setValue(0.3);
    MB.setDoubleValue(0.0);
    fuel_density=props.globals.getNode("consumables/fuel/tank[0]/density-ppg").getValue();
    setprop("/instrumentation/heading-indicator/offset-deg",-1 * getprop("/environment/magnetic-variation-deg"));
    setprop("/instrumentation/clock/flight-meter-hour",0);
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
}

var update_systems = func {
        var mb = 33.8637526 * props.globals.getNode("/instrumentation/altimeter/setting-inhg").getValue();
        power = getprop("/controls/switches/master-panel");
        volts = getprop("/systems/electrical/volts");
        if(volts == nil){volts = 0.0;}
        pph1 = getprop("/engines/engine[0]/fuel-flow-gph");
        pph2 = getprop("/engines/engine[1]/fuel-flow-gph");
        if(pph1 == nil){pph1 = 6.72;}
        if(pph2 == nil){pph2 = 6.72;}
        setprop("engines/engine[0]/fuel-flow-pph",pph1* fuel_density);
        setprop("engines/engine[1]/fuel-flow-pph",pph2* fuel_density);
        MB.setDoubleValue(mb);
        setprop("/sim/model/b1900d/material/panel/factor", 0.0);
        setprop("/sim/model/b1900d/material/radiance/factor", 0.0);
    flight_meter();
    settimer(update_systems, 0);
}

var flight_meter = func{
var fmeter = getprop("/instrumentation/clock/flight-meter-sec");
var fminute = fmeter * 0.016666;
var fhour = fminute * 0.016666;
setprop("/instrumentation/clock/flight-meter-hour",fhour);
}
