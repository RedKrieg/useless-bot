// geodesic sphere from https://www.thingiverse.com/thing:1484333
use <geodesic_sphere.scad>;
$fn=64;
clearance = 0.8; // part clearance to add for 3d printing
delta = 0.001; // used for cutouts to prevent weird stuff with parallel planes

// this is for a bearing cutout, no need to render inner diameter
module bearing(id=4, od=9, lip_od=10.3, lip_height=1, total_height=4, clearance=0.0) {
    union() {
        cylinder(h=lip_height+clearance, d=lip_od+clearance);
        cylinder(h=total_height+clearance, d=od+clearance);
    }
}

module bolt(diameter, length, head_diameter, head_length, clearance=0.0) {
    translate([0, 0, -head_length-clearance]) union() {
        cylinder(h=head_length+clearance, r=(head_diameter+clearance)/2);
        cylinder(h=length+head_length+clearance, r=(diameter+clearance)/2);
    }
}

module nut(r, h, clearance=0.0) {
    cylinder(h=h+clearance, r=r+clearance/2, center=true, $fn=6);
}

module metric_bolt(size, length, clearance=0.0) {
    if (size=="M2") {
        bolt(2, length, 3.8, 2, clearance);
    } else if (size=="M2.5") {
        bolt(2.5, length, 4.5, 2.45, clearance);
    } else if (size=="M3") {
        bolt(3, length, 5.5, 3, clearance);
    } else if (size=="M4") {
        bolt(4, length, 7, 4, clearance);
    } else if (size=="M5") {
        bolt(5, length, 8.5, 5, clearance);
    }
}

module thermal_printer(clearance) {
    c = clearance;
    lower_base_size = [71.2+c, 44.6+c, 23.8+c];
    upper_base_size = [71.2+c, 35.2+c, 35.8+c];
    electronics_size = [22.2+c, 23.8+c, 60.0+c];
    electronics_offset = [15.3-c/2, 9.8-c/2, 0];
    bracket_size = [78.7+c, 39.4+c, 1.6+c];
    bracket_offset = [
        -(bracket_size[0]-lower_base_size[0])/2,
        0,
        -bracket_size[2]
    ];
    feeder_face_size = [70.9+c, 43.2+c, 8.4+c];
    //feeder_face_size = [70.9+c, 43.2+c, 30+c];
    feeder_face_offset = [
        (lower_base_size[0]-feeder_face_size[0])/2,
        lower_base_size[1]-feeder_face_size[1],
        -feeder_face_size[2]
    ];
    center_offset = [
        -lower_base_size[0]/2,
        -lower_base_size[1]/2,
        0
    ];
    rotate([-90, 0, -90]) translate(center_offset) mirror([0, 0, 1]) union() {
        cube(lower_base_size);
        cube(upper_base_size);
        translate(electronics_offset) cube(electronics_size);
        translate(bracket_offset) cube(bracket_size);
        translate(feeder_face_offset) cube(feeder_face_size);
    }
}

module mainboard(clearance, cut_depth=0.0) {
    c = clearance;
    breadboard_size = [56+c, 84+c, 17+c];
    wiring_size = [50+c, 31+c, 44+c];
    wiring_offset = [3.2, 35.4, 0];
    power_plug_center_x = 61.5;
    power_plug_center_z = 14.8;
    center_offset = [
        -breadboard_size[0]/2,
        -breadboard_size[1]/2,
        0
    ];
    translate(center_offset) union() {
        if (cut_depth>0.0) {
            cube([breadboard_size[0], breadboard_size[1], cut_depth]);
        } else {
            cube(breadboard_size);
            translate(wiring_offset) cube(wiring_size);
        }
    }
}

module battery_pack(clearance, cut_depth=0.0) {
    c = clearance;
    pack_size = [60.0+c, 87.4+c, 24.4+cut_depth+c];
    power_channel_size = [
        pack_size[0] - 20.0 * 2,
        50.0+c,
        48.0+c
    ];
    power_channel_offset = [
        (pack_size[0] - power_channel_size[0]) / 2,
        -10.0,
        8.0
    ];
    center_offset = [-pack_size[0]/2, -pack_size[1]/2, -(pack_size[2]-cut_depth)/2];
    translate(center_offset) union() {
        cube(pack_size);
        translate(power_channel_offset) cube(power_channel_size);
    }
    
}

module flat_sphere(r, h) {
    difference() {
        geodesic_sphere(r);
        translate([h, -r, -r]) cube(r*2);
    }
}

