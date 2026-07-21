const std = @import("std");

const sokol = @import("sokol");
const sg = sokol.gfx;

const asset = @import("asset.zig");
const Input = @import("input.zig");
const Sprite = @import("sprite.zig");
const SpriteSheet = @import("sprite_sheet.zig");
const TileMap = @import("tile_map.zig");

const Marble = @This();

const MASS = 1.0;

const MOVE_ACCEL = 1.5;
const MAX_SPEED = 2.0;
const FRICTION = 2.0;
const GRAVITY = 1.0;

position: [3]f32 = .{ 0.0, 0.0, 0.0 },
accumulated_position: [2]f32 = .{ 0.0, 0.0 },
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
//
// TODO: Need to convert mouse movement into isometric tile movement
// TODO: Marble also needs to be displayed pixel aligned, not sure how to implement
// TODO: Even more thoughts about the marble. Technically we really care about the
// bottom center of the marble.
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

    self.accumulated_position[0] += self.velocity[0] * delta_time;
    self.accumulated_position[1] += self.velocity[1] * delta_time;

    // Sprite updates
    // std.debug.print("{any}\n", .{self.accumulated_position});
    if (self.accumulated_position[1] > 0.05) {
        const new_offset = @mod(self.sprite.offset[0] + 1, 9);
        self.sprite.offset = .{ new_offset, self.sprite.offset[1] };
        self.accumulated_position[0] = 0;
        self.accumulated_position[1] = 0;
    }

    if (self.accumulated_position[1] < -0.05) {
        const new_offset = @mod(self.sprite.offset[0] - 1, 9);
        self.sprite.offset = .{ new_offset, self.sprite.offset[1] };
        self.accumulated_position[0] = 0;
        self.accumulated_position[1] = 0;
    }
}
