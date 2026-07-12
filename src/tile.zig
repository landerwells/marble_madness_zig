const SpriteSheet = @import("sprite_sheet.zig");

const Tile = @This();

// The type and direction will determine what kind of offset
// needs to be used
const Type = enum {
    whole,
};

pub const Direction = enum {
    ne,
    se,
    sw,
    nw,
};

size: [2]f32 = .{ 0.5, 0.5 },

// A tile is going to be a single background piece, consisting of a
// sprite, quad, and some other information. The marble will
// know what kind of tile it is on

direction: Direction,
// type: Type,

sheet: SpriteSheet = SpriteSheet{
    .texture_width = 160,
    .texture_height = 160,
    .sprite_width = 16,
    .sprite_height = 16,
},

pub fn default() Tile {
    return .{
        .direction = Tile.Direction.ne,
    };
}
