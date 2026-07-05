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

    // This is simply an array of pixels, in order to flip the image,
    // we will have to write some code to swap it
    const pixels: []zigimg.color.Rgba32 = image.pixels.rgba32;
    // Width is going to be the size of array that we need,
    const width = image.width;
    const height = image.height;

    const tmp = try allocator.alloc(zigimg.color.Rgba32, width);

    var i: u32 = 0;
    while (i < height / 2) : (i += 1) {
        const top_row = i;
        const bottom_row = height - 1 - i;

        const first = pixels[top_row * width .. (top_row + 1) * width];
        const second = pixels[bottom_row * width .. (bottom_row + 1) * width];

        @memcpy(tmp, first);
        @memcpy(first, second);
        @memcpy(second, tmp);
    }

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
