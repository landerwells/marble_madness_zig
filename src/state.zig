// Here I am going to hold the global state
const input = @import("input.zig");

const sokol = @import("sokol");
const sg = sokol.gfx;
const std = @import("std");

pub var inputState: input.InputState = .{};
pub var bind: sg.Bindings = .{};
pub var pip: sg.Pipeline = .{};
pub var init: std.process.Init = .{};
