const Input = @import("input.zig");

const Camera = @This();

const zmath = @import("zmath");

position: [2]f32 = .{ 0.0, 0.0 },
velocity: [2]f32 = .{ 0.0, 0.0 },
// Not sure if we should try and keep this in pixels, or general
// sprite units?
screen_x: f32 = 8.0,
screen_y: f32 = 6.0,

pub fn update(self: *Camera, input: *Input, dt: f32) void {
    if (input.left) {
        self.position[0] -= 0.1 * dt;
    } else if (input.right) {
        self.position[0] += 0.1 * dt;
    }
}

pub fn view(_: *Camera) zmath.Mat {
    return zmath.identity();
}
