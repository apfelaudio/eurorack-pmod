include <threads.scad>

body_height = 6.30;
body_width  = 11.50;
body_depth  = 14.20;

jack_center_to_body_rhs = 5.5;

jack_diameter = 6.0;
jack_length = 3.5;

pin_depth = 3.0;

plastic_top_height = 1.5;

module body()
    
    union() {
        color([0.1, 0.1, 0.1])
        linear_extrude(height=body_height-plastic_top_height, scale=1)
            square([body_width, body_depth]);
        color([0.3, 0.3, 0.3])
        translate([0,0,body_height-plastic_top_height])
            linear_extrude(height=plastic_top_height, scale=1)
                square([body_width, body_depth]);
    }
        
module thread()
    color("gray")
    rotate([0, 90, 90])
    difference() {
        //metric_thread(diameter=jack_diameter, pitch=0.5, length=jack_length, leadin=3);
        cylinder(h=jack_length, r=jack_diameter/2, $fn=20);
        translate([0,0,-0.1]) cylinder(h=jack_length*1.2, r=0.8*jack_diameter/2, $fn=20);
    }

module pin(x, y, fat, thin, angle)
    color("gray")
    translate([x,y,-pin_depth/2])
    rotate([0,0,angle])
    cube([fat, thin, pin_depth], center=true);
    
module thermal_stud(x, y)
    color("black")
    translate([x,y,0.2])
    cylinder(h=body_height, r=1);

union() {
    translate([-body_width+jack_center_to_body_rhs, 0, 0]) body();
    translate([0, -jack_length, body_height/2]) thread();
    pin(0.0, 1.7, 1.5, 0.8, 0);    //1
    pin(-5.2, 9.61, 1.5, 0.5, 90); //2
    pin(-2.6, 8.61, 1.5, 0.8, 90); //3
    pin(4.1, 13.0, 1.5, 0.8, 0);   //4
    pin(4.6, 1.7+4.2, 1.5, 0.5, 90); //5
    thermal_stud(4, 1.7);
    thermal_stud(-4, 1.7);
    thermal_stud(0, 12);
}