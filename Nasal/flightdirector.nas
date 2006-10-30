#############################################################################
# B1900D Flight Director/Autopilot controller.
#Syd Adams
#############################################################################

# 0 - Off: v-bars hidden
# lnav -0=off,1=HDG,2=NAV,3=APR,4=BC
# vnav - 0=off,1=BARO ALT,2=ALT SELECT,3=VS,4=IAS, 5= DCS,6 = CLIMB

var GO = 0;
var lnav = 0;
var vnav=0;
var spd=0;
var lnav_last = 0;
var nav_dist = 0.0;
var last_nav_dist = 0.0;
var last_nav_time = 0.0;
var tth_filter = 0.0;
var alt_select = 0.0;
var current_alt=0.0;
var current_heading = 0.0;
var n_offset = 0.0;
var alt_offset = 0.0;
var ap_on = 0.0;
AP_hdg=nil;
AP_alt=nil;
AP_spd=nil;
AP_lnav=nil;
AP_vnav=nil;
AP_passive=nil;
var alt_alert = 0.0;
var course = 0.0;
var course_offset=0.0;
var nav_hdg_offset=0.0;
var nav_mag_brg=0.0;
var slaved = 0;
var BC_btn = nil;
#############################################################################
#############################################################################
setlistener("/sim/signals/fdm-initialized", func {
    current_alt = getprop("/instrumentation/altimeter/indicated-altitude-ft");
    alt_select = getprop("/autopilot/settings/target-altitude-ft");
    AP_hdg = props.globals.getNode("/autopilot/locks/heading",1);
    AP_alt = props.globals.getNode("/autopilot/locks/altitude",1);
    AP_spd = props.globals.getNode("/autopilot/locks/speed",1);
    AP_lnav = props.globals.getNode("/instrumentation/flightdirector/lnav",1);
    AP_vnav = props.globals.getNode("/instrumentation/flightdirector/vnav",1);
    AP_passive = props.globals.getNode("/autopilot/locks/passive-mode",1);
    BC_btn = props.globals.getNode("/instrumentation/nav/back-course-btn",1);
    GO = 1;
    print("Flight Director Check");
});

####################################################################
#######    handle KC 290 Mode Controller inputs,    ######################
####################################################################
handle_inputs = func {
    if (GO != 1) {return;}
    lnav = AP_lnav.getValue();
    vnav = AP_vnav.getValue();
    spd = AP_spd.getValue();
    
    if(lnav == 0 or lnav ==nil){AP_hdg.setValue("wing-leveler");BC_btn.setBoolValue(0);}
    if(lnav == 1){AP_hdg.setValue("dg-heading-hold");BC_btn.setBoolValue(0);if(vnav ==7 ){vnav = 0;}}
    if(lnav == 2){AP_hdg.setValue("nav1-hold");BC_btn.setBoolValue(0);if(vnav ==7 ){vnav = 0;}}
    if(lnav == 3){AP_hdg.setValue("nav1-hold");BC_btn.setBoolValue(0);}
    if(lnav == 4){AP_hdg.setValue("nav1-hold");BC_btn.setBoolValue(1);if(vnav ==7 ){vnav = 0;}}
    if(spd == 0){AP_spd.setValue("");}
    if(spd == 1){AP_spd.setValue("speed-with-throttle");}
    if(vnav == 0 or vnav == nil){AP_alt.setValue("");}
    if(vnav == 1){AP_alt.setValue("altitude-hold");}
    if(vnav == 2){AP_alt.setValue("altitude-hold");}
    if(vnav == 3){AP_alt.setValue("vertical-speed-hold");}
    if(vnav == 5){AP_spd.setValue("dcs-hold");}
    if(vnav == 6){AP_alt.setValue("pitch-hold");}
    if(vnav == 7){
    AP_alt.setValue("gs1-hold");
    if (props.globals.getNode("/instrumentation/nav/has-gs",1).getValue() == 0){
            vnav = 0;
            AP_alt.setValue("");}
        }
    maxroll = props.globals.getNode("/orientation/roll-deg",1).getValue();
    if(maxroll > 45 or maxroll < -45){AP_passive.setBoolValue(1);}
    maxpitch = props.globals.getNode("/orientation/pitch-deg").getValue();
    if(maxpitch > 45 or maxpitch < -45){AP_passive.setBoolValue(1);}
    if(props.globals.getNode("/position/altitude-agl-ft").getValue() < 200){AP_passive.setBoolValue(1);} 
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
