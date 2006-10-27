#############################################################################
#
# B1900D Flight Director/Autopilot controller.
#
# Written by Syd Adams
#Modification of Curtis Olson's flight director.
# Started 30 Jan 2006.
#
#############################################################################

#############################################################################
# Global shared variables
#############################################################################

# 0 - Off: v-bars hidden
# lnav -0=off,1=HDG,2=NAV,3=APR,4=BC
# vnav - 0=off,1=BARO ALT,2=ALT SELECT,3=VS,4=IAS, 5= DCS,6 = CLIMB


lnav = 0;
vnav=0;
lnav_last = 0;
vbar_roll = 0.0;
vbar_pitch = 0.0;
vbar_rol_propl = 0.0;
vbar_pitch_prop = 0.0;
nav_dist = 0.0;
last_nav_dist = 0.0;
last_nav_time = 0.0;
tth_filter = 0.0;
alt_select = 0.0;
current_alt=0.0;
current_heading = 0.0;
n_offset = 0.0;
alt_offset = 0.0;
kfcmode="";
ap_on = 0.0;
alt_alert = 0.0;
course = 0.0;
course_offset=0.0;
nav_hdg_offset=0.0;
nav_mag_brg=0.0;
slaved = 0;
#############################################################################
# Use tha nasal timer to call the initialization function once the sim is
# up and running
#############################################################################
setlistener("/sim/signals/fdm-initialized", func {
    current_alt = getprop("/instrumentation/altimeter/indicated-altitude-ft");
    alt_select = getprop("/autopilot/settings/target-altitude-ft");
    print("Systems Initialized");
});

#############################################################################
# handle KC 290 Mode Controller inputs, and compute correct mode/settings
#############################################################################

handle_inputs = func {
    lnav = getprop("/instrumentation/flightdirector/lnav");
    vnav = getprop("/instrumentation/flightdirector/vnav");
    ap_on = getprop("/autopilot/locks/passive-mode");

    if(lnav == 0 or lnav ==nil){setprop("autopilot/locks/heading","wing-leveler");}
    if(lnav == 1){setprop("autopilot/locks/heading","dg-heading-hold");}
    if(lnav == 2){setprop("autopilot/locks/heading","nav1-hold");}
    if(lnav == 3){setprop("autopilot/locks/heading","appr-hold");}
    if(lnav == 4){setprop("autopilot/locks/heading","bc-hold");}
    if(vnav == 0 or vnav == nil){setprop("autopilot/locks/altitude","");}
    if(vnav == 1){setprop("autopilot/locks/altitude","altitude-hold");}
    if(vnav == 2){setprop("autopilot/locks/altitude","altitude-select");}
    if(vnav == 3){setprop("autopilot/locks/speed","vs-hold");}
    if(vnav == 4){setprop("autopilot/locks/speed","ias-hold");}
    if(vnav == 5){setprop("autopilot/locks/speed","dcs-hold");}
    if(vnav == 6){setprop("autopilot/locks/speed","climb-hold");}
    maxroll = getprop("/orientation/roll-deg");
    if(maxroll > 45 or maxroll < -45){props.globals.getNode("autopilot/locks/passive-mode").setBoolValue(1);}
    maxpitch = getprop("/orientation/pitch-deg");
    if(maxpitch > 45 or maxpitch < -45){props.globals.getNode("autopilot/locks/passive-mode").setBoolValue(1);}
    if(getprop("/position/altitude-agl-ft") < 200){props.globals.getNode("autopilot/locks/passive-mode").setBoolValue(1);} 
   }

#############################################################################
#update nav gps or nav setting
#############################################################################

update_nav = func (){
    slaved = getprop("/instrumentation/nav/slaved-to-gps");
    current_heading = getprop("/orientation/heading-magnetic-deg");
    if(slaved == 0){
        desired_course = getprop("/instrumentation/nav/radials/selected-deg");
        course_offset = getprop("/instrumentation/nav/heading-needle-deflection");
        nav_mag_brg = getprop("/instrumentation/nav/heading-deg");
    }
    else
    {
        desired_course = getprop("/instrumentation/gps/wp/wp[1]/desired-course-deg");
        desired_course -= getprop("/environment/magnetic-variation-deg");
        nav_mag_brg = getprop("/instrumentation/gps/wp/wp[1]/bearing-mag-deg");
        if(desired_course < 0){desired_course += 360;}
        elsif(desired_course > 360){desired_course -= 360;}
        course_offset = getprop("/instrumentation/gps/wp/wp[1]/course-deviation-deg");
        if(course_offset > 10.0){course_offset = 10.0;}
        if(course_offset < -10.0){course_offset = -10.0;}
    }
    setprop("/instrumentation/flightdirector/dtk",desired_course);
    if(nav_mag_brg == nil){nav_mag_brg = 0;}
    nav_mag_brg -= current_heading;
    if(nav_mag_brg > 180){nav_mag_brg -= 360};
    if(nav_mag_brg < -180){nav_mag_brg += 360};

#########    set radial offset from current heading ###########
    desired_course -= current_heading;
    if(desired_course < -180){desired_course += 360;}
    elsif(desired_course > 180){desired_course -= 360;}
    setprop("/instrumentation/flightdirector/course",desired_course);

##### adjust autopilot nav heading with deviation ###########
    nav_adjust = ( course_offset * 4.5);
    nav_hdg_offset = desired_course + nav_adjust;
    if(nav_hdg_offset < -180){nav_hdg_offset += 360;}
    elsif(nav_hdg_offset > 180){nav_hdg_offset -= 360;}

    setprop("/instrumentation/flightdirector/nav-mag-brg",nav_mag_brg);
    setprop("/instrumentation/flightdirector/course-offset",course_offset);
    setprop("/instrumentation/flightdirector/nav-hdg",nav_hdg_offset);
}

#############################################################################
# main update function to be called each frame
#############################################################################

update = func {
    handle_inputs();
    update_nav();
    registerTimer();
}

#############################################################################
# Use tha nasal timer to call ourselves every frame
#############################################################################

registerTimer = func {
    settimer(update, 0);
}
registerTimer();
