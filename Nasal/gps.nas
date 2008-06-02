####	gps routines ####
var gpsmode = nil;
var gpsnode = nil;

var stall = 0.0;
var rhmenu = nil;
var lhmenu = nil;
var dmode = nil;
var getpage = nil;
var modestring1 = nil;

#GPS KLN90B gps
var GPS = {
    new : func {
    m = { parents : [GPS]};
    m.LEFTMODES =["TRI ","MOD ","FPL ","NAV ","CAL ","STA ","SET ","OTH "];
    m.RIGHTMODES =["CTR ","REF ","ACT ","D/T ","NAV ","APT ","VOR ","NDB ","INT ","SUP "];
    m.Page1 =["1","2","3","4","5","6","7","8","9","10"];
    m.Page2 =["1","2","3","4","5","6","7","8","9","10"];
    m.rhmenu=5;
    m.lhmenu=3;
    m.lhsubmenu =[0,0,0,0,0,0,0,0];
    m.rhsubmenu =[0,0,0,0,0,0,0,0,0,0];
    m.gps = props.globals.getNode("instrumentation/gps");
    m.serviceable = m.gps.getNode("serviceable");
    m.serviceable.setBoolValue(0);
    m.power=props.globals.getNode("systems/electrical/outputs/gps",1);
    if(m.power.getValue()==nil)m.power.setDoubleValue(0);
    m.dtrk=props.globals.getNode("instrumentation/gps/wp/wp[1]/desired-course-deg",1);
    m.mode0 = props.globals.getNode("instrumentation/gps-annunciator/mode-string[0]",1);
    m.mode0.setValue("POWER OFF");
    m.mode1 = props.globals.getNode("instrumentation/gps-annunciator/mode-string[1]",1);
    m.mode1.setValue("POWER OFF");
    m.slaved = props.globals.getNode("instrumentation/nav/slaved-to-gps",1);
    m.slaved.setBoolValue(1);
    m.legmode = m.gps.getNode("leg-mode",1);
    m.legmode.setBoolValue(1);
    m.appr = m.gps.getNode("approach-active",1);
    m.appr.setBoolValue(0);
return m;
    },
##################
    powerup : func {
        var srv = me.serviceable.getValue();
        srv=1-srv;
        me.serviceable.setBoolValue(srv);
        me.update();
    },
##################
    update : func (){
        me.mode0.setValue("");
        me.mode1.setValue("");
        if(me.power.getValue() > 5){
            me.mode0.setValue("POWER OFF");
            me.mode1.setValue("POWER OFF");
            if(me.serviceable.getBoolValue()){
                me.mode0.setValue(me.LEFTMODES[me.lhmenu] ~ me.Page1[me.lhsubmenu[me.lhmenu]]);
                me.mode1.setValue(me.RIGHTMODES[me.rhmenu] ~ me.Page2[me.rhsubmenu[me.rhmenu]]);
            }
        }
        me.lh_menu_modify(0);
        me.lh_submenu_modify(0);
        me.rh_menu_modify(0);
        me.rh_submenu_modify(0);
    },
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
    lh_menu_update : func (test){
        me.mode0.setValue("POWER OFF");
        if(me.power.getValue() > 5){
            if(test == 1)me.lh_menu_modify(1);
            if(test == 2)me.lh_menu_modify(2);
            if(test == 3)me.lh_submenu_modify(1);
            if(test == 4)me.lh_submenu_modify(2);
        }
    },
#################
    lh_menu_modify : func (tst1){
        if(tst1 == 1){
            me.lhmenu -= 1;
            if(me.lhmenu < 0 )me.lhmenu += 8;
        }elsif(tst1 == 2){
            me.lhmenu += 1;
            if(me.lhmenu > 7 )me.lhmenu -= 8;
        }
        me.mode0.setValue(me.LEFTMODES[me.lhmenu] ~ me.Page1[me.lhsubmenu[me.lhmenu]]);
    },
#################
    lh_submenu_modify : func (tst2){
        if(tst2 == 1){
            me.lhsubmenu[me.lhmenu] -= 1;
            if(me.lhsubmenu[me.lhmenu] < 0 )me.lhsubmenu[me.lhmenu] +=5;
        }elsif(tst2 == 2){
            me.lhsubmenu[me.lhmenu] += 1;
            if(me.lhsubmenu[me.lhmenu] > 4 )me.lhsubmenu[me.lhmenu] -= 5;
        }
        me.mode0.setValue(me.LEFTMODES[me.lhmenu] ~ me.Page1[me.lhsubmenu[me.lhmenu]]);
    },
##################
    rh_menu_update : func (test){
        me.mode1.setValue("POWER OFF");
        if(me.power.getValue() > 5){
            if(test == 1)me.rh_menu_modify(1);
            if(test == 2)me.rh_menu_modify(2);
            if(test == 3)me.rh_submenu_modify(1);
            if(test == 4)me.rh_submenu_modify(2);
        }
    },
#################
    rh_menu_modify : func (tst1){
        if(tst1 == 1){
            me.rhmenu -= 1;
            if(me.rhmenu < 0 )me.rhmenu += 8;
        }elsif(tst1 == 2){
            me.rhmenu += 1;
            if(me.rhmenu > 7 )me.rhmenu -=8;
        }
        me.mode1.setValue(me.RIGHTMODES[me.rhmenu] ~ me.Page2[me.rhsubmenu[me.rhmenu]]);
    },
#################
    rh_submenu_modify : func (tst2){
        if(tst2 == 1){
            me.rhsubmenu[me.rhmenu] -= 1;
            if(me.rhsubmenu[me.rhmenu] < 0 )me.rhsubmenu[me.rhmenu] +=5;
        }elsif(tst2 == 2){
            me.rhsubmenu[me.rhmenu] += 1;
            if(me.rhsubmenu[me.rhmenu] > 4 )me.rhsubmenu[me.rhmenu] -= 5;
        }
        me.mode1.setValue(me.RIGHTMODES[me.rhmenu] ~ me.Page2[me.rhsubmenu[me.rhmenu]]);
    },
#################
    direct_to : func {
        setprop("instrumentation/gps/wp/wp[0]/waypoint-type","");
        setprop("instrumentation/gps/wp/wp[0]/ID","");
        setprop("instrumentation/gps/wp/wp[0]/name","");
        setprop("instrumentation/gps/wp/wp[0]/latitude-deg",getprop("position/latitude-deg"));
        setprop("instrumentation/gps/wp/wp[0]/longitude-deg",getprop("position/longitude-deg"));
    }
};

var gps = GPS.new();

setlistener("sim/signals/fdm-initialized", func {
    setprop("instrumentation/gps/wp/wp/ID",getprop("sim/tower/airport-id"));
    setprop("instrumentation/gps/wp/wp/waypoint-type","airport");
    print("KLN-90B GPS  ...Check");
    });

