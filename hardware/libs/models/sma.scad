// Generic model of an end-launch SMA jack.
// Current parameters tuned to match digikey 'CON-SMA-EDGE-S-ND'

include <threads.scad>

// Flanges which are soldered to the PCB
top_flange_height    = 1.02;
flange_width         = 0.81;
flange_pcb_gap       = 1.73;
bottom_flange_height = 1.07;

// Endplate between flanges and jack
endplate_width       = 6.35;
endplate_height      = 6.35;
endplate_thickness   = 1.65;

// Pin which is soldered to the PCB
pin_radius           = 0.76/2;
fpin_radius          = 1/2;

// The jack itself
jack_length          = 7.87;
jack_rteflon         = 4.3/2;
jack_rsmall          = 5/2;
jack_innerdepth      = 2.0;
jack_threadlen       = 4.0;
jack_threadstart     = endplate_thickness+1.4;

// Length of the whole assembly - end of jack to end of flanges.
assembly_length      = 13.33;

// Everything below is generated based on the above.
flange_length        = assembly_length-jack_length-endplate_thickness;

echo("Calculated flange length:", flange_length);

module flange_top()
    linear_extrude(height=top_flange_height, scale=1)
        square([flange_length, flange_width], center=true);

flange_cy = (endplate_width-flange_width)/2;

module flange_bottom()
    linear_extrude(height=bottom_flange_height, scale=1)
        square([flange_length, flange_width], center=true);

bottom_flange_z = -(bottom_flange_height+flange_pcb_gap);

module pin()
    rotate([0, 90, 0])
      cylinder($fn=25, h=flange_length, r=pin_radius, center=true);


module endplate()
    difference() {
        linear_extrude(height=endplate_height, scale=1)
            square([endplate_thickness, endplate_width], center=true);
        translate([0, 0, endplate_height/2])
            rotate([0, 90, 0])
                cylinder($fn=25, h=100, r=jack_rteflon, center=true);
    }

jack_start = -endplate_thickness-jack_length;
    
module thread()
    rotate([0, 90, 0])
    difference() {
        translate([0, 0, -jack_threadstart])
            english_thread(0.25, 36, 4.5/25.4, leadin=2, groove=false);
        cylinder($fn=25, h=100, r=jack_rteflon, center=true);
    }


module jack()
    rotate([0, 90, 0])
        difference() {
            cylinder($fn=25, h=jack_length, r=jack_rsmall, center=true);
            cylinder($fn=25, h=100, r=jack_rteflon, center=true);
        }


teflon_len = endplate_thickness + jack_length - jack_innerdepth;

module teflon()
    color("white")
        difference() {
            rotate([0, 90, 0])
                cylinder($fn=25, h=teflon_len, r=jack_rteflon, center=true);
            rotate([0, 90, 0])
                cylinder($fn=25, h=100, r=fpin_radius, center=true);
        }

        
module fpin()
    difference() {
        rotate([0, 90, 0])
            cylinder($fn=25, h=teflon_len, r=fpin_radius, center=true);
        rotate([0, 90, 0])
            cylinder($fn=25, h=100, r=0.7*fpin_radius, center=true);
    }

union() {
    translate([flange_length/2, flange_cy, 0]) flange_top();
    translate([flange_length/2, -flange_cy, 0]) flange_top();
    translate([flange_length/2, flange_cy, bottom_flange_z]) flange_bottom();
    translate([flange_length/2, -flange_cy, bottom_flange_z]) flange_bottom();
    translate([flange_length/2, 0, bottom_flange_z+endplate_height/2]) pin();
    translate([-endplate_thickness/2, 0, bottom_flange_z]) endplate();
    translate([jack_start+jack_length/2, 0, bottom_flange_z+endplate_height/2]) thread();
    translate([jack_start+jack_length/2, 0, bottom_flange_z+endplate_height/2]) jack();
    translate([-teflon_len/2, 0, bottom_flange_z+endplate_height/2]) teflon();
    translate([-teflon_len/2, 0, bottom_flange_z+endplate_height/2]) fpin();
};