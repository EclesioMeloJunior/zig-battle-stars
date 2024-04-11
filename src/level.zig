const std = @import("std");
const time = std.time;
const RndGen = std.rand.DefaultPrng;
const raylib = @cImport({
    @cInclude("raylib.h");
});
const game = @import("game.zig");
const screen = @import("screen.zig");
const Allocator = std.mem.Allocator;

pub const ENEMY_SIZE: c_int = 25;
pub const ENEMY_WAIT_TIME: c_int = 0;
pub const ENEMY_LEFT_X_LIMIT: f32 = game.ACTOR_SIZE / 2;
pub const ENEMY_RIGHT_X_LIMIT: f32 = screen.SCREEN_WIDTH - (game.ACTOR_SIZE / 2);
pub const ENEMY_Y_LIMIT: f32 = screen.SCREEN_HEIGHT * 2 / 3;

pub const Enemy = struct {
    texture: raylib.Texture2D,
    texture_src: raylib.Rectangle,
    object: raylib.Rectangle,
    wait: c_int,

    pub fn small_enemy(x_pos: f32, y_pos: f32) Enemy {
        const small_enemy_texture = raylib.LoadTexture("./resources/small_enemy.png");

        return Enemy{
            .wait = ENEMY_WAIT_TIME,
            .texture = small_enemy_texture,
            .texture_src = .{
                .x = 0,
                .y = 0,
                .width = game.cintToFloat32(small_enemy_texture.width),
                .height = game.cintToFloat32(small_enemy_texture.height),
            },
            .object = .{
                .x = x_pos,
                .y = y_pos,
                .width = @as(f32, ENEMY_SIZE),
                .height = @as(f32, ENEMY_SIZE),
            },
        };
    }

    pub fn random_walk(self: *Enemy) void {
        if (self.wait > 0) {
            self.wait -= 1;
            return;
        }

        self.wait = ENEMY_WAIT_TIME;

        var rnd = RndGen.init(@intCast(time.timestamp()));
        var vertical: f32 = if (rnd.random().boolean()) 1.0 else -1.0;
        if ((self.object.y + vertical) >= 0 and (self.object.y + self.object.height + vertical) <= ENEMY_Y_LIMIT) {
            self.object.y += vertical;
        }

        var horizontal: f32 = if (rnd.random().boolean()) 1.0 else -1.0;
        if ((self.object.x + horizontal) >= ENEMY_LEFT_X_LIMIT and (self.object.x + self.object.width + horizontal) <= ENEMY_RIGHT_X_LIMIT) {
            self.object.x += horizontal;
        }
    }
};

pub const Level = struct {
    number: usize,
    enemies: ?std.ArrayList(Enemy),

    pub fn deinit(self: *Level) void {
        if (self.enemies) |enemies| {
            enemies.deinit();
            std.debug.print("deinit level\n", .{});
        }
    }

    pub fn update(self: *Level) void {
        if (self.enemies) |enemies| {
            for (enemies.items) |*enemy| {
                enemy.random_walk();
            }
        }
    }
};

pub fn CreateEmptyLevel() Level {
    return Level{
        .number = 0,
        .enemies = null,
    };
}

pub fn CreateNextLevel(number: usize, canvas: raylib.Vector2, allocator: Allocator) !Level {
    //const enemies_per_row = 4;
    var enemies = try std.ArrayList(Enemy).initCapacity(allocator, number);
    try enemies.append(Enemy.small_enemy((canvas.x / 2) - (ENEMY_SIZE / 2), 50));

    return Level{
        .number = number,
        .enemies = enemies,
    };
}
