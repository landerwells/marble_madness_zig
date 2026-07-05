const std = @import("std");

const sokol = @import("sokol");
const sg = sokol.gfx;

const zigimg = @import("zigimg");

// I could change this to use stb_image if I wanted.
pub fn loadImage(io: std.Io, allocator: std.mem.Allocator, path: []const u8) !sg.Image {
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

pub fn loadMap() void {}

pub fn loadFont() void {}
