const sokol = @import("sokol");
const shd = @import("shader");
const sapp = sokol.app;
const sg = sokol.gfx;
const sglue = sokol.glue;
const sfetch = sokol.fetch;
const slog = sokol.log;

const zigimg = @import("zigimg");
const std = @import("std");

const Vertex = struct {
    position: [3]f32,
    color: [4]f32,
    uv: [2]f32,
};

const Texture = struct {
    width: i32,
    height: i32,
};

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

const App = struct {
    // 192x288
    io: std.Io,
    bind: sg.Bindings = .{},
    pip: sg.Pipeline = .{},

    fn init(user_data: ?*anyopaque) callconv(.c) void {
        const app: *App = @ptrCast(@alignCast(user_data));

        sg.setup(.{
            .environment = sglue.environment(),
            .logger = .{ .func = slog.func },
        });

        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();

        const alloc = arena.allocator();

        const img = loadImage(
            app.io,
            alloc,
            "assets/isometric-sandbox-32x32/isometric-sandbox-sheet.png",
        ) catch |err| {
            std.log.err("failed to load image: {}", .{err});
            sapp.requestQuit();
            return;
        };

        const sheet = SpriteSheet{
            .texture_width = 192,
            .texture_height = 288,
            .sprite_width = 32,
            .sprite_height = 32,
        };

        const sprite_uvs = sheet.uvRect(0, 0);

        const vertices = [_]Vertex{
            .{
                .position = .{ -0.5, 0.5, 0.5 },
                .color = .{ 1.0, 0.0, 0.0, 1.0 },
                .uv = sprite_uvs[0],
            },
            .{
                .position = .{ 0.5, 0.5, 0.5 },
                .color = .{ 0.0, 1.0, 0.0, 1.0 },
                .uv = sprite_uvs[1],
            },
            .{
                .position = .{ 0.5, -0.5, 0.5 },
                .color = .{ 0.0, 0.0, 1.0, 1.0 },
                .uv = sprite_uvs[2],
            },
            .{
                .position = .{ -0.5, -0.5, 0.5 },
                .color = .{ 1.0, 1.0, 0.0, 1.0 },
                .uv = sprite_uvs[3],
            },
        };

        app.bind.vertex_buffers[0] = sg.makeBuffer(.{
            .data = sg.asRange(&vertices),
        });

        app.bind.index_buffer = sg.makeBuffer(.{
            .usage = .{ .index_buffer = true },
            .data = sg.asRange(&[_]u16{ 0, 1, 2, 0, 2, 3 }),
        });

        app.bind.views[shd.VIEW_tex] = sg.makeView(.{
            .texture = .{ .image = img },
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

    fn deinit(_: ?*anyopaque) callconv(.c) void {
        sg.shutdown();
    }

    // Drawing/rendering should be separate from updates
    // What is the appropriate name for this function?
    // I believe this is what is called render
    export fn frame(user_data: ?*anyopaque) callconv(.c) void {
        const app: *App = @ptrCast(@alignCast(user_data));
        sg.beginPass(.{ .swapchain = sglue.swapchain() });
        sg.applyPipeline(app.pip);
        sg.applyBindings(app.bind);
        sg.draw(0, 6, 1);
        sg.endPass();
        sg.commit();
    }

    fn event(ev: ?*const sapp.Event, _: ?*anyopaque) callconv(.c) void {
        const e = ev.?;
        // First want to check
        if (e.type != .KEY_DOWN) return;

        switch (e.key_code) {
            .ESCAPE => sapp.requestQuit(),
            else => {},
        }
    }
};

// This needs to be moved out somewhere
fn loadImage(io: std.Io, allocator: std.mem.Allocator, path: []const u8) !sg.Image {
    // need a read buffer.
    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var image = try zigimg.Image.fromFilePath(allocator, io, path, read_buffer[0..]);
    defer image.deinit(allocator);

    try image.convert(allocator, .rgba32);

    const pixels = image.pixels.rgba32;

    var img_data = sg.ImageData{};
    img_data.mip_levels[0] = sg.asRange(pixels);

    return sg.makeImage(.{
        .width = @intCast(image.width),
        .height = @intCast(image.height),
        .data = img_data,
    });
}

pub fn main(init: std.process.Init) void {
    var app = App{ .io = init.io };

    sapp.run(.{
        .user_data = &app,
        .init_userdata_cb = App.init,
        .frame_userdata_cb = App.frame,
        .cleanup_userdata_cb = App.deinit,
        .event_userdata_cb = App.event,
        .width = 640,
        .height = 480,
        .icon = .{ .sokol_default = true },
        .window_title = "Marble Madness",
        .logger = .{ .func = slog.func },
    });
}
