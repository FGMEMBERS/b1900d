
# B1900d systems

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
var viewnum = 0.0;
gpsmode = nil;
gpsnode = nil;
navnode = nil;
apprnode= nil;
LEFTMODES =["TRI ","MOD ","FPL ","NAV ","CAL ","STA ","SET ","OTH "];
RIGHTMODES =["CTR ","REF ","ACT ","D/T ","NAV ","APT ","VOR ","NDB ","INT ","SUP "];
PAGENUM = ["1","2","3","4","5","6","7","8","9","10"];
var stall = 0.0;
rhmenu = nil;
lhmenu = nil;
lhsubmenu =[0,0,0,0,0,0,0,0];
rhsubmenu =[0,0,0,0,0,0,0,0,0,0];

dmode = nil;
getpage = nil;
modestring1 = nil;


# Lighting system

strobe_switch = props.globals.getNode("controls/switches/strobe", 1);
aircraft.light.new("sim/model/b1900d/lighting/strobe", [0.05, 1.30], strobe_switch);
beacon_switch = props.globals.getNode("controls/switches/beacon", 1);
aircraft.light.new("sim/model/b1900d/lighting/beacon", [1.0, 1.0], beacon_switch);

setlistener("/sim/signals/fdm-initialized", func {
   lhmenu = 3;
   rhmenu = 5;
   lhsubmenu[lhmenu] = 1;
   rhsubmenu[rhmenu] = 3;
   setprop("/instrumentation/altimeter/millibars",0.0);
   fuel_density=getprop("consumables/fuel/tank[0]/density-ppg");
   setprop("/instrumentation/gps/wp/wp/ID",getprop("/sim/tower/airport-id"));
   setprop("/instrumentation/gps/wp/wp/waypoint-type","airport");
   setprop("/instrumentation/heading-indicator/offset-deg",-1 * getprop("/environment/magnetic-variation-deg"));
   print("KLN-90B GPS  ...Check");
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
}
);


update_systems = func {
if(getprop("/sim/signals/fdm-initialized")){
power = getprop("/controls/switches/master-panel");
eadi = getprop("/controls/lighting/eadi-ehsi-norm");
engines = getprop("/controls/lighting/engines-norm");
instruments = getprop("/controls/lighting/instruments-norm");
volts = getprop("/systems/electrical/volts");
if(volts == nil){volts = 0.0;}
panel = getprop("/controls/lighting/panel-norm");
viewnum = getprop("/sim/current-view/view-number");
pph1 = getprop("/engines/engine[0]/fuel-flow-gph");
pph2 = getprop("/engines/engine[1]/fuel-flow-gph");
if(pph1 == nil){pph1 = 6.84;}
if(pph2 == nil){pph2 = 6.84;}
setprop("engines/engine[0]/fuel-flow-pph",pph1* fuel_density);
setprop("engines/engine[1]/fuel-flow-pph",pph2* fuel_density);
setprop("/instrumentation/altimeter/millibars",getprop("/instrumentation/altimeter/setting-inhg") * 33.8637526);
setprop("/sim/model/b1900d/material/panel/factor", 0.0);
setprop("/sim/model/b1900d/material/radiance/factor", 0.0);

if (volts > 0.2 ){
	if(power > 0){
	setprop("/sim/model/b1900d/material/panel/factor", panel);
	setprop("/sim/model/b1900d/material/radiance/factor", panel);
	}
}

   force = getprop("/accelerations/pilot-g");
   if(force == nil) {force = 1.0;}
   eyepoint = getprop("sim/view/config/y-offset-m") +0.01;
   eyepoint -= (force * 0.01);
   if(getprop("/sim/current-view/view-number") < 1){
      setprop("/sim/current-view/y-offset-m",eyepoint);
      }
   }
}

