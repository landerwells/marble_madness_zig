const sokol = @import("sokol");
const sg = sokol.gfx;

const Sprite = @This();
const SpriteSheet = @import("sprite_sheet.zig");

pub const Texture = struct {
    view: sg.View,
};

offset: [2]f32 = .{ 0.0, 0.0 },
texture: ?*const Texture = null,
sheet: ?*const SpriteSheet = null,
