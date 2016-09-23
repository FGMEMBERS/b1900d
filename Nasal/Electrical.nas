##
# Initialize internal values
#

var battery = nil;
var left_alternator = nil;
var right_alternator = nil;

var last_time = 0.0;

var vbus_volts = 0.0;
var ebus1_volts = 0.0;
var ebus2_volts = 0.0;

var ammeter_ave = 0.0;

var strobe_switch = props.globals.initNode("controls/lighting/strobe/switch",0,"BOOL");
aircraft.light.new("controls/lighting/strobe", [0.05, 0.05, 0.05, 1.7], strobe_switch);
var beacon_switch = props.globals.initNode("controls/lighting/beacon/switch",0,"BOOL");
aircraft.light.new("controls/lighting/beacon", [1.0, 1.0], beacon_switch);

##
# Initialize the electrical system
#

init_electrical = func {
    battery = BatteryClass.new();
    left_alternator = AlternatorClass.new(0);
	right_alternator = AlternatorClass.new(1);

    # set initial switch positions
	setprop("/controls/electric/battery-switch", 0, "BOOL");
	setprop("/controls/electric/avionics-switch", 0, "BOOL");

    # Request that the update function be called next frame
    settimer(update_electrical, 0);
    print("Electrical system initialized");
}

##
# Battery model class.
#

BatteryClass = {};

BatteryClass.new = func {
    var obj = { parents : [BatteryClass],
                ideal_volts : 24.0,
                ideal_amps : 30.0,
                amp_hours : 12.75,
                charge_percent : 1.0,
                charge_amps : 7.0 };
    return obj;
}

##
# Passing in positive amps means the battery will be discharged.
# Negative amps indicates a battery charge.
#

BatteryClass.apply_load = func( amps, dt ) {
    var amphrs_used = amps * dt / 3600.0;
    var percent_used = amphrs_used / me.amp_hours;
    var charge_percent = me.charge_percent;
    charge_percent -= percent_used;
    if ( charge_percent < 0.0 ) {
        charge_percent = 0.0;
    } elsif ( charge_percent > 1.0 ) {
        charge_percent = 1.0;
    }
    if ((charge_percent < 0.1)and(me.charge_percent >= 0.1))
    {
        print("Warning: Low battery! Enable alternator or apply external power to recharge battery.");
    }
    me.charge_percent = charge_percent;
    setprop("/systems/electrical/battery-charge-percent", charge_percent);
    # print( "battery percent = ", charge_percent);
    return me.amp_hours * charge_percent;
}

##
# Return output volts based on percent charged.  Currently based on a simple
# polynomial percent charge vs. volts function.
#

BatteryClass.get_output_volts = func {
    var x = 1.0 - me.charge_percent;
    var tmp = -(3.0 * x - 1.0);
    var factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
    return me.ideal_volts * factor;
}


##
# Return output amps available.  This function is totally wrong and should be
# fixed at some point with a more sensible function based on charge percent.
# There is probably some physical limits to the number of instantaneous amps
# a battery can produce (cold cranking amps?)
#

BatteryClass.get_output_amps = func {
    var x = 1.0 - me.charge_percent;
    var tmp = -(3.0 * x - 1.0);
    var factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
    return me.ideal_amps * factor;
}


##
# Alternator model class.
#

AlternatorClass = {};

AlternatorClass.new = func(source) {
    var obj = { parents : [AlternatorClass],
                rpm_source : "/engines/engine["~source~"]/n1",
                rpm_threshold : 65.0,
                ideal_volts : 28.0,
                ideal_amps : 60.0 };
    setprop( obj.rpm_source, 0.0 );
    return obj;
}

##
# Computes available amps and returns remaining amps after load is applied
#

AlternatorClass.apply_load = func( amps, dt ) {
    # Scale alternator output for rpms < 800.  For rpms >= 800
    # give full output.  This is just a WAG, and probably not how
    # it really works but I'm keeping things "simple" to start.
    var rpm = getprop( me.rpm_source );
    var factor = rpm / me.rpm_threshold;
    if ( factor > 1.0 ) {
        factor = 1.0;
    }
    # print( "alternator amps = ", me.ideal_amps * factor );
    var available_amps = me.ideal_amps * factor;
    return available_amps - amps;
}

##
# Return output volts based on rpm
#

AlternatorClass.get_output_volts = func {
    # scale alternator output for rpms < 800.  For rpms >= 800
    # give full output.  This is just a WAG, and probably not how
    # it really works but I'm keeping things "simple" to start.
	var factor = 0.0;
    var rpm = getprop( me.rpm_source );
	factor = rpm / me.rpm_threshold;
	if ( factor > 1.0 ) {
        factor = 1.0;
    }
    # print( "alternator volts = ", me.ideal_volts * factor );
    return me.ideal_volts * factor;
}


