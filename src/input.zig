const std = @import("std");
const sokol = @import("sokol");
const sapp = sokol.app;

const Input = @This();

mouse_delta: [2]f32 = .{ 0.0, 0.0 },

left: bool = false,
right: bool = false,
up: bool = false,
down: bool = false,

pub fn eventHanlder(self: *Input, e: *const sapp.Event) void {
    switch (e.type) {
        .MOUSE_MOVE => {
            self.mouse_delta[0] += e.mouse_dx;
            self.mouse_delta[1] -= e.mouse_dy;
        },

        .MOUSE_DOWN => {
            if (e.mouse_button == .LEFT) {
                sapp.lockMouse(true);
            }
        },

        .KEY_DOWN => {
            // Not sure if this should be a switch statement?
            switch (e.key_code) {
                .ESCAPE => {
                    sapp.lockMouse(false);
                    sapp.requestQuit();
                },
                .LEFT => self.left = true,
                .RIGHT => self.right = true,
                .UP => self.up = true,
                .DOWN => self.down = true,
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
    self.left = false;
    self.right = false;
    self.up = false;
    self.down = false;
}
