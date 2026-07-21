const std = @import("std");

const zmath = @import("zmath");

const Input = @import("input.zig");

const Camera = @This();

position: [2]f32 = .{ 0.0, 0.0 },
velocity: [2]f32 = .{ 0.0, 0.0 },
// Not sure if we should try and keep this in pixels, or general
// sprite units?
screen_x: f32 = 9.0,
screen_y: f32 = 6.0,

const CAMERA_SPEED = 1.0;

// Technically we should set up some sort of linear interpolation for the
// camera.
pub fn update(self: *Camera, input: *Input, dt: f32) void {
    if (input.left) self.position[0] -= CAMERA_SPEED * dt;
    if (input.right) self.position[0] += CAMERA_SPEED * dt;
    if (input.up) self.position[1] += CAMERA_SPEED * dt;
    if (input.down) self.position[1] -= CAMERA_SPEED * dt;
}

pub fn view(self: *Camera) zmath.Mat {
    return zmath.translation(-self.position[0], -self.position[1], 0.0);
}
