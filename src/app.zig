const std = @import("std");

const sokol = @import("sokol");
const zmath = @import("zmath");
const shd = @import("shader");

const sapp = sokol.app;
const sg = sokol.gfx;
const sglue = sokol.glue;
const sfetch = sokol.fetch;
const slog = sokol.log;

const asset = @import("asset.zig");

const Input = @import("input.zig");
const Marble = @import("marble.zig");
const Map = @import("map.zig");

const App = @This();

const Vertex = struct {
    position: [2]f32,
    color: [4]f32,
    uv: [2]f32,
};

const INTERNAL_WIDTH = 320;
const INTERNAL_HEIGHT = 240;
const SPRITE_SIZE = 32;

io: std.Io,
bind: sg.Bindings = .{},
pip: sg.Pipeline = .{},

input: Input = .{},

background_view: sg.View = .{},

marble: Marble = .{},
map: Map = .{},

pub fn init(user_data: ?*anyopaque) callconv(.c) void {
    const view: zmath.Mat = zmath.identity();
    std.debug.print("{any}", .{view});
    const app: *App = @ptrCast(@alignCast(user_data));

    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const alloc = arena.allocator();

    app.map.img = asset.loadImage(
        app.io,
        alloc,
        "assets/tileset.png",
    ) catch |err| {
        std.log.err("failed to load image: {}", .{err});
        sapp.requestQuit();
        return;
    };

    // I don't think the tile has to actuall
    app.marble.img = asset.loadImage(
        app.io,
        alloc,
        "assets/misc.png",
    ) catch |err| {
        std.log.err("failed to load image: {}", .{err});
        sapp.requestQuit();
        return;
    };

    // I guess this is going to just be a
    // const vertices1: [_][_]f32 = {};

    // Vertex buffer needs to be created programatically from the map
    const vertices = [_]Vertex{
        .{
            .position = .{ 0, 0 },
            .color = .{ 1.0, 0.0, 0.0, 1.0 },
            .uv = .{ 0.0, 0.0 },
        },
        .{
            .position = .{ SPRITE_SIZE, 0 },
            .color = .{ 0.0, 1.0, 0.0, 1.0 },
            .uv = .{ 1.0, 0.0 },
        },
        .{
            .position = .{ SPRITE_SIZE, SPRITE_SIZE },
            .color = .{ 0.0, 0.0, 1.0, 1.0 },
            .uv = .{ 1.0, 1.0 },
        },
        .{
            .position = .{ 0, SPRITE_SIZE },
            .color = .{ 1.0, 1.0, 0.0, 1.0 },
            .uv = .{ 0.0, 1.0 },
        },
        .{
            .position = .{ 0, 0 },
            .color = .{ 1.0, 0.0, 0.0, 1.0 },
            .uv = .{ 0.0, 0.0 },
        },
        .{
            .position = .{ SPRITE_SIZE, 0 },
            .color = .{ 0.0, 1.0, 0.0, 1.0 },
            .uv = .{ 1.0, 0.0 },
        },
        .{
            .position = .{ SPRITE_SIZE, SPRITE_SIZE },
            .color = .{ 0.0, SPRITE_SIZE, 1.0, 1.0 },
            .uv = .{ 1.0, 1.0 },
        },
        .{
            .position = .{ 0, SPRITE_SIZE },
            .color = .{ 1.0, 1.0, 0.0, 1.0 },
            .uv = .{ 0.0, 1.0 },
        },
    };

    app.bind.vertex_buffers[0] = sg.makeBuffer(.{
        .data = sg.asRange(&vertices),
    });

    const indices = [_]u16{
        0, 1, 2, 0, 2, 3,
        4, 5, 6, 4, 6, 7,
    };

    app.bind.index_buffer = sg.makeBuffer(.{
        .usage = .{ .index_buffer = true },
        .data = sg.asRange(&indices),
    });

    app.background_view = sg.makeView(.{
        .texture = .{ .image = app.map.img },
    });

    app.marble.view = sg.makeView(.{
        .texture = .{ .image = app.marble.img },
    });

    // ...and a sampler object with default attributes
    app.bind.samplers[shd.SMP_smp] = sg.makeSampler(.{
        .min_filter = .NEAREST,
        .mag_filter = .NEAREST,
        .wrap_u = .CLAMP_TO_EDGE,
        .wrap_v = .CLAMP_TO_EDGE,
    });

    app.pip = sg.makePipeline(.{
        .index_type = .UINT16,
        .shader = sg.makeShader(shd.basicShaderDesc(sg.queryBackend())),
        .layout = init: {
            var l = sg.VertexLayoutState{};
            l.attrs[shd.ATTR_basic_position].format = .FLOAT2;
            l.attrs[shd.ATTR_basic_color0].format = .FLOAT4;
            l.attrs[shd.ATTR_basic_texture0].format = .FLOAT2;
            break :init l;
        },
        .colors = init: {
            var colors: [8]sg.ColorTargetState = @splat(.{});
            colors[0].blend = .{
                .enabled = true,
                .src_factor_rgb = .SRC_ALPHA,
                .dst_factor_rgb = .ONE_MINUS_SRC_ALPHA,
                .src_factor_alpha = .ONE,
                .dst_factor_alpha = .ONE_MINUS_SRC_ALPHA,
            };
            break :init colors;
        },
    });
}

pub fn deinit(_: ?*anyopaque) callconv(.c) void {
    sg.shutdown();
}

var time: f32 = 0.0;
var delta_time: f32 = 1.0 / 60.0;

var marble_frame: [2]f32 = .{ 0.0, 0.0 };
var marble_index: f32 = 0.0;

pub fn frame(user_data: ?*anyopaque) callconv(.c) void {
    const app: *App = @ptrCast(@alignCast(user_data));

    // integrate is for physics?
    // integrate(time, delta_time);

    // I think all of this code can be moved to a render call?

    // I believe each frame we will want to be passing a mvp to the shader
    sg.beginPass(.{ .swapchain = sglue.swapchain() });
    sg.applyPipeline(app.pip);

    app.marble.update(&app.input, delta_time);
    const background_params = shd.VsParams{
        // .model = ...,
        .projection = zmath.matToArr(zmath.orthographicLhGl(800, 600, -1.0, 1.0)),
        .offset = .{ 0.0, 0.0 },
        .uv_offset = .{ 0.0, 0.0 },
        .uv_scale = .{ 1.0, 1.0 },
    };

    app.bind.views[shd.VIEW_tex] = app.background_view;
    sg.applyBindings(app.bind);
    sg.applyUniforms(shd.UB_vs_params, sg.asRange(&background_params));
    sg.draw(0, 6, 1);

    const marble_params = shd.VsParams{
        // .model = ...,
        .projection = zmath.matToArr(zmath.orthographicLhGl(800, 600, -1.0, 1.0)),
        .offset = app.marble.position,
        .uv_offset = .{ 1, 4 },
        .uv_scale = app.marble.sheet.uvScale(),
    };

    app.bind.views[shd.VIEW_tex] = app.marble.view;
    sg.applyBindings(app.bind);
    sg.applyUniforms(shd.UB_vs_params, sg.asRange(&marble_params));
    sg.draw(6, 6, 1);

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

// A renderer is an abstraction in graphics programming which is responsible for managing the scene
// The renderer could be responsible for loading assets
const Renderer = struct {
    fn init() void {}
    fn draw() void {}
};
