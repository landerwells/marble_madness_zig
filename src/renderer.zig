const sokol = @import("sokol");
const shd = @import("shader");

const sg = sokol.gfx;
const zmath = @import("zmath");

bind: sg.Bindings = .{},
pip: sg.Pipeline = .{},

const Vertex = struct {
    position: [2]f32,
    uv: [2]f32,
};

const Renderer = @This();

const vertices = [_]Vertex{
    .{
        .position = .{ 0.0, 0.0 },
        .uv = .{ 0.0, 0.0 },
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

pub fn draw(self: *Renderer, view: sg.View, _: [2]f32, position: [2]f32) void {
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
