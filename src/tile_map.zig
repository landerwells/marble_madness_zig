const sokol = @import("sokol");
const sg = sokol.gfx;

const SpriteSheet = @import("sprite_sheet.zig");
const Sprite = @import("sprite.zig");

const TileMap = @This();

pub const Width = 10;
pub const Height = 15;

pub const tile_width = 1;
pub const tile_height = 1;

const Tile = struct {
    const Type = enum {
        whole,
    };

    pub const Direction = enum {
        ne,
        se,
        sw,
        nw,
    };
    direction: Direction,

    pub fn default() Tile {
        return .{
            .direction = Tile.Direction.ne,
        };
    }
};

tiles: [Height][Width]Tile = [_][Width]Tile{[_]Tile{Tile.default()} ** Width} ** Height,

sprite: Sprite = Sprite{
    .sheet = &SpriteSheet{
        .texture_width = 160,
        .texture_height = 160,
        .sprite_width = 16,
        .sprite_height = 16,
    },
},

pub fn init() TileMap {
    return .{
        .tiles = [_][Width]Tile{[_]Tile{Tile.default()} ** Width} ** Height,
    };
}

// What are even world coordinates? Do they go from -1 => 1?
pub fn tileToWorld(_: *TileMap, tile_x: usize, tile_y: usize) [2]f32 {
    // return .{
    //     @as(f32, @floatFromInt(tile_x - tile_y)) * 0.5,
    //     @as(f32, @floatFromInt(tile_x + tile_y)) * 0.5,
    // };
    return .{ @as(f32, @floatFromInt(tile_x)), @as(f32, @floatFromInt(tile_y)) };
}
