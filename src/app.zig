const std = @import("std");

const sokol = @import("sokol");
const zmath = @import("zmath");

const sapp = sokol.app;
const sg = sokol.gfx;
const sglue = sokol.glue;
const sfetch = sokol.fetch;
const slog = sokol.log;

const asset = @import("asset.zig");

const Input = @import("input.zig");
const Map = @import("map.zig");
const Marble = @import("marble.zig");
const Renderer = @import("renderer.zig");

const App = @This();

const INTERNAL_WIDTH = 320;
const INTERNAL_HEIGHT = 240;
const SPRITE_SIZE = 32;

io: std.Io,
renderer: Renderer = .{},

input: Input = .{},

background_view: sg.View = .{},
marble_view: sg.View = .{},

marble: Marble = .{},
map: Map = .{},

pub fn init(user_data: ?*anyopaque) callconv(.c) void {
    const app: *App = @ptrCast(@alignCast(user_data));

    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const alloc = arena.allocator();

    const background_img = asset.loadImage(
        app.io,
        alloc,
        "assets/tileset.png",
    ) catch |err| {
        std.log.err("failed to load image: {}", .{err});
        sapp.requestQuit();
        return;
    };

    const marble_img = asset.loadImage(
        app.io,
        alloc,
        "assets/misc.png",
    ) catch |err| {
        std.log.err("failed to load image: {}", .{err});
        sapp.requestQuit();
        return;
    };

    app.background_view = sg.makeView(.{
        .texture = .{ .image = background_img },
    });

    app.marble_view = sg.makeView(.{
        .texture = .{ .image = marble_img },
    });

    app.renderer.init();
}

pub fn deinit(_: ?*anyopaque) callconv(.c) void {
    sg.shutdown();
}

var time: f32 = 0.0;
var delta_time: f32 = 1.0 / 60.0;

pub fn frame(user_data: ?*anyopaque) callconv(.c) void {
    const app: *App = @ptrCast(@alignCast(user_data));

    app.marble.update(&app.input, delta_time);

    sg.beginPass(.{ .swapchain = sglue.swapchain() });
    sg.applyPipeline(app.renderer.pip);

    // So now I can render multiple sprites at a given time, I need to pass in a map
    // or something to render all of the blocks correctly
    app.renderer.draw(app.background_view, .{ 0.0, 0.0 }, .{ 0.0, 0.0 });
    app.renderer.draw(app.background_view, .{ 0.0, 0.0 }, .{ 0.0, 1.0 });
    app.renderer.draw(app.marble_view, .{ 0.0, 0.0 }, app.marble.position);

    sg.endPass();
    sg.commit();

    app.input.frameEnd();
    time += delta_time;
}

pub fn event(ev: ?*const sapp.Event, user_data: ?*anyopaque) callconv(.c) void {
    const app: *App = @ptrCast(@alignCast(user_data));
    const e: *const sapp.Event = ev.?;

    app.input.eventHanlder(e);
}
