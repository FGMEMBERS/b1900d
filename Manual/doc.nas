#### POH ####
var poh = nil;
var enabled = nil;
var x = nil;
var y = nil;
var z = nil;
var pitch = nil;
var page_num = nil;
var total_pages = nil;
var page_texture = nil;

setlistener("/sim/signals/fdm-initialized", func {
    poh = props.globals.getNode("sim/model/manual",1);
    enabled = poh.initNode("enabled",0,"BOOL");
    x = poh.initNode("x-offset",0,"DOUBLE");
    y = poh.initNode("y-offset",0,"DOUBLE");
    z = poh.initNode("z-offset",0,"DOUBLE");
    pitch = poh.initNode("pitch",0,"DOUBLE");
    page_num = poh.initNode("page-num",0,"INT");
    total_pages = poh.initNode("total-pages",1,"INT");
    page_texture = poh.initNode("page-texture","page0.png","STRING");
});


var flip_page = func(dir) {
    if(enabled.getValue()){
        var pg = page_num.getValue();
        var ttl = total_pages.getValue();
        pg +=dir;
        if(pg >= ttl) pg -= 1;
        if(pg< 0 ) pg = 0;
        page_num.setValue(pg);
        var newtex = "page"~pg~".png";
        page_texture.setValue(newtex);
    }
}