##
# Return output amps available based on rpm.
#

AlternatorClass.get_output_amps = func {
    # scale alternator output for rpms < 800.  For rpms >= 800
    # give full output.  This is just a WAG, and probably not how
    # it really works but I'm keeping things "simple" to start.
    var rpm = getprop( me.rpm_source );
    var factor = rpm / me.rpm_threshold;
    if ( factor > 1.0 ) {
        factor = 1.0;
    }
    # print( "alternator amps = ", ideal_amps * factor );
    return me.ideal_amps * factor;
}


##
# This is the main electrical system update function.
#

update_electrical = func {
    var time = getprop("/sim/time/elapsed-sec");
    var dt = time - last_time;
    last_time = time;

    update_virtual_bus( dt );

    # Request that the update function be called again next frame
    settimer(update_electrical, 0);
}

update_virtual_bus = func( dt ) {
    var serviceable = getprop("/systems/electrical/serviceable");
    var external_volts = 0.0;
    var load = 0.0;
    var battery_volts = 0.0;
    var left_alternator_volts = 0.0;
	var right_alternator_volts = 0.0;
    if ( serviceable ) {
        battery_volts = battery.get_output_volts();
        left_alternator_volts = left_alternator.get_output_volts();
		right_alternator_volts = right_alternator.get_output_volts();
    }

	# switch state
	var master_bat = getprop("/controls/electric/battery-switch");
	var left_bus_tie = getprop("/controls/electric/engine[0]/bus-tie");
	var right_bus_tie = getprop("/controls/electric/engine[1]/bus-tie");
    var left_AC_bus_tie = getprop("/controls/electric/LH-AC-bus");
    var right_AC_bus_tie = getprop("/controls/electric/RH-AC-bus");

	if (getprop("/controls/electric/external-power"))
	{
		external_volts = 28;
	}

	# determine power source
    var bus_volts = 0.0;
    var power_source = nil;
    if ( master_bat ) {
        bus_volts = battery_volts;
        power_source = "battery";
    }

	if (left_bus_tie) {
		if (left_alternator_volts > bus_volts)
			if (left_alternator_volts < 24)
				bus_volts = 0.0;
			else {
				bus_volts = left_alternator_volts;
			    power_source = "alternator";
            }
	}

	if (right_bus_tie) {
		if (right_alternator_volts > bus_volts)
			if (right_alternator_volts < 24)
				bus_volts = 0.0;
			else {
				bus_volts = right_alternator_volts;
			    power_source = "alternator";
            }
    }

    if (external_volts > bus_volts) {
        bus_volts = external_volts;
        power_source = "external";
    }

    setprop("/systems/electrical/LH-ac-bus", left_AC_bus_tie * 115);
    setprop("/systems/electrical/RH-ac-bus", right_AC_bus_tie * 115);

	################### DEBUG ###################
    #print( "virtual bus volts = ", bus_volts );
	#print( "l_alt volts = ", left_alternator_volts );
	#print( "r_alt volts = ", right_alternator_volts );

	load += battery_bus();
	load += triple_fed_bus();
	load += avionics_bus();
	load += left_gen_bus();

    # system loads and ammeter gauge
    var ammeter = 0.0;
    if ( bus_volts > 1.0 ) {
        # ammeter gauge
        if ( power_source == "battery" ) {
            ammeter = -load;
        } else {
            ammeter = battery.charge_amps;
        }
    }

    # charge/discharge the battery
    if ( power_source == "battery" ) {
        battery.apply_load( load, dt );
    } elsif ( bus_volts > battery_volts ) {
        battery.apply_load( -battery.charge_amps, dt );
    }

    # filter ammeter needle pos
    ammeter_ave = 0.8 * ammeter_ave + 0.2 * ammeter;

	if (bus_volts > 24)
        vbus_volts = bus_volts;
    else
        vbus_volts = 0.0;

	setprop("/systems/electrical/volts", bus_volts);
    setprop("/systems/electrical/amps", ammeter_ave);

	return load;
}

battery_bus = func() {
	# we are fed from the "virtual" bus
	var bus_volts = vbus_volts;
	var load = 0.0;

	return load;
}

