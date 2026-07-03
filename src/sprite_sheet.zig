// So sprite_sheet is supposed to handle all of the sprites, not
// sure how the animations are going to fit itno this system.

// Basically for every sprite we are going to need to define which
// actions are being performed. Probably via an enum?

const std = @import("std");
const SpriteSheet = @This();

texture_width: u32,
texture_height: u32,
sprite_width: u32,
sprite_height: u32,

pub fn uvScale(self: SpriteSheet) [2]f32 {
    return .{
        1.0 / (@as(f32, @floatFromInt(self.texture_width)) / @as(f32, @floatFromInt(self.sprite_width))),
        1.0 / (@as(f32, @floatFromInt(self.texture_height)) / @as(f32, @floatFromInt(self.sprite_height))),
    };
}

test uvScale {
    const sheet = SpriteSheet{
        .texture_width = 64,
        .texture_height = 32,
        .sprite_width = 16,
        .sprite_height = 16,
    };

    try std.testing.expectEqual(.{ 0.25, 0.5 }, sheet.uvScale());
}

// Not sure if these are needed anymore.
// pub fn uvOffset(self: SpriteSheet, index: u32) [2]f32 {
//     const cols = self.texture_width / self.texture_width;

//     const col = index % cols;
//     const row = index / cols;

//     const scale = self.uvScale();

//     return .{
//         @as(f32, @floatFromInt(col)) * scale[0],
//         @as(f32, @floatFromInt(row)) * scale[1],
//     };
// }

// pub fn uvOffsetFromRowCol(self: SpriteSheet, row: u32, col: u32) [2]f32 {
//     const scale = self.uvScale();

//     return .{
//         @as(f32, @floatFromInt(col)) * scale[0],
//         @as(f32, @floatFromInt(row)) * scale[1],
//     };
// }
