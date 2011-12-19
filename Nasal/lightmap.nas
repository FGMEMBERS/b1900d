#### this small script handle the intensity of the lightmap effect

#### the following values sets the intensity of the lightmap effect
var tail=1.6;
var beaconup=1.8;
var beacondown=1.8;
var landingright=2.0;
var landingleft=2.0;
var landingfront=1.6;
setprop("sim/model/livery/alfa-lightfactor", 0);

#### manage tail-logo light
setlistener("systems/electrical/outputs/logo-lights", func {
var tailstate=getprop("systems/electrical/outputs/logo-lights");
if ( tailstate == 0)
  setprop("sim/model/livery/tail-logo-lightfactor", 0);
else
  setprop("sim/model/livery/tail-logo-lightfactor", tail);
});

#### manage beacons light
setlistener("controls/lighting/beacon-state/state", func {
var battstate=getprop("systems/electrical/batt-volts");
var beaconstate=getprop("controls/lighting/beacon");
var beaconswitch=getprop("controls/lighting/beacon-state/state");
if (battstate > 0 and  beaconstate == 0) {
  setprop("sim/model/livery/beacon-up-lightfactor", beaconup);
  setprop("sim/model/livery/beacon-down-lightfactor", beacondown);
} else if (battstate > 0 and beaconstate == 1) {
  if ( beaconswitch == 1) {
    setprop("sim/model/livery/beacon-up-lightfactor", 0);
    setprop("sim/model/livery/beacon-down-lightfactor", beacondown);
  } else {
    setprop("sim/model/livery/beacon-up-lightfactor", beaconup);
    setprop("sim/model/livery/beacon-down-lightfactor", 0);
  }
} else {
  setprop("sim/model/livery/beacon-up-lightfactor", 0);
  setprop("sim/model/livery/beacon-down-lightfactor", 0);
}
});

#### manage landing lights
setlistener ("systems/electrical/outputs/landing-lights", func {
var battstate=getprop("systems/electrical/batt-volts");
var leftstate=getprop("systems/electrical/outputs/landing-lights");
if (battstate > 0 and leftstate > 0)
  setprop("sim/model/livery/landing-light-left", landingleft);
else
  setprop("sim/model/livery/landing-light-left", 0);
});

setlistener ("systems/electrical/outputs/landing-lights[1]", func {
var battstate=getprop("systems/electrical/batt-volts");
var rightstate=getprop("systems/electrical/outputs/landing-lights[1]");
if (battstate > 0 and rightstate > 0)
  setprop("sim/model/livery/landing-light-right", landingright);
else
  setprop("sim/model/livery/landing-light-right", 0);
});

#### front landing light (not used at the moment)
setlistener ("systems/electrical/outputs/lighting/taxi-lights", func {
var battstate=getprop("systems/electrical/batt-volts");
var taxistate=getprop("systems/electrical/outputs/taxi-lights");
if (battstate > 0 and taxistate > 0 )
  setprop("sim/model/livery/taxi-lightfactor", landingfront);
else
  setprop("sim/model/livery/taxi-lightfactor", 0);
});
