const sokol = @import("sokol");
const sg = sokol.gfx;

const SpriteSheet = @import("sprite_sheet.zig");
const Sprite = @import("sprite.zig");

const TileMap = @This();

pub const X = 20;
pub const Y = 20;
pub const Z = 20;

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

size: [2]f32 = .{ 16.0, 16.0 },
tiles: [Z][Y][X]Tile =
    [_][Y][X]Tile{[_][X]Tile{[_]Tile{Tile.default()} ** X} ** Y} ** Z,

sprite: Sprite = Sprite{
    .sheet = &SpriteSheet{
        .texture_width = 160,
        .texture_height = 160,
        .sprite_width = 16,
        .sprite_height = 16,
    },
},

pub fn init() TileMap {
    return .{};
}

// Do I even put these
pub fn tileToWorld(x: usize, y: usize, z: usize) [2]f32 {
    const fx = @as(f32, @floatFromInt(x));
    const fy = @as(f32, @floatFromInt(y));
    const fz = @as(f32, @floatFromInt(z));

    return .{
        (fx - fy) * Tile.WIDTH / 2,
        (fx + fy) * Tile.HEIGHT / 2 - fz * Tile.HEIGHT,
    };
}

pub fn tileToWorldFloat(x: f32, y: f32, z: f32) [2]f32 {
    return .{
        (x - y) * Tile.WIDTH / 2,
        (x + y) * Tile.HEIGHT / 2 - z * Tile.HEIGHT,
    };
}

//
pub fn worldToTile(
    x: f32,
    y: f32,
) [2]f32 {
    return .{
        (x - y) * Tile.WIDTH / 2,
        (x + y) * Tile.HEIGHT / 2,
    };
}

// Need to rectify pixels which are what the window is specified in
// with world space,
// with the isometric tilespace
