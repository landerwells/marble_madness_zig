const sokol = @import("sokol");
const sg = sokol.gfx;

const asset = @import("asset.zig");
const Input = @import("input.zig");
const Sprite = @import("sprite.zig");
const SpriteSheet = @import("sprite_sheet.zig");

const Marble = @This();

const MOVE_ACCEL = 1.0;
const MAX_SPEED = 1.0;
const FRICTION = 2.0;

// Position is going to matter when trying to figure out which
// tile the marble is currently resting on, since the tile will
// have influence over the marble's movement.
position: [2]f32 = .{ 0.0, 0.0 },
velocity: [2]f32 = .{ 0.0, 0.0 },

img: sg.Image = .{},
view: sg.View = .{},

size: [2]f32 = .{ 1.0, 1.0 },

sprite: Sprite = Sprite{
    .offset = .{ 1.0, 4.0 },
    .sheet = &SpriteSheet{
        .texture_width = 352,
        .texture_height = 864,
        .sprite_width = 32,
        .sprite_height = 32,
    },
},

// TODO: Need to update this function to actually account for things
// other than just friction and the mouse_delta.
pub fn update(self: *Marble, input: *Input, dt: f32) void {
    self.velocity[0] += input.mouse_delta[0] * dt;
    self.velocity[1] += input.mouse_delta[1] * dt;

    self.velocity[0] *= 1.0 - FRICTION * dt;
    self.velocity[1] *= 1.0 - FRICTION * dt;

    self.position[0] += self.velocity[0] * dt;
    self.position[1] += self.velocity[1] * dt;
}
