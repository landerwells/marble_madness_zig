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
    uv: [2]f32,
};

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

    app.renderer.draw(app.background_view, .{ 0.0, 0.0 }, .{ 0.0, 0.0 });
    app.renderer.draw(app.marble_view, .{ 0.0, 0.0 }, .{ 0.0, 0.0 });

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

const Renderer = struct {
    bind: sg.Bindings = .{},
    pip: sg.Pipeline = .{},

    const vertices = [_]Vertex{
        .{
            .position = .{ 0.0, 1.0 },
            .uv = .{ 0.0, 1.0 },
        },
        .{
            .position = .{ 1.0, 0.0 },
            .uv = .{ 1.0, 0.0 },
        },
        .{
            .position = .{ 1.0, 1.0 },
            .uv = .{ 1.0, 1.0 },
        },
        .{
            .position = .{ 0, 1.0 },
            .uv = .{ 0.0, 1.0 },
        },
    };

    const indices = [_]u16{ 0, 1, 2, 0, 2, 3 };

    fn init(self: *Renderer) void {
        self.bind.vertex_buffers[0] = sg.makeBuffer(.{
            .data = sg.asRange(&vertices),
        });

        self.bind.index_buffer = sg.makeBuffer(.{
            .usage = .{ .index_buffer = true },
            .data = sg.asRange(&indices),
        });

        // ...and a sampler object with default attributes
        self.bind.samplers[shd.SMP_smp] = sg.makeSampler(.{
            .min_filter = .NEAREST,
            .mag_filter = .NEAREST,
            .wrap_u = .CLAMP_TO_EDGE,
            .wrap_v = .CLAMP_TO_EDGE,
        });

        self.pip = sg.makePipeline(.{
            .index_type = .UINT16,
            .shader = sg.makeShader(shd.basicShaderDesc(sg.queryBackend())),
            .layout = init: {
                var l = sg.VertexLayoutState{};
                l.attrs[shd.ATTR_basic_position].format = .FLOAT2;
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

    fn draw(self: *Renderer, view: sg.View, _: [2]f32, position: [2]f32) void {
        // var model: zmath.Mat = zmath.identity();
        // model = zmath.translation(tmodel, y: f32, z: f32)
        const model = zmath.translationV(position ++ .{ 0.0, 0.0 });
        // model = zmath.translation(model, 0.5 * size[0], 0.5 * size[1]);
        // model = zmath.translation(model, -0.5 * size[0], 0.5 * size[1]);

        const uniforms = shd.VsParams{
            .model = zmath.matToArr(model),
            .projection = zmath.matToArr(zmath.orthographicLhGl(8, 6, -1.0, 1.0)),
        };

        self.bind.views[shd.VIEW_tex] = view;
        sg.applyBindings(self.bind);
        sg.applyUniforms(shd.UB_vs_params, sg.asRange(&uniforms));
        sg.draw(0, 6, 1);
    }
};
