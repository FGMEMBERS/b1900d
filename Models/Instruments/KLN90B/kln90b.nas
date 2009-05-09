#GPS KLN90B gps
var GPS = {
    new : func {
    m = { parents : [GPS]};
    m.Menu1 = 3;
    m.Menu2 = 4;
    m.Page1 = 0;
    m.Page2 = 0;
    m.LHstring=[];
    m.RHstring=[];
    m.PWR=0;
    m.gps = props.globals.initNode("instrumentation/gps");
    m.gps_annun = props.globals.initNode("instrumentation/gps-annunciator");
    m.serviceable = m.gps.initNode("serviceable",0,"BOOL");
    m.pwr=props.globals.initNode("systems/electrical/outputs/gps",0.0);
    m.dtrk=m.gps.initNode("wp/wp[1]/desired-course-deg",0.0);
    
    for(var i=0; i<7; i+=1) {
        append(m.LHstring,m.gps_annun.initNode("LHmode-string["~i~"]","","STRING"));
        append(m.RHstring,m.gps_annun.initNode("RHmode-string["~i~"]","","STRING"));
    }

    m.slaved = props.globals.initNode("instrumentation/nav/slaved-to-gps",0."BOOL");
    m.legmode = m.gps.initNode("leg-mode");
    m.appr = m.gps.initNode("approach-active",0."BOOL");
    return m;
    },
##################
    draw_display : func(){
        for(var i=0; i<7; i+=1) {
        me.LHstring[i].setValue("");
        me.RHstring[i].setValue("");
    }

    if(me.PWR == 0){
            me.LHstring[6].setValue("POWER OFF");
            me.RHstring[6].setValue("POWER OFF");
        }else{
        me.setmode1();
        me.setmode2();
        }
    },
##################
    power_up : func(){
        var tmp=me.serviceable.getValue();
        tmp=1-tmp;
        me.serviceable.setBoolValue(tmp);
        if(tmp==0){
            setprop("instrumentation/gps/wp/wp[1]/waypoint-type","");
            setprop("/instrumentation/gps/wp/wp[1]/ID","");
            setprop("instrumentation/gps/wp/wp[1]/name","");
        }
        me.get_power();
    },
##################
    get_power : func(){
        if(me.pwr.getValue()>5){
        me.PWR=1;
        }else{
        me.PWR=0;
        }
    },
##################
    setmode1: func(){
        if(me.Menu1 == 0){
            me.set_TRI1();
        }elsif(me.Menu1 == 1){
            me.set_MOD1();
        }elsif(me.Menu1 == 2){
            me.set_FPL1();
        }elsif(me.Menu1 == 3){
            me.set_NAV1();
        }elsif(me.Menu1 == 4){
            me.set_CAL1();
        }elsif(me.Menu1 == 5){
            me.set_STA1();
        }elsif(me.Menu1 == 6){
            me.set_SET1();
        }elsif(me.Menu1 == 7){
            me.set_OTH1();
        }
    },
##################
    setmode2: func(){
        if(me.Menu2 == 0){
            me.set_CTR2();
        }elsif(me.Menu2 == 1){
            me.set_REF2();
        }elsif(me.Menu2 == 2){
            me.set_ACT2();
        }elsif(me.Menu2 == 3){
            me.set_DT2();
        }elsif(me.Menu2 == 4){
            me.set_NAV2();
        }elsif(me.Menu2 == 5){
            me.set_APT2();
        }elsif(me.Menu2 == 6){
            me.set_VOR2();
        }elsif(me.Menu2 == 7){
            me.set_NDB2();
        }elsif(me.Menu2 == 8){
            me.set_INT2();
        }elsif(me.Menu2 == 9){
            me.set_SUP2();
        }
    },

################################
#######Update Pages ############
###############################
####### LEFT MENU ###########
#############################
    set_TRI1: func {
        var num=me.Page1+1;
        me.LHstring[6].setValue("TRI "~num);
    },
################
    set_MOD1: func {
        var num=me.Page1+1;
        me.LHstring[6].setValue("MOD "~num);
    },
###############
    set_FPL1: func {
        var num=me.Page1+1;
        me.LHstring[6].setValue("FPL "~num);
    },
################
    set_NAV1: func {
        var num=me.Page1+1;
        me.LHstring[6].setValue("NAV "~num);
        var buf="";
        var ID=getprop("instrumentation/gps/wp/wp/ID");
        if(ID==nil)ID="D";
        var ID2=getprop("instrumentation/gps/wp/wp[1]/ID");
        if(ID2==nil)ID2=" ";
        buf = sprintf("   %s > %s",ID,ID2);
        me.LHstring[0].setValue(buf);
        me.LHstring[1].setValue("* * * * * * * * * * *");
        var DIS=getprop("instrumentation/gps/wp/wp[1]/distance-nm");
        buf = sprintf("DIS     %4.0fNM",DIS);
        me.LHstring[2].setValue(buf);
        var GS=getprop("velocities/groundspeed-kt");
        buf = sprintf("GS     %3.0fKT",GS);
        me.LHstring[3].setValue(buf);
        var ETE=getprop("instrumentation/gps/wp/wp[1]/TTW");
        buf = sprintf("ETE     %s",ETE);
        me.LHstring[4].setValue(buf);
        var BRG=getprop("instrumentation/gps/wp/wp[1]/bearing-mag-deg");
        buf = sprintf("BRG     %3.0f",BRG);
        me.LHstring[5].setValue(buf);
    },
#################
    set_CAL1: func {
        var num=me.Page1+1;
        me.LHstring[6].setValue("CAL "~num);
    },
#################
    set_STA1: func {
        var num=me.Page1+1;
        me.LHstring[6].setValue("STA "~num);
    },
##################
    set_SET1: func {
        var num=me.Page1+1;
        me.LHstring[6].setValue("SET "~num);
    },
##################
    set_OTH1: func {
        var num=me.Page1+1;
        me.LHstring[6].setValue("OTH "~num);
    },
##############################
####### RIGHT MENU ###########
##############################
    set_CTR2: func {
        var num=me.Page2+1;
        me.RHstring[6].setValue("CTR "~num);
    },
#################
    set_REF2: func {
        var num=me.Page2+1;
        me.RHstring[6].setValue("REF "~num);
    },
################
    set_ACT2: func {
        var num=me.Page2+1;
        me.RHstring[6].setValue("ACT "~num);
    },
#################
    set_DT2: func {
        var num=me.Page2+1;
        me.RHstring[6].setValue("D/T "~num);
    },
################
    set_NAV2: func {
        var num=me.Page2+1;
        me.RHstring[6].setValue("NAV "~num);
    },
###################
    set_APT2: func {
        var num=me.Page2+1;
        me.RHstring[6].setValue("APT "~num);
    },
###################
    set_VOR2: func {
        var num=me.Page2+1;
        me.RHstring[6].setValue("VOR "~num);
    },
##################
    set_NDB2: func {
        var num=me.Page2+1;
        me.RHstring[6].setValue("NDB "~num);
    },
#################
    set_INT2: func {
        var num=me.Page2+1;
        me.RHstring[6].setValue("INT "~num);
    },
##################
    set_SUP2: func {
        var num=me.Page2+1;
        me.RHstring[6].setValue("SUP "~num);
    },
##################
##################
    GPSappr : func {
        me.legmode.setBoolValue(0);
        me.slaved.setBoolValue(0);
        if(me.appr.getBoolValue()){
            me.appr.setBoolValue(0);
        }else{
            me.appr.setBoolValue(1);
        }
},
##################
    GPScrs : func {
        me.appr.setBoolValue(0);
        if(me.legmode.getBoolValue()){
            me.legmode.setBoolValue(0);
            me.slaved.setBoolValue(0);
        }else{
            me.legmode.setBoolValue(1);
            me.slaved.setBoolValue(1);
        }
},
##################
    lh_menu : func (test){
        if(me.PWR != 0){
            me.Menu1 +=test;
            if(me.Menu1 > 7)me.Menu1 -= 8;
            if(me.Menu1 < 0)me.Menu1 += 8;
        }
    },
##################
    lh_page : func (test){
        if(me.PWR != 0){
            me.Page1 +=test;
            if(me.Page1 > 7)me.Page1 -= 8;
            if(me.Page1 < 0)me.Page1 += 8;
        }
    },
##################
    rh_menu : func (test){
        if(me.PWR != 0){
            me.Menu2 +=test;
            if(me.Menu2 > 7)me.Menu2 -= 8;
            if(me.Menu2 < 0)me.Menu2 += 8;
        }
    },
##################
    rh_page : func (test){
        if(me.PWR != 0){
            me.Page2 +=test;
            if(me.Page2 > 7)me.Page2 -= 8;
            if(me.Page2 < 0)me.Page2 += 8;
        }
    },
#################
    direct_to : func {
        if(me.PWR != 0){
            setprop("instrumentation/gps/wp/wp[0]/waypoint-type","");
            setprop("instrumentation/gps/wp/wp[0]/ID","");
            setprop("instrumentation/gps/wp/wp[0]/name","");
            setprop("instrumentation/gps/wp/wp[0]/latitude-deg",getprop("position/latitude-deg"));
            setprop("instrumentation/gps/wp/wp[0]/longitude-deg",getprop("position/longitude-deg"));
        }
    }
};
#########################################################

var Gps = GPS.new();

setlistener("sim/signals/fdm-initialized", func {
    setprop("instrumentation/gps/wp/wp/ID",getprop("sim/tower/airport-id"));
    setprop("instrumentation/gps/wp/wp/waypoint-type","airport");
    print("KLN-90B GPS  ...Check");
    settimer(update_gps,5);
    });

var update_gps = func {
    Gps.get_power();
    Gps.draw_display();
    settimer(update_gps,0);
}

