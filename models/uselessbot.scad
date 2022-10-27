// geodesic sphere from https://www.thingiverse.com/thing:1484333
use <geodesic_sphere.scad>;
$fn=64;
clearance = 0.6; // part clearance to add for 3d printing
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
    if (size=="M1") {
        bolt(1, length, 3.8, 2, clearance);
    } else if (size=="M1.6") {
        bolt(1.6, length, 3.8, 2, clearance);
    } else if (size=="M2") {
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

module mainboard(breadboard_size, clearance=0.0, cut_depth=0.0) {
    c = clearance;
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
        10.0+c,
        48.0+c
    ];
    power_channel_offset = [
        (pack_size[0] - power_channel_size[0]) / 2,
        -10.0-c,
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
            translate([0, 0, r]) metric_bolt("M4", 10, clearance);
            rotate([180, 0, 0]) translate([0, 0, r]) metric_bolt("M4", 10, clearance);
        }
        difference() {
            hull() {
                translate(bracket_offset) cube(bracket_size);
                translate([bracket_offset[0], 0, bracket_offset[2]]) cylinder(h=bracket_size[2], r=bracket_size[1]/2);
            }
            //bearings
            translate([0, 0, bracket_size[2]/2]) mirror([0, 0, 1]) bearing(total_height=4+clearance, clearance=clearance/2);
            translate([-r, 0, -bracket_size[2]/2]) bearing(clearance=clearance/2);
        }
    }
}

module slug(h, r1, r2, p1, p2) {
    hull() {
        translate(p1) cylinder(h=h, r=r1, center=true);
        translate(p2) cylinder(h=h, r=r2, center=true);
    }
}

module lr_linkage(ipd, eye_radius, wall_thickness=1.6, clearance=0.0) {
    nut_h=3;
    nut_r=4;
    slug_h = nut_h/2+wall_thickness;
    slug_r = nut_r+(wall_thickness+clearance)/2;
    linkage_nut_r = 2.3; //measured
    linkage_nut_h = 4; //two nuts
    points = [
        [0, 0, 0],
        [ipd/4, 1.25*eye_radius, 0],
        [ipd/2, 1.5*eye_radius+3.5, 0], //3.5 here is the same offset used in the ud_linkage for servo motor positioning.  we're putting the center of the servo at eye_radius from the linkage arm because it seems like a good idea to avoid stretching the push rod.
        [3*ipd/4, 1.25*eye_radius, 0],
        [ipd, 0, 0]
    ];
    slug_radii = [slug_r, slug_r/2, linkage_nut_r+wall_thickness/2+clearance/2, slug_r/2, slug_r];
    difference() {
        union() {
            for (i=[0:len(points)-2]) {
                slug(h=slug_h, r1=slug_radii[i], r2=slug_radii[i+1], p1=points[i], p2=points[i+1]);
            }
        }
        for (x=[0, ipd]) {
            translate([x, 0, nut_h/2]) {
                nut(r=nut_r, h=nut_h, clearance=clearance);
                translate([0, 0, -ipd/2]) metric_bolt("M4", ipd, clearance=clearance/2);
            }
        }
        translate(points[2]+[0, 0, slug_h/3]) nut(r=linkage_nut_r, h=linkage_nut_h-clearance,clearance=clearance/2);
        translate(points[2]+[0, 0, -ipd/2]) metric_bolt("M1.6", ipd, clearance=clearance/2);
    }
}

module rounded_plate(size, r) {
    hull() for (ix=[-size[0]/2+r,size[0]/2-r], iy=[-size[1]/2+r,size[1]/2-r]) translate([ix,iy,0]) cylinder(h=size[2], r=r, center=true);
}

module pill(r, p1, p2) {
    hull() for (p=[p1,p2]) translate(p) geodesic_sphere(r);
}

