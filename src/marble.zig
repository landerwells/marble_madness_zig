const sokol = @import("sokol");
const sg = sokol.gfx;

const asset = @import("asset.zig");
const Input = @import("input.zig");
const Sprite = @import("sprite.zig");
const SpriteSheet = @import("sprite_sheet.zig");
const TileMap = @import("tile_map.zig");

const Marble = @This();

const MASS = 1.0;

const MOVE_ACCEL = 1.0;
const MAX_SPEED = 1.0;
const FRICTION = 2.0;
const GRAVITY = 1.0;

// Position is going to be the in game position of the marble,
// No longer the world posiiton
position: [2]f32 = .{ 0.0, 0.0 },
velocity: [2]f32 = .{ 0.0, 0.0 },
acceleration: [2]f32 = .{ 0.0, 0.0 },

size: [2]f32 = .{ 1.0, 1.0 },

sprite: Sprite = Sprite{
    .offset = .{ 1.0, 4.0 },
    .sheet = &SpriteSheet{
        .texture_width = 352,
        .texture_height = 864,
        .sprite_width = 32,
        .sprite_height = 32,
    },
},

// This function is going to handle:
// - Gravity for the marble
// - Sprite updates
// - General movement
pub fn update(self: *Marble, input: *Input, _: *TileMap, delta_time: f32) void {
    self.acceleration[0] = input.mouse_delta[0] / MASS;
    self.acceleration[1] = input.mouse_delta[1] / MASS;

    self.velocity[0] += self.acceleration[0] * delta_time;
    self.velocity[1] += self.acceleration[1] * delta_time;

    self.velocity[0] *= 1.0 - FRICTION * delta_time;
    self.velocity[1] *= 1.0 - FRICTION * delta_time;

    const speed = @sqrt(self.velocity[0] * self.velocity[0] + self.velocity[1] * self.velocity[1]);

    if (speed > MAX_SPEED) {
        self.velocity[0] = (self.velocity[0] / speed) * MAX_SPEED;
        self.velocity[1] = (self.velocity[1] / speed) * MAX_SPEED;
    }

    self.position[0] += self.velocity[0] * delta_time;
    self.position[1] += self.velocity[1] * delta_time;
}
