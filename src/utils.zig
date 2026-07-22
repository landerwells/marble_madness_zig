const Camera = @import("camera.zig");

const sokol = @import("sokol");
const sapp = sokol.app;

/// Converts pixel coordinates to world coordinates
pub fn windowToWorld(window_x: f32, window_y: f32) [2]f32 {
    const width = @as(f32, @floatFromInt(sapp.width()));
    const height = @as(f32, @floatFromInt(sapp.height()));

    return .{
        (window_x / width - 0.5) * Camera.VIEWPORT[0],
        (0.5 - window_y / height) * Camera.VIEWPORT[1],
    };
}

pub fn worldToTile() void {}

pub fn tileToWorld() void {}

pub fn windowToTile() void {}
