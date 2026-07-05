const std = @import("std");

const stb_image = @cImport("../lib/stb_image.h");
const sokol = @import("sokol");

const sg = sokol.gfx;

const zigimg = @import("zigimg");

pub fn loadImage(io: std.Io, allocator: std.mem.Allocator, path: []const u8) !sg.Image {
    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var image = try zigimg.Image.fromFilePath(allocator, io, path, read_buffer[0..]);
    defer image.deinit(allocator);

    try image.convert(allocator, .rgba32);

    // Write something to swap the pixels on the this boi
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
