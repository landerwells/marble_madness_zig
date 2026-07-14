const shd = @import("shader");
const sokol = @import("sokol");
const sg = sokol.gfx;
const zmath = @import("zmath");

const Camera = @import("camera.zig");
const SpriteSheet = @import("sprite_sheet.zig");
const TileMap = @import("tile_map.zig");
const Sprite = @import("sprite.zig");

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

// TODO: Update to handle [3]f32 position since both tiles and the marble will
// have depth as well.
pub fn draw(
    self: *Renderer,
    camera: *Camera,
    sprite: *Sprite,
    position: [2]f32,
    size: [2]f32,
) void {
    var model = zmath.translationV(position ++ .{ 0.0, 0.0 });
    model = zmath.mul(model, zmath.scaling(size[0], size[1], 1.0));
    const view_matrix = camera.view();

    const uniforms = shd.VsParams{
        .model = zmath.matToArr(model),
        .view = zmath.matToArr(view_matrix),
        .projection = zmath.matToArr(zmath.orthographicLhGl(
            camera.screen_x,
            camera.screen_y,
            -1.0,
            1.0,
        )),
        .uv_offset = sprite.offset,
        .uv_scale = sprite.sheet.?.uvScale(),
    };

    self.bind.views[shd.VIEW_tex] = sprite.texture.?.view;
    sg.applyBindings(self.bind);
    sg.applyUniforms(shd.UB_vs_params, sg.asRange(&uniforms));
    sg.draw(0, 6, 1);
}

// TODO: Need to modify in order to correctly print an isometric map.
// Thinking about this a little more, essentially the width on every
// draw call is not going to be the same
pub fn drawFromTileMap(
    self: *Renderer,
    camera: *Camera,
    tile_map: *TileMap,
) void {
    var y = tile_map.tiles.len;
    while (y > 0) {
        y -= 1;

        var x = tile_map.tiles[y].len;
        while (x > 0) {
            x -= 1;
            const position: [2]f32 = tile_map.tileToWorld(@as(f32, @floatFromInt(x)), @as(f32, @floatFromInt(y)));
            self.draw(
                camera,
                &tile_map.sprite,
                .{ position[0], position[1] },
                .{ 0.5, 0.5 },
            );
        }
    }
}

// This function needs to correctly call the draw function with position
fn drawTile() void {}
