const App = @import("app.zig");

const sokol = @import("sokol");
const sapp = sokol.app;
const slog = sokol.log;

const std = @import("std");

pub fn main(init: std.process.Init) void {
    var app = App{ .io = init.io };

    sapp.run(.{
        .user_data = &app,
        .init_userdata_cb = App.init,
        .frame_userdata_cb = App.frame,
        .cleanup_userdata_cb = App.deinit,
        .event_userdata_cb = App.event,
        .width = 1080,
        .height = 920,
        .icon = .{ .sokol_default = true },
        .window_title = "Marble Madness",
        .logger = .{ .func = slog.func },
    });
}
