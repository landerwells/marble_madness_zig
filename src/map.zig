// Here is where I want to start working on the map

const sokol = @import("sokol");
const sg = sokol.gfx;

const Map = @This();

// Lets just say for now that the map is 10 items wide, 15 items tall

// This is an abstraction for getting tiles placed in a level,
// I essentially want to be able to put things in a map, and then the vertex buffer gets
// filled automatically with the information it needs.

img: sg.Image = .{},
