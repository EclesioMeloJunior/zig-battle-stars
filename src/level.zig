const std = @import("std");
const raylib = @cImport({
    @cInclude("raylib.h");
});
const Allocator = std.mem.Allocator;

pub const ENEMY_SIZE: c_int = 100;

pub const Enemy = struct {
    object: raylib.Rectangle,
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
};

pub fn CreateEmptyLevel() Level {
    return Level{
        .number = 0,
        .enemies = null,
    };
}

pub fn CreateNextLevel(number: usize, canvas: raylib.Vector2, allocator: Allocator) !Level {
    //const enemies_per_row = 4;
    const enemy = Enemy{ .object = .{
        .x = (canvas.x / 2) - (ENEMY_SIZE / 2),
        .y = 50,
        .width = @as(f32, ENEMY_SIZE),
        .height = @as(f32, ENEMY_SIZE),
    } };

    var enemies = try std.ArrayList(Enemy).initCapacity(allocator, number);
    try enemies.append(enemy);

    return Level{
        .number = number,
        .enemies = enemies,
    };
}
