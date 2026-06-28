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

const std = @import("std");

const Vertex = struct {
    position: [3]f32,
    color: [4]f32,
    uv: [2]f32,
};

const INTERNAL_WIDTH = 320;
const INTERNAL_HEIGHT = 240;
const SPRITE_SIZE = 32;

const SpriteSheet = struct {
    texture_width: f32,
    texture_height: f32,
    sprite_width: f32,
    sprite_height: f32,

    fn uvRect(self: SpriteSheet, col: u32, row: u32) [4][2]f32 {
        const x0 = (@as(f32, @floatFromInt(col)) * self.sprite_width) / self.texture_width;
        const y0 = (@as(f32, @floatFromInt(row)) * self.sprite_height) / self.texture_height;
        const x1 = (@as(f32, @floatFromInt(col + 1)) * self.sprite_width) / self.texture_width;
        const y1 = (@as(f32, @floatFromInt(row + 1)) * self.sprite_height) / self.texture_height;

        return .{
            .{ x0, y0 }, // top-left
            .{ x1, y0 }, // top-right
            .{ x1, y1 }, // bottom-right
            .{ x0, y1 }, // bottom-left
        };
    }
};

const MOVE_ACCEL = 100.0;
const MAX_SPEED = 150.0;
const FRICTION = 0.5;

// The marble should probably own its own spritesheet/ animation
const Marble = struct {
    // I think technically we will need to know what Z level we are at as well,
    // since the marble should fall when not actually on the ground.
    position: [2]f32 = .{ 160.0, 120.0 },
    velocity: [2]f32 = .{ 0.0, 0.0 },

    fn update(self: *Marble, input: *Input, dt: f32) void {
        self.velocity[0] += input.mouse_delta[0] * dt;
        self.velocity[1] += input.mouse_delta[1] * dt;

        self.velocity[0] *= 1.0 - FRICTION * dt;
        self.velocity[1] *= 1.0 - FRICTION * dt;

        self.position[0] += self.velocity[0] * dt;
        self.position[1] += self.velocity[1] * dt;
    }
};

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

    const background_sheet = SpriteSheet{
        .texture_width = 192,
        .texture_height = 288,
        .sprite_width = 32,
        .sprite_height = 32,
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

    const marble_sheet = SpriteSheet{
        .texture_width = 352,
        .texture_height = 864,
        .sprite_width = 32,
        .sprite_height = 32,
    };

    const background_uvs = background_sheet.uvRect(0, 0);
    const marble_uvs = marble_sheet.uvRect(0, 2);

    const vertices = [_]Vertex{
        .{
            .position = .{ 0, 0, 0.5 },
            .color = .{ 1.0, 0.0, 0.0, 1.0 },
            .uv = background_uvs[0],
        },
        .{
            .position = .{ SPRITE_SIZE, 0, 0.5 },
            .color = .{ 0.0, 1.0, 0.0, 1.0 },
            .uv = background_uvs[1],
        },
        .{
            .position = .{ SPRITE_SIZE, SPRITE_SIZE, 0.5 },
            .color = .{ 0.0, 0.0, 1.0, 1.0 },
            .uv = background_uvs[2],
        },
        .{
            .position = .{ 0, SPRITE_SIZE, 0.5 },
            .color = .{ 1.0, 1.0, 0.0, 1.0 },
            .uv = background_uvs[3],
        },
        .{
            .position = .{ 0, 0, 0.5 },
            .color = .{ 1.0, 0.0, 0.0, 1.0 },
            .uv = marble_uvs[0],
        },
        .{
            .position = .{ SPRITE_SIZE, 0, 0.5 },
            .color = .{ 0.0, 1.0, 0.0, 1.0 },
            .uv = marble_uvs[1],
        },
        .{
            .position = .{ SPRITE_SIZE, SPRITE_SIZE, 0.5 },
            .color = .{ 0.0, SPRITE_SIZE, 1.0, 1.0 },
            .uv = marble_uvs[2],
        },
        .{
            .position = .{ 0, SPRITE_SIZE, 0.5 },
            .color = .{ 1.0, 1.0, 0.0, 1.0 },
            .uv = marble_uvs[3],
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
    };

    app.bind.views[shd.VIEW_tex] = app.background_view;
    sg.applyBindings(app.bind);
    sg.applyUniforms(shd.UB_vs_params, sg.asRange(&background_params));
    sg.draw(0, 6, 1);

    const marble_params = shd.VsParams{ .offset = app.marble.position };

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
