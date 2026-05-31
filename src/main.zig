const state = @import("state.zig");

const sokol = @import("sokol");
const shd = @import("shader");
const sapp = sokol.app;
const sg = sokol.gfx;
const sglue = sokol.glue;
const sfetch = sokol.fetch;
const slog = sokol.log;

const zigimg = @import("zigimg");
const std = @import("std");

const App = struct {
    io: std.Io,
};

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

fn setup(user_data: ?*anyopaque) callconv(.c) void {
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
        .texture = .{ .image = img },
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

export fn frame(_: ?*anyopaque) callconv(.c) void {
    sg.beginPass(.{ .swapchain = sglue.swapchain() });
    sg.applyPipeline(state.pip);
    sg.applyBindings(state.bind);
    sg.draw(0, 6, 1);
    sg.endPass();
    sg.commit();
}

export fn input(ev: ?*const sapp.Event, _: ?*anyopaque) callconv(.c) void {
    const e = ev.?;
    // First want to check
    if (e.type != .KEY_DOWN) return;

    switch (e.key_code) {
        .ESCAPE => sapp.requestQuit(),
        else => {},
    }
}

export fn cleanup(_: ?*anyopaque) void {
    sg.shutdown();
}

pub fn main(init: std.process.Init) void {
    var app = App{ .io = init.io };

    sapp.run(.{
        .user_data = &app,
        .init_userdata_cb = setup,
        .frame_userdata_cb = frame,
        .cleanup_userdata_cb = cleanup,
        .event_userdata_cb = input,
        .width = 640,
        .height = 480,
        .icon = .{ .sokol_default = true },
        .window_title = "Marble Madness",
        .logger = .{ .func = slog.func },
    });
}
