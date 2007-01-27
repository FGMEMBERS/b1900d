# 
# B1900D   electrical system.
# 

battery = nil;
alternator1 = nil;
alternator2 = nil;
var last_time = 0.0;
var vbus_volts = 0.0;
var ebus1_volts = 0.0;
var ebus2_volts = 0.0;
var ammeter_ave = 0.0;

setlistener("/sim/signals/fdm-initialized", func {
    battery = BatteryClass.new();
    alternator1 = AlternatorClass.new();
    alternator2 = AlternatorClass.new();
    setprop("/controls/electric/external-power", 0);
    setprop("/controls/switches/landing-light[0]", 0);
    setprop("/controls/switches/landing-light[1]", 0);
    setprop("/controls/switches/taxi-lights", 0);
    setprop("/controls/switches/ice-light", 0);
    setprop("/controls/switches/nav-lights", 0);
    setprop("/controls/switches/beacon", 0);
    setprop("/controls/switches/strobe", 0);
    setprop("/controls/switches/recog", 0);
    setprop("/controls/switches/logo", 0);
    print("Electrical Systems  ...Check");
});

BatteryClass = {};

BatteryClass.new = func {
    obj = { parents : [BatteryClass],
            ideal_volts : 24.0,
            ideal_amps : 30.0,
            amp_hours : 34.0,
            charge_percent : 1.0,
            charge_amps : 7.0 };
    return obj;
}

BatteryClass.apply_load = func( amps, dt ) {
    amphrs_used = amps * dt / 3600.0;
    percent_used = amphrs_used / me.amp_hours;
    me.charge_percent -= percent_used;
    if ( me.charge_percent < 0.0 ) {
        me.charge_percent = 0.0;
    } elsif ( me.charge_percent > 1.0 ) {
        me.charge_percent = 1.0;
    }
    return me.amp_hours * me.charge_percent;
}

BatteryClass.get_output_volts = func {
    x = 1.0 - me.charge_percent;
    tmp = -(3.0 * x - 1.0);
    factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
    return me.ideal_volts * factor;
}

BatteryClass.get_output_amps = func {
    x = 1.0 - me.charge_percent;
    tmp = -(3.0 * x - 1.0);
    factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
    return me.ideal_amps * factor;
}

AlternatorClass = {};

AlternatorClass.new = func {
    obj = { parents : [AlternatorClass],
            rpm_source : "/engines/engine[0]/rpm",
            rpm_threshold : 600.0,
            ideal_volts : 28.0,
            ideal_amps : 60.0 };
    setprop( obj.rpm_source, 0.0 );
    return obj;
}

AlternatorClass.apply_load = func( amps, dt ) {
    rpm = getprop( me.rpm_source );
    factor = rpm / me.rpm_threshold;
    if ( factor > 1.0 ) {
        factor = 1.0;
    }
    available_amps = me.ideal_amps * factor;
    return available_amps - amps;
}

AlternatorClass.get_output_volts = func {
    rpm = getprop( me.rpm_source );
    factor = rpm / me.rpm_threshold;
    if ( factor > 1.0 ) {
        factor = 1.0;
    }
    return me.ideal_volts * factor;
}

AlternatorClass.get_output_amps = func {
    rpm = getprop( me.rpm_source );
    factor = rpm / me.rpm_threshold;
    if ( factor > 1.0 ) {
        factor = 1.0;
    }
    return me.ideal_amps * factor;
}

update_electrical = func {
if(getprop("/sim/signals/fdm-initialized")){
    time = getprop("/sim/time/elapsed-sec");
    dt = time - last_time;
    last_time = time;
    update_virtual_bus( dt );
    }
settimer(update_electrical, 0);
}

update_virtual_bus = func( dt ) {
    battery_volts = battery.get_output_volts();
    alternator1_volts = alternator1.get_output_volts();
    alternator2_volts = alternator2.get_output_volts();
external_volts = 0.0;
  load = 0.0;

    master_bat = getprop("/controls/electric/battery-switch");
    master_alt1 = getprop("/controls/electric/engine[0]/generator");
    master_alt2 = getprop("/controls/electric/engine[1]/generator");
    external_switch = getprop("/controls/electric/external-power");
    engine0_state = getprop("/engines/engine[0]/running");
    engine1_state = getprop("/engines/engine[1]/running");
    if (!engine0_state and (!engine1_state)){external_volts = 24.0;}

    bus_volts = 0.0;
    power_source = nil;
    if ( master_bat ) {
        bus_volts = battery_volts;
        power_source = "battery";
    }
   if ( master_alt1 and (alternator1_volts > bus_volts) ) {
        bus_volts = alternator1_volts;
        power_source = "alternator1";
    }
    if ( master_alt2 and (alternator2_volts > bus_volts) ) {
        bus_volts = alternator2_volts;
        power_source = "alternator2";
    }
    if (external_switch and ( external_volts > bus_volts) ) {
        bus_volts = external_volts;
    }
    starter_switch = getprop("/controls/engines/engine[0]/starter");
    starter_volts = 0.0;
    if ( starter_switch ) {
        starter_volts = bus_volts;
    }
    setprop("/systems/electrical/outputs/starter[0]", starter_volts);

    load += electrical_bus_1();
    load += electrical_bus_2();
    load += cross_feed_bus();
    load += avionics_bus_1();
    load += avionics_bus_2();

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

    setprop("/systems/electrical/amps", ammeter_ave);
    setprop("/systems/electrical/volts", bus_volts);
    vbus_volts = bus_volts;
    return load;
}