####################################
gpspower = func {
           gpsnode = props.globals.getNode("/instrumentation/gps/serviceable");
           node = 1 - getprop("/instrumentation/gps/serviceable");
           gpsnode.setBoolValue(node);
           if (node != 0.0){
setprop("/instrumentation/gps-annunciator/mode-string[0]",LEFTMODES[lhmenu] ~ PAGENUM[lhsubmenu[lhmenu]]);
setprop("/instrumentation/gps-annunciator/mode-string[1]",RIGHTMODES[rhmenu] ~ PAGENUM[rhsubmenu[rhmenu]]);
}else{
setprop("/instrumentation/gps-annunciator/mode-string[0]","POWER OFF");
setprop("/instrumentation/gps-annunciator/mode-string[1]","POWER OFF");
}}
####################################
GpsAppr = func {
gpsnode = props.globals.getNode("/instrumentation/gps/leg-mode");
      apprnode = props.globals.getNode("/instrumentation/gps/approach-active");
      navnode = props.globals.getNode("/instrumentation/nav/slaved-to-gps");
      if(apprnode.getBoolValue()){
      apprnode.setBoolValue(0);
      navnode.setBoolValue(0);
      } else {
      apprnode.setBoolValue(1);
      navnode.setBoolValue(1);
      gpsnode.setBoolValue(0);
      }
}
####################################
GpsCrs = func {gpsnode = props.globals.getNode("/instrumentation/gps/leg-mode");
      apprnode = props.globals.getNode("/instrumentation/gps/approach-active");
      navnode = props.globals.getNode("/instrumentation/nav/slaved-to-gps");
      if(gpsnode.getBoolValue()){
      gpsnode.setBoolValue(0);
      navnode.setBoolValue(0);
      } else {
      gpsnode.setBoolValue(1);
      navnode.setBoolValue(1);
      apprnode.setBoolValue(0);
      }
}
####################################

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
}}}

lh_menu_modify = func (){
test=arg[0];
if(test == 1){
lhmenu = lhmenu - 1;
if(lhmenu < 0 ){lhmenu =lhmenu + 8;}
}
else{
if(test == 2){
lhmenu = lhmenu + 1;
if(lhmenu > 7 ){lhmenu =lhmenu - 8;}
}}
setprop("/instrumentation/gps-annunciator/mode-string[0]",LEFTMODES[lhmenu] ~ PAGENUM[lhsubmenu[lhmenu]]);
}
####################################
lh_submenu_modify = func (){
test=arg[0];
if(test == 1){
lhsubmenu[lhmenu] = lhsubmenu[lhmenu] - 1;
if(lhsubmenu[lhmenu] < 0 ){lhsubmenu[lhmenu] =lhsubmenu[lhmenu] + 5;}
}
else{
if(test == 2){
lhsubmenu[lhmenu] = lhsubmenu[lhmenu] + 1;
if(lhsubmenu[lhmenu] > 4 ){lhsubmenu[lhmenu] =lhsubmenu[lhmenu] - 5;}
}}
setprop("/instrumentation/gps-annunciator/mode-string[0]",LEFTMODES[lhmenu] ~ PAGENUM[lhsubmenu[lhmenu]]);
}

####################################
# right hand knob

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
}}}

####################################
rh_menu_modify = func (){
test=arg[0];
if(test == 1){
rhmenu = rhmenu - 1;
if(rhmenu < 0 ){rhmenu =rhmenu + 10;}
}
else{
if(test == 2){
rhmenu = rhmenu + 1;
if(rhmenu > 7 ){rhmenu =rhmenu - 10;}
}}
setprop("/instrumentation/gps-annunciator/mode-string[1]",RIGHTMODES[rhmenu] ~ PAGENUM[rhsubmenu[rhmenu]]);
}
####################################
rh_submenu_modify = func (){
test=arg[0];
if(test == 1){
rhsubmenu[rhmenu] = rhsubmenu[rhmenu] - 1;
if(rhsubmenu[rhmenu] < 0 ){rhsubmenu[rhmenu] =rhsubmenu[rhmenu] + 5;}
}
else{
if(test == 2){
rhsubmenu[rhmenu] = rhsubmenu[rhmenu] + 1;
if(rhsubmenu[rhmenu] > 4 ){rhsubmenu[rhmenu] =rhsubmenu[rhmenu] - 5;}
}}
setprop("/instrumentation/gps-annunciator/mode-string[1]",RIGHTMODES[rhmenu] ~ PAGENUM[rhsubmenu[rhmenu]]);
}
####################################
direct_to = func {
setprop("/instrumentation/gps/wp/wp/waypoint-type","fix");
setprop("/instrumentation/gps/wp/wp/ID","");
setprop("/instrumentation/gps/wp/wp/name","");
setprop("/instrumentation/gps/wp/wp/latitude-deg",getprop("/position/latitude-deg"));
setprop("/instrumentation/gps/wp/wp/longitude-deg",getprop("/position/longitude-deg"));
}
####################################
registerTimer = func {
    settimer(update_systems, 0);
}
registerTimer();
