const shd = @import("shader");
const sokol = @import("sokol");
const sg = sokol.gfx;
const zmath = @import("zmath");

const Camera = @import("camera.zig");
const Sprite = @import("sprite.zig");
const SpriteSheet = @import("sprite_sheet.zig");
const TileMap = @import("tile_map.zig");

bind: sg.Bindings = .{},
pip: sg.Pipeline = .{},

current_texture: ?*const Sprite.Texture = null,

// TODO: Long term need to refactor renderer to support batching
//
const Vertex = struct {
    position: [2]f32,
    uv: [2]f32,
};

const Renderer = @This();
const vertices = [_]Vertex{
    .{
        .position = .{ 0.0, 0.0 },
        .uv = .{ 0.0, 1.0 },
    },
    .{
        .position = .{ 1.0, 0.0 },
        .uv = .{ 1.0, 1.0 },
    },
    .{
        .position = .{ 1.0, 1.0 },
        .uv = .{ 1.0, 0.0 },
    },
    .{
        .position = .{ 0, 1.0 },
        .uv = .{ 0.0, 0.0 },
    },
};

const indices = [_]u16{ 0, 1, 2, 0, 2, 3 };

pub fn init(self: *Renderer) void {
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

pub fn draw(
    self: *Renderer,
    view: [16]f32,
    projection: [16]f32,
    tint: [3]f32,
    sprite: *Sprite,
    position: [2]f32,
    size: [2]f32,
) void {
    var model = zmath.translationV(position[0..2].* ++ .{ 0.0, 0.0 });
    model = zmath.mul(model, zmath.scaling(size[0], size[1], 1.0));

    const uniforms = shd.VsParams{
        .model = zmath.matToArr(model),
        .view = view,
        .projection = projection,
        // We are passing this in as a uniform right now, but I believe
        // this should just be part of a dynamic vertex buffer.
        .tint = tint,
        .uv_offset = sprite.offset,
        .uv_scale = sprite.sheet.?.uvScale(),
    };

    if (self.current_texture != sprite.texture.?) {
        self.current_texture = sprite.texture.?;
        self.bind.views[shd.VIEW_tex] = sprite.texture.?.view;
        sg.applyBindings(self.bind);
    }
    sg.applyUniforms(shd.UB_vs_params, sg.asRange(&uniforms));
    sg.draw(0, 6, 1);
}
