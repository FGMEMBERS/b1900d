####	B1900d systems	####

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
var gpsmode = nil;
var gpsnode = nil;
var navnode = props.globals.getNode("/instrumentation/nav/slaved-to-gps",1);
var apprnode= nil;
var LEFTMODES =["TRI ","MOD ","FPL ","NAV ","CAL ","STA ","SET ","OTH "];
var RIGHTMODES =["CTR ","REF ","ACT ","D/T ","NAV ","APT ","VOR ","NDB ","INT ","SUP "];
var PAGENUM = ["1","2","3","4","5","6","7","8","9","10"];
var stall = 0.0;
var rhmenu = nil;
var lhmenu = nil;
var lhsubmenu =[0,0,0,0,0,0,0,0];
var rhsubmenu =[0,0,0,0,0,0,0,0,0,0];
var dmode = nil;
var getpage = nil;
var modestring1 = nil;
S_volume = props.globals.getNode("/sim/sound/E_volume",1);
C_volume = props.globals.getNode("/sim/sound/cabin",1);
var FDM_ON = 0;
var MB = props.globals.getNode("/instrumentation/altimeter/millibars",1);

var FHmeter = aircraft.timer.new("/instrumentation/clock/flight-meter-sec", 10);
FHmeter.stop();

setlistener("/sim/signals/fdm-initialized", func {
    S_volume.setValue(0.3);
    C_volume.setValue(0.3);
    lhmenu = 3;
    rhmenu = 5;
    lhsubmenu[lhmenu] = 1;
    rhsubmenu[rhmenu] = 3;
    navnode.setBoolValue(1);
    MB.setDoubleValue(0.0);
    fuel_density=props.globals.getNode("consumables/fuel/tank[0]/density-ppg").getValue();
    setprop("/instrumentation/gps/wp/wp/ID",getprop("/sim/tower/airport-id"));
    setprop("/instrumentation/gps/wp/wp/waypoint-type","airport");
    setprop("/instrumentation/heading-indicator/offset-deg",-1 * getprop("/environment/magnetic-variation-deg"));
    setprop("/instrumentation/clock/flight-meter-hour",0);
    FDM_ON =1;
    print("KLN-90B GPS  ...Check");
    settimer(update_systems, 1);
    });

setlistener("/engines/engine/out-of-fuel", func {
    if(cmdarg().getValue() != 0){
        fueltanks = props.globals.getNode("consumables/fuel").getChildren("tank");
        foreach(f; fueltanks) {
            if(f.getNode("selected", 1).getBoolValue()){
                if(f.getNode("level-lbs").getValue() > 0.01){
                    setprop("/engines/engine/out-of-fuel",0);
                }
            }
        }
    }
});

setlistener("/sim/current-view/view-number", func {
    if(FDM_ON !=0){
        ViewNum = cmdarg().getValue();
        if(ViewNum == 0){
            S_volume.setValue(0.3);
            C_volume.setValue(0.3);
            }else{
                S_volume.setValue(0.9);
                C_volume.setValue(0.05);
                }
            }
    });

setlistener("/gear/gear[1]/wow", func {
    if(cmdarg().getBoolValue()){
    FHmeter.stop();
    }else{FHmeter.start();}
});

update_systems = func {
    if(FDM_ON != 0){
        var mb = 33.8637526 * props.globals.getNode("/instrumentation/altimeter/setting-inhg").getValue();
        power = getprop("/controls/switches/master-panel");
        volts = getprop("/systems/electrical/volts");
        if(volts == nil){volts = 0.0;}
        pph1 = props.globals.getNode("/engines/engine[0]/fuel-flow-gph").getValue();
        pph2 = props.globals.getNode("/engines/engine[1]/fuel-flow-gph").getValue();
        if(pph1 == nil){pph1 = 6.72;}
        if(pph2 == nil){pph2 = 6.72;}
        props.globals.getNode("engines/engine[0]/fuel-flow-pph").setDoubleValue(pph1* fuel_density);
        props.globals.getNode("engines/engine[1]/fuel-flow-pph").setDoubleValue(pph2* fuel_density);
        MB.setDoubleValue(mb);
        setprop("/sim/model/b1900d/material/panel/factor", 0.0);
        setprop("/sim/model/b1900d/material/radiance/factor", 0.0);
    }
    flight_meter();
    settimer(update_systems, 0);
}

flight_meter = func{
var fmeter = getprop("/instrumentation/clock/flight-meter-sec");
var fminute = fmeter * 0.016666;
var fhour = fminute * 0.016666;
setprop("/instrumentation/clock/flight-meter-hour",fhour);
}

setlistener("/instrumentation/gps/serviceable", func {
var power = cmdarg().getBoolValue();
    if (power){
        setprop("/instrumentation/gps-annunciator/mode-string[0]",LEFTMODES[lhmenu] ~ PAGENUM[lhsubmenu[lhmenu]]);
        setprop("/instrumentation/gps-annunciator/mode-string[1]",RIGHTMODES[rhmenu] ~ PAGENUM[rhsubmenu[rhmenu]]);
        }else{
        setprop("/instrumentation/gps-annunciator/mode-string[0]","POWER OFF");
        setprop("/instrumentation/gps-annunciator/mode-string[1]","POWER OFF");
    }
});

