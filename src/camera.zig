const std = @import("std");

const zmath = @import("zmath");

const Input = @import("input.zig");

const Camera = @This();

pub const VIEWPORT = .{ 320.0, 240.0 };

position: [2]f32 = .{ 0.0, 0.0 },
velocity: [2]f32 = .{ 0.0, 0.0 },
screen_x: f32 = 320.0,
screen_y: f32 = 240.0,

const CAMERA_SPEED = 1.0;

// Camera should be pixel aligned?
pub fn update(self: *Camera, input: *Input, dt: f32) void {
    if (input.left) self.position[0] -= CAMERA_SPEED * dt;
    if (input.right) self.position[0] += CAMERA_SPEED * dt;
    if (input.up) self.position[1] += CAMERA_SPEED * dt;
    if (input.down) self.position[1] -= CAMERA_SPEED * dt;
}

pub fn view(self: *Camera) zmath.Mat {
    return zmath.translation(-self.position[0], -self.position[1], 0.0);
}