module eye(r, flat_r, back_cut_angle, wall_thickness, bolt_diameter, clearance) {
    flat_height = sqrt(r*r-flat_r*flat_r);
    back_cut_depth = r * cos(back_cut_angle);
    bracket_size = [r+flat_height, 14, 4]; //y and z to fit bearing
    bracket_offset = [-r, -bracket_size[1]/2, -bracket_size[2]/2];
    union() {
        difference() {
            flat_sphere(r, flat_height);
            flat_sphere(r-wall_thickness, flat_height-wall_thickness);
            translate([-r*2-back_cut_depth, -r, -r]) cube(r*2);
            translate([0, 0, r]) metric_bolt("M4", 10);
        }
        difference() {
            hull() {
                translate(bracket_offset) cube(bracket_size);
                translate([bracket_offset[0], 0, bracket_offset[2]]) cylinder(h=bracket_size[2], r=bracket_size[1]/2);
            }
            translate([0,0,bracket_size[2]/2]) mirror([0, 0, 1]) bearing(total_height=4+clearance, clearance=clearance/2);
           translate([-r,0,bracket_size[2]/2]) mirror([0, 0, 1]) bearing(clearance=clearance/2);
        }
    }
}

module slug(h, r, p1, p2) {
    hull() {
        translate(p1) cylinder(h=h, r=r, center=true);
        translate(p2) cylinder(h=h, r=r, center=true);
    }
}

module lr_linkage(ipd, wall_thickness=1.6, clearance=0.0) {
    nut_h=3;
    nut_r=4;
    slug_h = nut_h/2+wall_thickness;
    slug_r = nut_r+(wall_thickness+clearance)/2;
    linkage_nut_r = 2.3; //measured
    linkage_nut_h = 4; //two nuts
    points = [
        [0, 0, 0],
        [ipd/4, ipd/2, 0],
        [3*ipd/4, ipd/2, 0],
        [ipd, 0, 0]
    ];
    difference() {
        union() {
            for (i=[0:len(points)-2]) {
                slug(h=slug_h, r=slug_r, p1=points[i], p2=points[i+1]);
            }
        }
        for (x=[0, ipd]) {
            translate([x, 0, nut_h/2]) {
                nut(r=nut_r, h=nut_h, clearance=clearance);
                translate([0, 0, -ipd/2]) metric_bolt("M4", ipd, clearance=clearance/2);
            }
        }
        translate([ipd/2, ipd/2, slug_h/3]) nut(r=linkage_nut_r, h=linkage_nut_h,clearance=clearance/2);
        translate([ipd/2, ipd/2, -ipd/2]) metric_bolt("M2", ipd, clearance=clearance/2);
    }
}

module rounded_plate(x, y, r) {
    translate([-x/2, -y/2, 0]) hull() for (ix=[0,x], iy=[0,y]) geodesic_sphere(r);
}

module pill(r, p1, p2) {
    hull() for (p=[p1,p2]) translate(p) geodesic_sphere(r, $fn=$fn/4);
}

module ud_linkage(eye_radius, ipd, wall_thickness=1.6, clearance=0.0) {
    z_offset = 4+clearance;
    segment_length = ipd/6;
    points = [
        [0, 0, z_offset],
        [-2*eye_radius/3, 0, z_offset],
        [-eye_radius, 0, z_offset+segment_length],
        [-eye_radius, -segment_length, z_offset+segment_length],
        [-eye_radius, -2*segment_length, z_offset+segment_length],
        [-eye_radius, -3*segment_length, 0], //center
        [-eye_radius, -4*segment_length, z_offset+segment_length],
        [-eye_radius, -5*segment_length, z_offset+segment_length],
        [-eye_radius, -6*segment_length, z_offset+segment_length],
        [-2*eye_radius/3, -6*segment_length, z_offset],
        [0, -6*segment_length, z_offset]
    ];
    for (i=[0:len(points)-2]) pill(2, points[i], points[i+1]);
    translate([0, -ipd/2-clearance, 0]) rotate([90, 0, 0]) bearing(clearance=clearance/2);
    translate([-eye_radius, -ipd/2, -3-wall_thickness*2]) rotate([0, 180, 0]) servo();
}

