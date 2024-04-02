const std = @import("std");
const raylib = @cImport({
    @cInclude("raylib.h");
});

pub const Bullet = struct {
    texture: raylib.Texture2D,
    source: raylib.Rectangle,
    dest: raylib.Rectangle,
    origin: raylib.Vector2,
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
