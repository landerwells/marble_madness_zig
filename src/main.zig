const state = @import("state.zig");

const sokol = @import("sokol");
const shd = @import("shader");
const sapp = sokol.app;
const sg = sokol.gfx;
const sglue = sokol.glue;
const slog = sokol.log;

const zigimg = @import("zigimg");

export fn init() void {
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });

    // I believe in order to actually read my image, I am going to need
    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var _ = try zigimg.Image.fromFilePath(init.gpa, init.io, "my_image.png", read_buffer[0..]);

    state.bind.vertex_buffers[0] = sg.makeBuffer(.{
        .data = sg.asRange(&[_]f32{
            // positions     colors              texture
            -0.5, 0.5,  0.5, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0,
            0.5,  0.5,  0.5, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0,
            0.5,  -0.5, 0.5, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0,
            -0.5, -0.5, 0.5, 1.0, 1.0, 0.0, 1.0, 0.0, 1.0,
        }),
    });

    state.bind.index_buffer = sg.makeBuffer(.{
        .usage = .{ .index_buffer = true },
        .data = sg.asRange(&[_]u16{ 0, 1, 2, 0, 2, 3 }),
    });

    state.bind.views[shd.VIEW_tex] = sg.makeView(.{
        .texture = .{
            .image = sg.makeImage(.{
                .width = 4,
                .height = 4,
                .data = init: {
                    var data = sg.ImageData{};
                    data.mip_levels[0] = sg.asRange(&[4 * 4]u32{
                        0xFFFFFFFF, 0xFF000000, 0xFFFFFFFF, 0xFF000000,
                        0xFF000000, 0xFFFFFFFF, 0xFF000000, 0xFFFFFFFF,
                        0xFFFFFFFF, 0xFF000000, 0xFFFFFFFF, 0xFF000000,
                        0xFF000000, 0xFFFFFFFF, 0xFF000000, 0xFFFFFFFF,
                    });
                    break :init data;
                },
            }),
        },
    });

    // ...and a sampler object with default attributes
    state.bind.samplers[shd.SMP_smp] = sg.makeSampler(.{});

    state.pip = sg.makePipeline(.{
        .index_type = .UINT16,
        .shader = sg.makeShader(shd.basicShaderDesc(sg.queryBackend())),
        .layout = init: {
            var l = sg.VertexLayoutState{};
            l.attrs[shd.ATTR_basic_position].format = .FLOAT3;
            l.attrs[shd.ATTR_basic_color0].format = .FLOAT4;
            l.attrs[shd.ATTR_basic_texture0].format = .FLOAT2;
            break :init l;
        },
    });
}

export fn frame() void {
    sg.beginPass(.{ .swapchain = sglue.swapchain() });
    sg.applyPipeline(state.pip);
    sg.applyBindings(state.bind);
    sg.draw(0, 6, 1);
    sg.endPass();
    sg.commit();
}

export fn input(ev: ?*const sapp.Event) void {
    const e = ev.?;
    // First want to check
    if (e.type != .KEY_DOWN) return;

    switch (e.key_code) {
        .ESCAPE => sapp.requestQuit(),
        else => {},
    }
}

export fn cleanup() void {
    sg.shutdown();
}

pub fn main() void {
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = input,
        .width = 640,
        .height = 480,
        .icon = .{ .sokol_default = true },
        .window_title = "Marble Madness",
        .logger = .{ .func = slog.func },
    });
}
