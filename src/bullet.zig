const std = @import("std");
const raylib = @cImport({
    @cInclude("raylib.h");
});

pub const Bullet = struct {
    texture: raylib.Texture2D,
    source: raylib.Rectangle,
    dest: raylib.Rectangle,
    origin: raylib.Vector2,

    pub fn bullet_out_of_canvas(self: *Bullet, current_game_canvas: raylib.Vector2) bool {
        const canvas_top_edge: f32 = 0.0;
        const canvas_bottom_edge = current_game_canvas.y;

        const canvas_left_edge: f32 = 0.0;
        const canvas_rigth_edge = current_game_canvas.x;

        return self.dest.y < canvas_top_edge or
            self.dest.y > canvas_bottom_edge or
            self.dest.x < canvas_left_edge or
            self.dest.x > canvas_rigth_edge;
    }

    pub fn update_y(self: *Bullet, value: f32) void {
        self.dest.y += value;
    }
};

pub const BulletCollection = struct {
    collection: raylib.Texture2D,

    pub fn init() BulletCollection {
        return BulletCollection{
            .collection = raylib.LoadTexture("./resources/bullets.png"),
        };
    }

    pub fn simple_bullet(self: BulletCollection, dest: raylib.Rectangle) Bullet {
        var bullet_pos = raylib.Rectangle{
            .x = 137,
            .y = 5,
            .width = 15,
            .height = 15,
        };

        return Bullet{
            .texture = self.collection,
            .source = bullet_pos,
            .dest = dest,
            .origin = .{ .x = 0, .y = 0 },
        };
    }
};
