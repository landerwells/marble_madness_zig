const App = @This();

const asset = @import("asset.zig");
const sokol = @import("sokol");

const zmath = @import("zmath");
const sapp = sokol.app;
const sg = sokol.gfx;
const sglue = sokol.glue;
const sfetch = sokol.fetch;
const slog = sokol.log;
const shd = @import("shader");
const Input = @import("input.zig");
const SpriteSheet = @import("sprite_sheet.zig");
const Marble = @import("marble.zig");

const std = @import("std");

const Vertex = struct {
    position: [3]f32,
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
marble_view: sg.View = .{},

marble: Marble = .{},

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
        "assets/isometric-sandbox-32x32/isometric-sandbox-sheet.png",
    ) catch |err| {
        std.log.err("failed to load image: {}", .{err});
        sapp.requestQuit();
        return;
    };

    // const background_sheet = SpriteSheet{
    //     .texture_width = 192,
    //     .texture_height = 288,
    //     .sprite_width = 32,
    //     .sprite_height = 32,
    // };

    marble.img = asset.loadImage(
        app.io,
        alloc,
        "assets/misc.png",
    ) catch |err| {
        std.log.err("failed to load image: {}", .{err});
        sapp.requestQuit();
        return;
    };

    const vertices = [_]Vertex{
        .{
            .position = .{ 0, 0, 0.5 },
            .color = .{ 1.0, 0.0, 0.0, 1.0 },
            .uv = .{ 0.0, 0.0 },
        },
        .{
            .position = .{ SPRITE_SIZE, 0, 0.5 },
            .color = .{ 0.0, 1.0, 0.0, 1.0 },
            .uv = .{ 1.0, 0.0 },
        },
        .{
            .position = .{ SPRITE_SIZE, SPRITE_SIZE, 0.5 },
            .color = .{ 0.0, 0.0, 1.0, 1.0 },
            .uv = .{ 1.0, 1.0 },
        },
        .{
            .position = .{ 0, SPRITE_SIZE, 0.5 },
            .color = .{ 1.0, 1.0, 0.0, 1.0 },
            .uv = .{ 0.0, 1.0 },
        },
        .{
            .position = .{ 0, 0, 0.5 },
            .color = .{ 1.0, 0.0, 0.0, 1.0 },
            .uv = .{ 0.0, 0.0 },
        },
        .{
            .position = .{ SPRITE_SIZE, 0, 0.5 },
            .color = .{ 0.0, 1.0, 0.0, 1.0 },
            .uv = .{ 1.0, 0.0 },
        },
        .{
            .position = .{ SPRITE_SIZE, SPRITE_SIZE, 0.5 },
            .color = .{ 0.0, SPRITE_SIZE, 1.0, 1.0 },
            .uv = .{ 1.0, 1.0 },
        },
        .{
            .position = .{ 0, SPRITE_SIZE, 0.5 },
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
        .texture = .{ .image = background_img },
    });

    app.marble_view = sg.makeView(.{
        .texture = .{ .image = marble_img },
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
            l.attrs[shd.ATTR_basic_position].format = .FLOAT3;
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
    // render();

    // I think all of this code can be moved to a render call?
    sg.beginPass(.{ .swapchain = sglue.swapchain() });
    sg.applyPipeline(app.pip);

    app.marble.update(&app.input, delta_time);
    const background_params = shd.VsParams{
        .offset = .{ 0.0, 0.0 },
        .uv_offset = .{ 0.0, 0.0 },
        .uv_scale = .{ 1.0, 1.0 },
    };

    app.bind.views[shd.VIEW_tex] = app.background_view;
    sg.applyBindings(app.bind);
    sg.applyUniforms(shd.UB_vs_params, sg.asRange(&background_params));
    sg.draw(0, 6, 1);

    // Alright, we technically got sprite animation "working"
    const marble_params = shd.VsParams{
        .offset = app.marble.position,
        // How to get this UV offset to a meaningful value?
        // Need a function to calculate and return a [2]f32 based on the current
        // animation frame
        // Need to convert here from rows/cols to uv offset
        // So need a function that allows
        .uv_offset = app.marble.sheet.uvOffset(@intFromFloat(marble_index)),
        .uv_scale = app.marble.sheet.uvScale(),
    };

    marble_index += 0.01;
    // marble_index = marble_index % 10;

    app.bind.views[shd.VIEW_tex] = app.marble_view;
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