triple_fed_bus = func() {
	# we are fed from the "virtual" bus
	var bus_volts = vbus_volts;
	var load = 0.0;
	var l_starter_switch = getprop("/controls/electric/left-starter");
	var r_starter_switch = getprop("/controls/electric/right-starter");

	setprop("/systems/electrical/outputs/triple-fed-bus", bus_volts);
	setprop("/systems/electrical/outputs/warning-annunciator", bus_volts);
	setprop("/systems/electrical/outputs/caution-annunciator", bus_volts);

	### check starter switch and toggle
	if (l_starter_switch) {
		setprop("controls/engines/engine[0]/starter", 1);
		load += 12;
	} else
		setprop("controls/engines/engine[0]/starter", 0);

	if (r_starter_switch) {
		setprop("/controls/engines/engine[1]/starter", 1);
		load += 12;
	} else
		setprop("controls/engines/engine[1]/starter", 0);

	return load;
}

### TODO - add redundancy if triple-fed-bus fails
left_gen_bus = func() {
	var bus_volts = vbus_volts;
	var load = 0.0;
	var left_landing_light = getprop("/controls/lighting/landing-lights[0]");
	var right_landing_light = getprop("/controls/lighting/landing-lights[1]");
	var taxi_light = getprop("/controls/lighting/taxi-lights");
	var ice_light = getprop("/controls/lighting/ice-lights");
	var nav_light = getprop("/controls/lighting/nav-lights");
	var beacon_light = getprop("/controls/lighting/beacon/switch");
	var strobe_light = getprop("/controls/lighting/strobe/switch");
	var logo_light = getprop("/controls/lighting/logo-lights");
	var recog_light = getprop("/controls/lighting/recog-lights");
	var master_panel_switch = getprop("/controls/lighting/master-panel");

	setprop("/systems/electrical/outputs/lights/landing-lights[0]", 1*left_landing_light);
	setprop("/systems/electrical/outputs/lights/landing-lights[1]", 1*right_landing_light);
    setprop("/systems/electrical/outputs/lights/logo-lights", 1*logo_light);
    if (taxi_light) setprop("/systems/electrical/outputs/lights/taxi-lights", 1*bus_volts);
	if (ice_light) setprop("/systems/electrical/outputs/lights/ice-lights", 1*bus_volts);
	if (nav_light) setprop("/systems/electrical/outputs/lights/nav-lights", bus_volts);
    if (master_panel_switch) {
        setprop("/systems/electrical/outputs/lights/instrument-lights", 1*bus_volts);
	    setprop("/systems/electrical/outputs/lights/eng-lights", 1*bus_volts);
    }
    # setprop("/systems/electrical/outputs/lights/beacon[0]", 1*beacon_light);
	# setprop("/systems/electrical/outputs/lights/beacon[1]", 1*beacon_light);
	# setprop("/systems/electrical/outputs/lights/strobe", 1*bus_volts);

    ### Make them flash
    if(strobe_light or beacon_light)
        update_strobes();

	return load;
}

right_gen_bus = func() {
	var load = 0.0;

	return load;
}
###

avionics_bus = func() {
	# we are fed from virtual bus
	var load = 0.0;
	var avionics_switch = getprop("/controls/electric/avionics-switch");
	var pilot_efis_switch = getprop("/controls/electric/efis/bank[0]");
	var copilot_efis_switch = getprop("/controls/electric/efis/bank[1]");

	if (avionics_switch){
		var bus_volts = vbus_volts;
	} else
		bus_volts = 0.0;

	setprop("/systems/electrical/outputs/nav[0]", bus_volts);
	setprop("/systems/electrical/outputs/nav[1]", bus_volts);
	setprop("/systems/electrical/outputs/comm[0]", bus_volts);
	setprop("/systems/electrical/outputs/comm[1]", bus_volts);
	setprop("/systems/electrical/outputs/dme", bus_volts);
	setprop("/systems/electrical/outputs/adf", bus_volts);
	setprop("/systems/electrical/outputs/gps", bus_volts);
	setprop("/systems/electrical/outputs/transponder", bus_volts);
	setprop("/systems/electrical/outputs/turn-coordinator", bus_volts);
	setprop("/systems/electrical/outputs/mk-viii", bus_volts);
	setprop("/systems/electrical/outputs/fgc-65", bus_volts);

	if (pilot_efis_switch)
		setprop("/systems/electrical/outputs/efis[0]", bus_volts);
	if (copilot_efis_switch)
		setprop("/systems/electrical/outputs/efis[1]", bus_volts);

	return load;
}

update_strobes = func() {
    var bcn = getprop("controls/lighting/beacon/state");
    setprop("systems/electrical/outputs/lights/strobe", 1 * getprop("controls/lighting/strobe/state"));
    setprop("systems/electrical/outputs/lights/beacon[0]", 1 * bcn);
    setprop("systems/electrical/outputs/lights/beacon[1]", 1 * (1-bcn));
}

### Upon load, initialize electrical systems immediately
settimer(init_electrical, 0);
