const SpriteSheet = @import("sprite_sheet.zig");

const Tile = @This();

const Type = enum {
    whole,
};

const Direction = enum {
    ne,
    se,
    sw,
    nw,
};

// A tile is going to be a single background piece, consisting of a
// sprite, quad, and some other information. The marble will
// know what kind of tile it is on

direction: Direction,
type: Type,

const sheet = SpriteSheet{
    .texture_width = 160,
    .texture_height = 160,
    .sprite_width = 16,
    .sprite_height = 16,
};
