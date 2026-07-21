// So each level is going to consist of a tilemap, and probably some other things
// I am making this file to write down some thoughts on how I believe a level should
// be created?
//
// I could have a level generator script

// Levels need to know some things
// Time to completion
// Spawn point
// End zone

const std = @import("std");

const TileMap = @import("tile_map.zig");

const Level = @This();

tile_map: TileMap,
// I believe we are going to have to keep the marble's position in f32?
// I am not sure what makes the most sense since the marble can be in between
// two units of tiles, but tiles can only ever be grid aligned. Not sure what
// to make of that, will probably just store tiles in a grid, and then the function
// that converts from tile to world will correctly get both types.
marble_spawn: [3]f32,