electrical_bus_1 = func() {
    bus_volts = vbus_volts;
    load = 0.0;
    
    if ( getprop("/controls/circuit-breakers/cabin-lights-pwr") ) {
        setprop("/systems/electrical/outputs/cabin-lights", bus_volts);
    } else {
        setprop("/systems/electrical/outputs/cabin-lights", 0.0);
    }

    setprop("/systems/electrical/outputs/instr-ignition-switch", bus_volts);

    if ( getprop("/controls/engines/engine[0]/fuel-pump") ) {
        setprop("/systems/electrical/outputs/fuel-pump", bus_volts);
    } else {
        setprop("/systems/electrical/outputs/fuel-pump", 0.0);
    }

    if ( getprop("/controls/switches/landing-light[0]") ) {
        setprop("/systems/electrical/outputs/landing-light[0]", bus_volts);
    } else {
        setprop("/systems/electrical/outputs/landing-light[0]", 0.0 );
    }

    if ( getprop("/controls/switches/landing-light[1]") ) {
        setprop("/systems/electrical/outputs/landing-light[1]", bus_volts);
    } else {
        setprop("/systems/electrical/outputs/landing-light[1]", 0.0 );
    }

    if ( getprop("/controls/switches/nav-lights") ) {
        setprop("/systems/electrical/outputs/nav-lights", bus_volts);
    } else {
        setprop("/systems/electrical/outputs/nav-lights", 0.0 );
    }

    if ( getprop("/controls/switches/beacon" ) ) {
        setprop("/systems/electrical/outputs/beacon", bus_volts);
        if ( bus_volts > 1.0 ) { load += 7.5; }
    } else {
        setprop("/systems/electrical/outputs/beacon", 0.0);
    }

    if ( getprop("/controls/switches/logo" ) ) {
        setprop("/systems/electrical/outputs/logo", bus_volts);
        if ( bus_volts > 1.0 ) { load += 7.5; }
    } else {
        setprop("/systems/electrical/outputs/logo", 0.0);
    }

    if ( getprop("/controls/switches/recog" ) ) {
        setprop("/systems/electrical/outputs/recog", bus_volts);
        if ( bus_volts > 1.0 ) { load += 7.5; }
    } else {
        setprop("/systems/electrical/outputs/recog", 0.0);
    }

    setprop("/systems/electrical/outputs/flaps", bus_volts);

    ebus1_volts = bus_volts;

    return load;
}


electrical_bus_2 = func() {
    bus_volts = vbus_volts;
    load = 0.0;

    setprop("/systems/electrical/outputs/turn-coordinator", bus_volts);
  
    if ( getprop("/controls/switches/map-lights" ) ) {
        setprop("/systems/electrical/outputs/map-lights", bus_volts);
        if ( bus_volts > 1.0 ) { load += 7.0; }
    } else {
        setprop("/systems/electrical/outputs/map-lights", 0.0);
    }
  
    if ( getprop("/controls/switches/master-panel" ) ) {
    setprop("/systems/electrical/outputs/instrument-lights", bus_volts);
        if ( bus_volts > 1.0 ) { load += 7.0; }
    } else {
    setprop("/systems/electrical/outputs/instrument-lights", 0.0);
    }
  
    if ( getprop("/controls/switches/strobe" ) ) {
        setprop("/systems/electrical/outputs/strobe-lights", bus_volts);
    } else {
        setprop("/systems/electrical/outputs/strobe-lights", 0.0);
    }
  
    if ( getprop("/controls/switches/taxi-lights" ) ) {
        setprop("/systems/electrical/outputs/taxi-lights", bus_volts);
    } else {
        setprop("/systems/electrical/outputs/taxi-lights", 0.0);
    }

    if ( getprop("/controls/switches/ice-light" ) ) {
        setprop("/systems/electrical/outputs/ice-light", bus_volts);
    } else {
        setprop("/systems/electrical/outputs/ice-light", 0.0);
    }
 
    if ( getprop("/controls/switches/pitot-heat" ) ) {
        setprop("/systems/electrical/outputs/pitot-heat", bus_volts);
    } else {
        setprop("/systems/electrical/outputs/pitot-heat", 0.0);
    }
    ebus2_volts = bus_volts;
    return load;
}


cross_feed_bus = func() {
    if ( ebus1_volts > ebus2_volts ) {
        bus_volts = ebus1_volts;
    } else {
        bus_volts = ebus2_volts;
    }
    load = 0.0;
    setprop("/systems/electrical/outputs/annunciators", bus_volts);
    return load;
}


avionics_bus_1 = func() {
    master_av = getprop("/controls/switches/master-avionics");
    if ( master_av ) {
        bus_volts = ebus1_volts;
    } else {
        bus_volts = 0.0;
    }
    load = 0.0;
    
    setprop("/systems/electrical/outputs/avionics-fan", bus_volts);
    setprop("/systems/electrical/outputs/mk-viii", bus_volts);
    setprop("/systems/electrical/outputs/gps", bus_volts);
    setprop("/systems/electrical/outputs/hsi", bus_volts);
    setprop("/systems/electrical/outputs/nav[0]", bus_volts);
    setprop("/systems/electrical/outputs/dme", bus_volts);
    setprop("/systems/electrical/outputs/audio-panel[0]", bus_volts);
    return load;
}

avionics_bus_2 = func() {
    master_av = getprop("/controls/switches/master-avionics");

    if ( master_av ) {
        bus_volts = ebus2_volts;
    } else {
        bus_volts = 0.0;
    }
    load = 0.0;

    setprop("/systems/electrical/outputs/nav[1]", bus_volts);
    setprop("/systems/electrical/outputs/audio-panel[1]", bus_volts);
    setprop("/systems/electrical/outputs/transponder", bus_volts);
    setprop("/systems/electrical/outputs/autopilot", bus_volts);
    setprop("/systems/electrical/outputs/adf", bus_volts);
    return load;
}

registerTimer = func {
    settimer(update_electrical, 0);
}
registerTimer();