GpsAppr = func {
    gpsnode = props.globals.getNode("/instrumentation/gps/leg-mode");
    apprnode = props.globals.getNode("/instrumentation/gps/approach-active");
    navnode.getBoolValue();
    if(apprnode.getBoolValue()){
        apprnode.setBoolValue(0);
        navnode.setBoolValue(0);
        }else{
        apprnode.setBoolValue(1);
        navnode.setBoolValue(1);
        gpsnode.setBoolValue(0);
    }
}

GpsCrs = func {gpsnode = props.globals.getNode("/instrumentation/gps/leg-mode");
    apprnode = props.globals.getNode("/instrumentation/gps/approach-active");
    if(gpsnode.getBoolValue()){
        gpsnode.setBoolValue(0);
        navnode.setBoolValue(0);
        }else{
        gpsnode.setBoolValue(1);
        navnode.setBoolValue(1);
        apprnode.setBoolValue(0);
        }
}

lh_menu_update = func (){
    setprop("/instrumentation/gps-annunciator/mode-string[0]","POWER OFF");
    if(gpsnode != 0.0){
        volts = getprop("/systems/electrical/outputs/gps");
        if(volts > 0.2){
            modestring1 = getprop("/instrumentation/gps-annunciator/mode-string[0]");
            test = arg[0];
            if(test == 1){lh_menu_modify(1);}
            if(test == 2){lh_menu_modify(2);}
            if(test == 3){lh_submenu_modify(1);}
            if(test == 4){lh_submenu_modify(2);}
            }
        }
    }

    lh_menu_modify = func (){
    test=arg[0];
    if(test == 1){
        lhmenu = lhmenu - 1;
        if(lhmenu < 0 ){lhmenu =lhmenu + 8;}
        }else{
        if(test == 2){
        lhmenu = lhmenu + 1;
        if(lhmenu > 7 ){lhmenu =lhmenu - 8;}
        }
    }
    setprop("/instrumentation/gps-annunciator/mode-string[0]",LEFTMODES[lhmenu] ~ PAGENUM[lhsubmenu[lhmenu]]);
}

lh_submenu_modify = func (){
    test=arg[0];
    if(test == 1){
        lhsubmenu[lhmenu] = lhsubmenu[lhmenu] - 1;
        if(lhsubmenu[lhmenu] < 0 ){lhsubmenu[lhmenu] =lhsubmenu[lhmenu] + 5;}
        }else{
        if(test == 2){
        lhsubmenu[lhmenu] = lhsubmenu[lhmenu] + 1;
        if(lhsubmenu[lhmenu] > 4 ){lhsubmenu[lhmenu] =lhsubmenu[lhmenu] - 5;}
        }
    }
    setprop("/instrumentation/gps-annunciator/mode-string[0]",LEFTMODES[lhmenu] ~ PAGENUM[lhsubmenu[lhmenu]]);
}

rh_menu_update = func (){
    setprop("/instrumentation/gps-annunciator/mode-string[1]","POWER OFF");
    if(gpsnode != 0.0){
        volts = getprop("/systems/electrical/outputs/gps");
        if(volts > 0.2){
            test = arg[0];
            if(test == 1){rh_menu_modify(1);}
            if(test == 2){rh_menu_modify(2);}
            if(test == 3){rh_submenu_modify(1);}
            if(test == 4){rh_submenu_modify(2);}
            }
        }
    }

rh_menu_modify = func (){
    test=arg[0];
    if(test == 1){
        rhmenu = rhmenu - 1;
        if(rhmenu < 0 ){rhmenu =rhmenu + 10;}
        }else{
        if(test == 2){
            rhmenu = rhmenu + 1;
            if(rhmenu > 7 ){rhmenu =rhmenu - 10;}
            }
        }
    setprop("/instrumentation/gps-annunciator/mode-string[1]",RIGHTMODES[rhmenu] ~ PAGENUM[rhsubmenu[rhmenu]]);
}

rh_submenu_modify = func (){
    test=arg[0];
    if(test == 1){
        rhsubmenu[rhmenu] = rhsubmenu[rhmenu] - 1;
        if(rhsubmenu[rhmenu] < 0 ){rhsubmenu[rhmenu] =rhsubmenu[rhmenu] + 5;}
        }else{
        if(test == 2){
            rhsubmenu[rhmenu] = rhsubmenu[rhmenu] + 1;
            if(rhsubmenu[rhmenu] > 4 ){rhsubmenu[rhmenu] =rhsubmenu[rhmenu] - 5;}
            }
        }
    setprop("/instrumentation/gps-annunciator/mode-string[1]",RIGHTMODES[rhmenu] ~ PAGENUM[rhsubmenu[rhmenu]]);
}

direct_to = func {
    setprop("/instrumentation/gps/wp/wp/waypoint-type","fix");
    setprop("/instrumentation/gps/wp/wp/ID","");
    setprop("/instrumentation/gps/wp/wp/name","");
    setprop("/instrumentation/gps/wp/wp/latitude-deg",getprop("/position/latitude-deg"));
    setprop("/instrumentation/gps/wp/wp/longitude-deg",getprop("/position/longitude-deg"));
    }
