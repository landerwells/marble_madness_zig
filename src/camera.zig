const Input = @import("input.zig");

const Camera = @This();

const zmath = @import("zmath");

const std = @import("std");

position: [2]f32 = .{ 0.0, 0.0 },
velocity: [2]f32 = .{ 0.0, 0.0 },
// Not sure if we should try and keep this in pixels, or general
// sprite units?
screen_x: f32 = 8.0,
screen_y: f32 = 6.0,

pub fn update(self: *Camera, input: *Input, dt: f32) void {
    if (input.left) {
        self.position[0] -= 1.0 * dt;
    } else if (input.right) {
        self.position[0] += 1.0 * dt;
    } else if (input.up) {
        self.position[1] += 1.0 * dt;
    } else if (input.down) {
        self.position[1] -= 1.0 * dt;
    }
    std.debug.print("{any}\n", .{self.position});
}

pub fn view(self: *Camera) zmath.Mat {
    return zmath.translation(-self.position[0], -self.position[1], 0.0);
}
