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
const Tile = @import("tile.zig");

const App = @This();

const INTERNAL_WIDTH = 320;
const INTERNAL_HEIGHT = 240;
const SPRITE_SIZE = 32;

io: std.Io,
renderer: Renderer = .{},

input: Input = .{},

marble: Marble = .{},
map: Map = .{},

tile_view: sg.View = .{},
tile: Tile = .{
    .direction = Tile.Direction.ne,
},

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

    app.tile_view = sg.makeView(.{
        .texture = .{ .image = background_img },
    });

    app.marble.view = sg.makeView(.{
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

    app.renderer.drawFromSpriteSheet(app.tile_view, app.tile.sheet, app.tile.size, .{ 0.0, 0.0 }, .{ 0.0, 0.0 });
    app.renderer.drawFromSpriteSheet(app.marble.view, app.marble.sheet, app.marble.size, app.marble.position, .{ 1.0, 4.0 });

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
