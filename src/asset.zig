const std = @import("std");

const sokol = @import("sokol");
const sg = sokol.gfx;
const zigimg = @import("zigimg");

const c = @cImport({
    @cInclude("stb_truetype.h");
});

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

pub fn loadFont(allocator: std.mem.Allocator) void {
    const font_bytes = try std.fs.cwd().readFileAlloc(
        allocator,
        "assets/font/Pixelated.ttf",
        10 * 1024 * 1024,
    );

    var font_info: c.stbtt_fontinfo = undefined;

    if (c.stbtt_InitFont(
        &font_info,
        font_bytes.ptr,
        c.stbtt_GetFontOffsetForIndex(font_bytes.ptr, 0),
    ) == 0) {
        return error.InvalidFont;
    }
}