module ud_linkage(eye_radius, ipd, wall_thickness=1.6, clearance=0.0) {
    nut_h=3;
    nut_r=4;
    slug_h = nut_h/2+wall_thickness;
    slug_r = nut_r+(wall_thickness+clearance)/2;
    linkage_nut_r = 2.3; //measured
    linkage_nut_h = 4; //two nuts
    z_offset = 4+clearance;
    segment_length = ipd/6;
    servo_frame_size = [32+wall_thickness,12+clearance+wall_thickness*2,6];
    servo_frame_offset = [0, 0, 1.45];
    servo_body_size = [23+clearance, 12+clearance, 40+clearance];
    points = [
        [0, 0, z_offset],
        [-2*eye_radius/3, 0, z_offset],
        [-0.75*eye_radius, 0, z_offset+segment_length],
        [-1.5*eye_radius, -segment_length, z_offset+segment_length],
        [-1.5*eye_radius, -2*segment_length, 0],
        [-1.5*eye_radius+3.5, -3*segment_length, 0], //center
        [-1.5*eye_radius, -4*segment_length, 0],
        [-1.5*eye_radius, -5*segment_length, z_offset+segment_length],
        [-0.75*eye_radius, -6*segment_length, z_offset+segment_length],
        [-2*eye_radius/3, -6*segment_length, z_offset],
        [0, -6*segment_length, z_offset]
    ];
    rotations = [
        [0, 0, 0],
        [0, 0, 0],
        [0, 0, 45],
        [0, 0, 90],
        [0, 0, 90],
        [0, 0, 90],
        [0, 0, 90],
        [0, 0, 90],
        [0, 0, -45],
        [0, 0, 0],
        [0, 0, 0],
    ];
    slim_size = [wall_thickness, slug_r ,slug_h];
    hole_offset = [(servo_body_size[0]-clearance)/2+2.65, 0, 0];
    linkage_nut_offset = points[7] + [-slug_r-nut_r, -4, -slug_r/2];
    difference() {
        union() {
            hull() {
                translate(points[0]) cylinder(h=slug_h, r=slug_r, center=true);
                translate(points[1]) cube(slim_size, center=true);
            }
            for (i=[1:8]) hull() {
                translate(points[i]) rotate(rotations[i]) cube(slim_size, center=true);
                translate(points[i+1]) rotate(rotations[i+1]) cube(slim_size, center=true);
            }
            hull() {
                translate(points[10]) cylinder(h=slug_h, r=slug_r, center=true);
                translate(points[9]) cube(slim_size, center=true);
            }
            //servo frame body
            translate(points[5]+servo_frame_offset) rounded_plate(servo_frame_size, wall_thickness*2+clearance);
            //bearing holder
            translate([0, -ipd/2-clearance, 0]) rotate([90, 0, 0]) cylinder(h=4.0, r=5.25+wall_thickness+clearance/2);
            //linkage holder
            hull() {
                translate(linkage_nut_offset) rotate([-90,0,0]) cylinder(h=wall_thickness+linkage_nut_h/4, r=linkage_nut_r+wall_thickness);
                translate(points[7]) rotate(rotations[7]) cube(slim_size, center=true);
            }
        }
        translate(points[5]) cube(servo_body_size, center=true);
        translate(points[5]+hole_offset) cylinder(h=10, r=1.05,center=true);
        translate(points[5]-hole_offset) cylinder(h=10, r=1.05,center=true);
        //nuts
        translate(points[0]-[0,0,nut_h/2]) nut(r=nut_r, h=nut_h, clearance=clearance);
        translate(points[10]-[0,0,nut_h/2]) nut(r=nut_r, h=nut_h, clearance=clearance);
        //bolts
        translate(points[0]) metric_bolt("M4", 10, clearance=clearance/2);
        translate(points[10]) metric_bolt("M4", 10, clearance=clearance/2);
        // bearing
    translate([0, -ipd/2-clearance-4, 0]) rotate([-90, 0, 0]) bearing(clearance=clearance/2);
        //linkage nut
        translate(linkage_nut_offset) rotate([90, 0, 0]) nut(r=linkage_nut_r, h=linkage_nut_h-clearance, clearance=clearance);
        translate(linkage_nut_offset+[0,nut_h,0]) rotate([90, 0, 0]) metric_bolt("M1.6", 10, clearance=clearance);
    }
    // lr_servo
    //color("#ff0000") translate([-eye_radius, -ipd/2, -3-wall_thickness*2]) rotate([0, 180, 0]) servo();
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
    translate([-eye_radius, -ipd, -bearing_height]) rotate([0, 0, 90]) lr_linkage(ipd, eye_radius, clearance=c);
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

pack_height = 24.4;
pack_offset = -30;
breadboard_size = [56+clearance, 84+clearance, 17+clearance];
printer_offset = [52, 0, -2.5];
mainboard_offset = [-22, 0, pack_offset+pack_height/2];
electronics_offset = [0, 0, pack_offset];
electronics_rotation = [0, 15, 0];
shell_radius = 75;
wall_thickness = 2.6;

eye_angle = 55;
eye_radius = 36/2;
eye_distance = shell_radius-wall_thickness*2-clearance-5.5; //2 for half bearing radius
ipd = eye_radius*2+clearance*2+18+3;//18 is for the M4x14 bolt length (include head), 3 is for the final nut to make assembly possible

part = "top";

module assembly(clearance, cut_depth=0.0) {
    color("#4080ff") translate(printer_offset) thermal_printer(clearance);
    rotate(electronics_rotation) {
        color("#ff0000") translate(mainboard_offset) mainboard(breadboard_size, clearance, cut_depth);
        color("#ffff00") translate(electronics_offset) battery_pack(clearance, cut_depth);
    }
}

if (part == "top") {
    socket_radius = 36/2+clearance;
    difference() {
        union() {
            shell(shell_radius, wall_thickness);
            //eye bulbs
            for (y=[-ipd/2, ipd/2]) {
                eye_coords = [eye_distance*cos(eye_angle), y, eye_distance*sin(eye_angle)];
                difference() {
                    pill(socket_radius+wall_thickness, eye_coords, [0, eye_coords[1], eye_coords[2]-(socket_radius+wall_thickness)/2]);
                    //translate(eye_coords) geodesic_sphere(socket_radius+wall_thickness);
                    translate(eye_coords+[socket_radius+wall_thickness+4.0,0,0]) cube((socket_radius+wall_thickness)*2, center=true);
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
        // eye sockets
        for (y=[-ipd/2, ipd/2]) {
            eye_coords = [eye_distance*cos(eye_angle), y, eye_distance*sin(eye_angle)];
            pill(socket_radius, eye_coords, [0, eye_coords[1], eye_coords[2]-socket_radius/2]);
            //translate([eye_distance*cos(eye_angle), y, eye_distance*sin(eye_angle)]) geodesic_sphere(socket_radius);
        }
    }
    // ud_servo
    color("#ff0000") translate([-10, ipd/2, 30]) rotate([90, 0, 0]) servo();
    //eyes
    color("#ff0000") translate([eye_distance*cos(eye_angle), -ipd/2, eye_distance*sin(eye_angle)]) rotate([180, 0, 0]) eyes(ipd, clearance=clearance);
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
