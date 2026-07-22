const std = @import("std");

const sokol = @import("sokol");
const sapp = sokol.app;
const sg = sokol.gfx;
const sglue = sokol.glue;
const sfetch = sokol.fetch;
const slog = sokol.log;
const zmath = @import("zmath");

const asset = @import("asset.zig");
const Camera = @import("camera.zig");
const Input = @import("input.zig");
const Marble = @import("marble.zig");
const Renderer = @import("renderer.zig");
const Sprite = @import("sprite.zig");
const TileMap = @import("tile_map.zig");
const utils = @import("utils.zig");

const App = @This();

const INTERNAL_WIDTH = 320;
const INTERNAL_HEIGHT = 240;
const SPRITE_SIZE = 32;

io: std.Io,
arena: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator),

renderer: Renderer = .{},

camera: Camera = .{},
input: Input = .{},
marble: Marble = .{},
tile_map: TileMap = .{},

pub fn init(user_data: ?*anyopaque) callconv(.c) void {
    const app: *App = @ptrCast(@alignCast(user_data));

    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });

    const allocator = app.arena.allocator();

    const tile_img = asset.loadImage(
        app.io,
        allocator,
        "assets/tileset.png",
    ) catch |err| {
        std.log.err("failed to load image: {}", .{err});
        sapp.requestQuit();
        return;
    };

    const marble_img = asset.loadImage(
        app.io,
        allocator,
        "assets/misc.png",
    ) catch |err| {
        std.log.err("failed to load image: {}", .{err});
        sapp.requestQuit();
        return;
    };

    const marble_texture = allocator.create(Sprite.Texture) catch |err| {
        std.log.err("failed to allocate marble_texture: {}", .{err});
        sapp.requestQuit();
        return;
    };

    marble_texture.* = .{
        .view = sg.makeView(.{
            .texture = .{
                .image = marble_img,
            },
        }),
    };

    app.marble.sprite.texture = marble_texture;

    const tile_texture = allocator.create(Sprite.Texture) catch |err| {
        std.log.err("failed to allocate marble_texture: {}", .{err});
        sapp.requestQuit();
        return;
    };

    tile_texture.* = .{
        .view = sg.makeView(.{
            .texture = .{
                .image = tile_img,
            },
        }),
    };

    app.tile_map.sprite.texture = tile_texture;

    app.renderer.init();
}

pub fn deinit(user_data: ?*anyopaque) callconv(.c) void {
    const app: *App = @ptrCast(@alignCast(user_data));

    app.arena.deinit();
    sg.shutdown();
}

// TODO: Set up state and lerp across values
var delta_time: f32 = 0.01;
var time: f32 = 0.0;
var accumulator: f32 = 0.0;

pub fn frame(user_data: ?*anyopaque) callconv(.c) void {
    const app: *App = @ptrCast(@alignCast(user_data));

    var frame_time: f32 = @as(f32, @floatCast(sapp.frameDuration()));
    if (frame_time > 0.25) {
        frame_time = 0.25;
    }

    accumulator += frame_time;

    while (accumulator >= delta_time) {
        app.marble.update(&app.input, &app.tile_map, delta_time);
        app.camera.update(&app.input, delta_time);

        accumulator -= delta_time;
        time += delta_time;
    }

    sg.beginPass(.{ .swapchain = sglue.swapchain() });
    sg.applyPipeline(app.renderer.pip);

    const view = zmath.matToArr(app.camera.view());
    const projection = zmath.matToArr(zmath.orthographicLhGl(
        app.camera.screen_x,
        app.camera.screen_y,
        -1.0,
        1.0,
    ));

    // Uhhh, technically the marble is supposed to be like 20 tiles high
    // std.debug.print("{any}\n", .{app.marble.position});

    const num = utils.windowToWorld(app.input.mouse_x, app.input.mouse_y);
    std.debug.print("{any}\n", .{num});

    for (0..app.tile_map.tiles.len) |z| {
        for (0..app.tile_map.tiles[0].len) |y| {
            for (0..app.tile_map.tiles[0][0].len) |x| {
                var tint: [3]f32 = .{ 1.0, 1.0, 1.0 };
                const position = TileMap.tileToWorld(
                    app.tile_map.tiles.len - x,
                    app.tile_map.tiles.len - y,
                    app.tile_map.tiles.len - z,
                );
                // Looks like this is doing the wrong thing pretty much.
                // I need to rectify my usage of floats, usizes, and everything else. Its all getting jumbled at this point.
                if (@as(i32, @intFromFloat(@floor(app.marble.position[0] * 2))) == x and @as(i32, @intFromFloat(@floor(app.marble.position[1] * 2))) == y) {
                    tint = .{ 1.0, 1.0, 0.0 };
                }
                app.renderer.draw(
                    view,
                    projection,
                    tint,
                    &app.tile_map.sprite,
                    position,
                    app.tile_map.size,
                );
            }
        }
    }

    app.renderer.draw(
        view,
        projection,
        .{ 1.0, 1.0, 1.0 },
        &app.marble.sprite,
        TileMap.tileToWorldFloat(
            app.marble.position[0],
            app.marble.position[1],
            app.marble.position[2],
        ),
        app.marble.size,
    );

    sg.endPass();
    sg.commit();

    app.input.frameEnd();
}

pub fn event(ev: ?*const sapp.Event, user_data: ?*anyopaque) callconv(.c) void {
    const app: *App = @ptrCast(@alignCast(user_data));
    const e: *const sapp.Event = ev.?;

    app.input.eventHanlder(e);
}
