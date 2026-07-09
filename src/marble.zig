const SpriteSheet = @import("sprite_sheet.zig");
const Marble = @This();
const Input = @import("input.zig");
const asset = @import("asset.zig");
const sokol = @import("sokol");
const sg = sokol.gfx;

const MOVE_ACCEL = 100.0;
const MAX_SPEED = 150.0;
const FRICTION = 0.5;

position: [2]f32 = .{ 0.0, 0.0 },
velocity: [2]f32 = .{ 0.0, 0.0 },

img: sg.Image = .{},
view: sg.View = .{},

size: [2]f32 = .{ 1.0, 1.0 },

sheet: SpriteSheet = SpriteSheet{
    .texture_width = 352,
    .texture_height = 864,
    .sprite_width = 32,
    .sprite_height = 32,
},

pub fn update(self: *Marble, input: *Input, dt: f32) void {
    self.velocity[0] += input.mouse_delta[0] * dt;
    self.velocity[1] += input.mouse_delta[1] * dt;

    self.velocity[0] *= 1.0 - FRICTION * dt;
    self.velocity[1] *= 1.0 - FRICTION * dt;

    self.position[0] += self.velocity[0] * dt;
    self.position[1] += self.velocity[1] * dt;
}
