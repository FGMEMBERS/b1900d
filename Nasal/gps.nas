####	gps routines ####
var gpsmode = nil;
var gpsnode = nil;
var navnode = props.globals.getNode("instrumentation/nav/slaved-to-gps",1);
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

setlistener("sim/signals/fdm-initialized", func {
    lhmenu = 3;
    rhmenu = 5;
    lhsubmenu[lhmenu] = 1;
    rhsubmenu[rhmenu] = 3;
    navnode.setBoolValue(1);
    setprop("instrumentation/gps/wp/wp/ID",getprop("sim/tower/airport-id"));
    setprop("instrumentation/gps/wp/wp/waypoint-type","airport");
    print("KLN-90B GPS  ...Check");
    });

var flight_meter = func{
var fmeter = getprop("instrumentation/clock/flight-meter-sec");
var fminute = fmeter * 0.016666;
var fhour = fminute * 0.016666;
setprop("instrumentation/clock/flight-meter-hour",fhour);
}

setlistener("instrumentation/gps/serviceable", func(gps1){
    var power = gps1.getBoolValue();
    if (power){
        setprop("instrumentation/gps-annunciator/mode-string[0]",LEFTMODES[lhmenu] ~ PAGENUM[lhsubmenu[lhmenu]]);
        setprop("instrumentation/gps-annunciator/mode-string[1]",RIGHTMODES[rhmenu] ~ PAGENUM[rhsubmenu[rhmenu]]);
        }else{
        setprop("instrumentation/gps-annunciator/mode-string[0]","POWER OFF");
        setprop("instrumentation/gps-annunciator/mode-string[1]","POWER OFF");
    }
},0,0);

var GpsAppr = func {
    gpsnode = props.globals.getNode("instrumentation/gps/leg-mode");
    apprnode = props.globals.getNode("instrumentation/gps/approach-active");
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

var GpsCrs = func {
    gpsnode = props.globals.getNode("instrumentation/gps/leg-mode");
    apprnode = props.globals.getNode("instrumentation/gps/approach-active");
    if(gpsnode.getBoolValue()){
        gpsnode.setBoolValue(0);
        navnode.setBoolValue(0);
        }else{
        gpsnode.setBoolValue(1);
        navnode.setBoolValue(1);
        apprnode.setBoolValue(0);
        }
}

var lh_menu_update = func (){
    setprop("instrumentation/gps-annunciator/mode-string[0]","POWER OFF");
    if(gpsnode != 0.0){
        volts = getprop("systems/electrical/outputs/gps");
        if(volts > 0.2){
            modestring1 = getprop("instrumentation/gps-annunciator/mode-string[0]");
            test = arg[0];
            if(test == 1){lh_menu_modify(1);}
            if(test == 2){lh_menu_modify(2);}
            if(test == 3){lh_submenu_modify(1);}
            if(test == 4){lh_submenu_modify(2);}
        }
    }
}

var  lh_menu_modify = func (){
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
    setprop("instrumentation/gps-annunciator/mode-string[0]",LEFTMODES[lhmenu] ~ PAGENUM[lhsubmenu[lhmenu]]);
}

var lh_submenu_modify = func (){
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
    setprop("instrumentation/gps-annunciator/mode-string[0]",LEFTMODES[lhmenu] ~ PAGENUM[lhsubmenu[lhmenu]]);
}

var rh_menu_update = func (){
    setprop("instrumentation/gps-annunciator/mode-string[1]","POWER OFF");
    if(gpsnode != 0.0){
        volts = getprop("systems/electrical/outputs/gps");
        if(volts > 0.2){
            test = arg[0];
            if(test == 1){rh_menu_modify(1);}
            if(test == 2){rh_menu_modify(2);}
            if(test == 3){rh_submenu_modify(1);}
            if(test == 4){rh_submenu_modify(2);}
        }
    }
}

var rh_menu_modify = func (){
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
    setprop("instrumentation/gps-annunciator/mode-string[1]",RIGHTMODES[rhmenu] ~ PAGENUM[rhsubmenu[rhmenu]]);
}

var rh_submenu_modify = func (){
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
    setprop("instrumentation/gps-annunciator/mode-string[1]",RIGHTMODES[rhmenu] ~ PAGENUM[rhsubmenu[rhmenu]]);
}

var direct_to = func {
    setprop("instrumentation/gps/wp/wp[0]/waypoint-type","");
    setprop("instrumentation/gps/wp/wp[0]/ID","");
    setprop("instrumentation/gps/wp/wp[0]/name","");
    setprop("instrumentation/gps/wp/wp[0]/latitude-deg",getprop("position/latitude-deg"));
    setprop("instrumentation/gps/wp/wp[0]/longitude-deg",getprop("position/longitude-deg"));
}
