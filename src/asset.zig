const std = @import("std");

const sokol = @import("sokol");
const sg = sokol.gfx;
const zigimg = @import("zigimg");

// Should rename to texture, and asset.zig should load and
// store all of the assets for the app.
pub fn loadImage(io: std.Io, allocator: std.mem.Allocator, path: []const u8) !sg.Image {
    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var image = try zigimg.Image.fromFilePath(allocator, io, path, read_buffer[0..]);
    defer image.deinit(allocator);

    try image.convert(allocator, .rgba32);

    const pixels: []zigimg.color.Rgba32 = image.pixels.rgba32;

    var img_data = sg.ImageData{};
    img_data.mip_levels[0] = sg.asRange(pixels);

    return sg.makeImage(.{
        .width = @intCast(image.width),
        .height = @intCast(image.height),
        .data = img_data,
    });
}

pub fn loadTileMap() void {}

pub fn generateTileMap() void {}

pub fn loadFont() void {}
