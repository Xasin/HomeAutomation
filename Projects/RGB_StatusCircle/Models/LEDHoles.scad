
difference() {

import("/home/xasin/Print/Print.stl");

translate([0, 0, 4.6])
for(i=[0:4]) rotate([0, 0,  45 + 90*i])
rotate([90, 0, 0])
cylinder(d = 5.15, h = 1000, $fs = 0.5); 
}