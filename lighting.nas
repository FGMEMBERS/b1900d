##
# Lighting system
#
##
# Initialize internal values
#


##
# Initialize lighting system
#

# strobes ===========================================================
strobe_switch = props.globals.getNode("controls/switches/strobe", 1);
aircraft.light.new("sim/model/b1900d/lighting/strobe", 0.05, 1.50, strobe_switch);

# beacons ===========================================================
beacon_switch = props.globals.getNode("controls/switches/beacon", 1);
aircraft.light.new("sim/model/b1900d/lighting/beacon", 1.0, 1.0, beacon_switch);


power = nil;
eadi = nil;
engines = nil;
instruments = nil;
panel = nil;
volts = nil;

update_lights = func {

power = getprop("/controls/switches/master-panel");
if (power == nil) { power = 0.0;}
eadi = getprop("/controls/lighting/eadi-ehsi-norm");
if (eadi == nil) {eadi = 0.0;}
engines = getprop("/controls/lighting/engines-norm");
if (engines == nil) {engines = 0.0;}
instruments = getprop("/controls/lighting/instruments-norm");
if (instruments == nil) {instruments = 0.0;}
volts = getprop("/systems/electrical/volts");
if (volts == nil) {volts = 0.0;}
panel = getprop("/controls/lighting/panel-norm");
if (panel == nil) {panel = 0.0;}

setprop("/sim/model/b1900d/material/instruments/factor", 0.0);
setprop("/sim/model/b1900d/material/engines/factor", 0.0);
setprop("/sim/model/b1900d/material/pfd/factor", 0.0);
setprop("/sim/model/b1900d/material/panel/factor", 0.0);

   if (volts > 0.2){
setprop("/sim/model/b1900d/material/instruments/factor", instruments);
setprop("/sim/model/b1900d/material/engines/factor", engines);
setprop("/sim/model/b1900d/material/pfd/factor", eadi);
if(power > 0){
setprop("/sim/model/b1900d/material/panel/factor", panel);
setprop("/sim/model/b1900d/material/radiance/factor", panel);
  }
}

    settimer(update_lights, 0);
}


settimer(update_lights, 0);