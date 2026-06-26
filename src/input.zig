const std = @import("std");
const sokol = @import("sokol");
const sapp = sokol.app;

// This is a cool idiom idiom that I didn't realize was possible
const Input = @This();

mouse_delta: [2]f32 = .{ 0.0, 0.0 },

pub fn eventHanlder(self: *Input, e: *const sapp.Event) void {
    std.debug.print("{any}\n", .{self.mouse_delta});
    switch (e.type) {
        .MOUSE_MOVE => {
            // I only care about the dx and dy of the mouse, nothing else
            // This is going to be used in the physics calculations

            self.mouse_delta[0] += e.mouse_dx;
            self.mouse_delta[1] += e.mouse_dy;
        },

        .MOUSE_DOWN => {
            if (e.mouse_button == .LEFT) {
                sapp.lockMouse(true);
            }
        },

        .KEY_DOWN => {
            switch (e.key_code) {
                .ESCAPE => {
                    sapp.lockMouse(false);
                    sapp.requestQuit();
                },
                else => {},
            }
        },

        .UNFOCUSED => {
            sapp.lockMouse(false);
        },

        else => {},
    }
}

pub fn frameEnd(self: *Input) void {
    self.mouse_delta = .{ 0.0, 0.0 };
}
