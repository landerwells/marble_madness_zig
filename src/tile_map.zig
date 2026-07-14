const sokol = @import("sokol");
const sg = sokol.gfx;

const SpriteSheet = @import("sprite_sheet.zig");
const Sprite = @import("sprite.zig");

const TileMap = @This();

pub const Width = 10;
pub const Height = 15;

const Tile = struct {
    pub const WIDTH = 1.0;
    pub const HEIGHT = 0.5;

    const Type = enum {
        whole,
    };

    pub const Direction = enum {
        ne,
        se,
        sw,
        nw,
    };

    // Was thinking of a list of each item a Tile needs
    // - Color details, unless that belongs to the level
    // - x, y, z, unless that belongs to the TileMap
    // -

    // type: Type,
    // height: u8,
    direction: Direction,
    // palette: u8,

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

pub fn tileToWorld(_: *TileMap, x: f32, y: f32) [2]f32 {
    // return .{
    //     @as(f32, @floatFromInt(tile_x - tile_y)) * 0.5,
    //     @as(f32, @floatFromInt(tile_x + tile_y)) * 0.5,
    // };
    //
    return .{
        (x - y) * Tile.WIDTH / 2,
        (x + y) * Tile.HEIGHT / 2,
    };
    // return .{ @as(f32, @floatFromInt(x)), @as(f32, @floatFromInt(y)) };
}