module eyes(ipd, eye_radius=36/2, clearance) {
    c = clearance;
    googly_radius = 25.4/2;
    wall_thickness = 1.6;
    back_cut_angle = 60;
    bolt_diameter = 4+c;
    bearing_height = 4+c;
    for (y=[0, ipd]) {
        translate([0, -y, 0]) eye(eye_radius, googly_radius, back_cut_angle, wall_thickness, bolt_diameter, c);
    }
    translate([-eye_radius, -ipd, -bearing_height]) rotate([0, 0, 90]) lr_linkage(ipd, clearance=c);
    ud_linkage(eye_radius, ipd, clearance=clearance);
}

module servo() {
    //set origin to center of output shaft's base
    translate([4.5, -14.5, -25.3]) import("sg90.stl");
}

module shell(radius, wall_thickness) {
    difference() {
        geodesic_sphere(radius);
        difference() {
            geodesic_sphere(radius-wall_thickness);
            translate([
                0,
                -radius,
                -radius
            ]) cube(radius*2);
            translate([
                -radius,
                -radius,
                -radius*2-35 //mainboard offset
            ]) cube(radius*2);
        }
    }
}

module upper_shell(radius, wall_thickness, ipd) {
}

//cube(wiring_size);
pack_height = 24.4;
pack_offset = -30;
//metric_bolt("M4", 20, clearance);
//bearing(clearance=clearance);
printer_offset = [52, 0, -2.5];
mainboard_offset = [-22, 0, pack_offset+pack_height/2];
electronics_offset = [0, 0, pack_offset];
electronics_rotation = [0, 15, 0];
shell_radius = 71;
wall_thickness = 2.6;
ipd = 2*shell_radius/3;
eye_angle = 50;
eye_radius = 36/2;
eye_distance = shell_radius-wall_thickness-clearance-5.5; //2 for half bearing radius

part = "top";

module assembly(clearance, cut_depth=0.0) {
    color("#4080ff") translate(printer_offset) thermal_printer(clearance);
    rotate(electronics_rotation) {
        color("#ff0000") translate(mainboard_offset) mainboard(clearance, cut_depth);
        color("#ffff00") translate(electronics_offset) battery_pack(clearance, cut_depth);
    }
}

if (part == "top") {
    socket_radius = 36/2+clearance;
    difference() {
        union() {
            shell(shell_radius, wall_thickness);
            for (y=[-ipd/2, ipd/2]) {
                difference() {
                    translate([eye_distance*cos(eye_angle), y, eye_distance*sin(eye_angle)]) geodesic_sphere(socket_radius+wall_thickness);
                    translate([eye_distance*cos(eye_angle)+socket_radius+wall_thickness, y, eye_distance*sin(eye_angle)]) cube((socket_radius+wall_thickness)*2, center=true);
                }
            }
        }
        assembly(clearance=clearance, cut_depth=0.0);
        translate([printer_offset[0]+5.3, -shell_radius, -shell_radius]) cube(shell_radius*2);
        //translate([-shell_radius, -shell_radius, 0]) cube(shell_radius*2);
        translate([-shell_radius, -shell_radius, -shell_radius*2]) cube(shell_radius*2);
        difference() {
            geodesic_sphere(shell_radius-wall_thickness);
            translate([printer_offset[0]-wall_thickness, -shell_radius, -shell_radius]) cube(shell_radius*2);
        }
        for (y=[-ipd/2, ipd/2]) {
            translate([eye_distance*cos(eye_angle), y, eye_distance*sin(eye_angle)]) geodesic_sphere(socket_radius);
        }
    }
} else if (part == "bottom") {
    difference() {
        shell(shell_radius, wall_thickness);
        assembly(clearance=clearance, cut_depth=4);
        translate([printer_offset[0]+5.3, -shell_radius, -shell_radius]) cube(shell_radius*2);
        translate([-shell_radius, -shell_radius, 0]) cube(shell_radius*2);
        //translate([-shell_radius, -shell_radius, -shell_radius*2]) cube(shell_radius*2);
    }
} else if (part == "guts") {
    intersection() {
        geodesic_sphere(shell_radius);
        assembly(clearance=clearance);
    }
} else if (part == "eyes") {
    eyes(ipd, eye_radius=eye_radius, clearance=clearance);
}
//color("#4080ff") translate(printer_offset) thermal_printer(clearance);
//translate([shell_radius-30, ipd/2, 2*shell_radius/3]) mirror([0,0,1]) eyes(ipd, clearance=clearance);
translate([eye_distance*cos(eye_angle), ipd/2, eye_distance*sin(eye_angle)]) mirror([0,0,1]) eyes(ipd, clearance=clearance);