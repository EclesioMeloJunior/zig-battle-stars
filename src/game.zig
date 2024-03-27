const std = @import("std");
const raylib = @cImport({
    @cInclude("raylib.h");
});
const mem = std.mem;
const Allocator = mem.Allocator;

const ACTOR_SIZE: c_int = 100;
const PROJECTILE_SIZE: c_int = 10;
const CHARGING_DELAY: i32 = 30; // 2s (given 60FPS)

pub const Bullet = struct {
    origin: raylib.Vector2,
    object: raylib.Rectangle,
};

pub const Player = struct {
    origin: raylib.Vector2,
    object: raylib.Rectangle,

    recharging: i32,
    shoots: std.ArrayList(Bullet),

    pub fn init(comptime screen_width: comptime_int, comptime screen_height: comptime_int, allocator: Allocator) !Player {
        return Player{
            .shoots = try std.ArrayList(Bullet).initCapacity(allocator, 8),
            .origin = raylib.Vector2{ .x = 0, .y = 0 },
            .recharging = 0,
            .object = .{
                .height = ACTOR_SIZE,
                .width = ACTOR_SIZE,
                .x = @as(f32, screen_width / 2 - ACTOR_SIZE / 2),
                .y = @as(f32, screen_height / 2 - ACTOR_SIZE / 2),
            },
        };
    }

    pub fn deinit(self: *Player) void {
        std.debug.print("deinit player\n", .{});
        self.shoots.deinit();
    }

    fn shoot(self: *Player) !void {
        var bullet = Bullet{ .object = .{
            .height = PROJECTILE_SIZE,
            .width = PROJECTILE_SIZE,
            .x = self.object.x,
            .y = self.object.y - PROJECTILE_SIZE,
        }, .origin = .{
            .x = 0,
            .y = 0,
        } };

        try self.shoots.append(bullet);
        self.recharging = CHARGING_DELAY;
    }

    fn destroy_bullet(self: *Player, index: usize) void {
        _ = self.shoots.orderedRemove(index);
    }
};

pub const GameState = struct {
    canvas: raylib.Vector2,
    player: Player,

    pub fn update(self: *GameState) !void {
        // limit the amount of shoots per second
        if (self.player.recharging > 0) {
            self.player.recharging -= 1;
        }

        try self.update_bullet();
        try self.handle_keyboard_input();
    }

    fn handle_keyboard_input(self: *GameState) !void {
        if (raylib.IsKeyDown(raylib.KEY_RIGHT)) {
            self.*.player.object.x += 3.5;
        }

        if (raylib.IsKeyDown(raylib.KEY_LEFT)) {
            self.*.player.object.x -= 3.5;
        }

        if (raylib.IsKeyDown(raylib.KEY_SPACE) and self.player.recharging == 0) {
            try self.*.player.shoot();
        }
    }

    fn update_bullet(self: *GameState) !void {
        if (self.player.shoots.items.len < 0) {
            return;
        }

        var indexes_to_remove: std.ArrayList(usize) = std.ArrayList(usize).init(std.heap.page_allocator);
        defer indexes_to_remove.deinit();

        for (self.*.player.shoots.items, 0..) |*bullet_ptr, idx| {
            if (bullet_ptr.object.y <= 0) {
                try indexes_to_remove.append(idx);
            } else {
                bullet_ptr.*.object.y -= 1.0;
            }
        }

        for (indexes_to_remove.items) |bullet_idx| {
            self.player.destroy_bullet(bullet_idx);
        }
    }

    pub fn draw(self: *GameState) void {
        raylib.DrawRectanglePro(self.player.object, self.player.origin, 0, raylib.RED);

        for (self.player.shoots.items) |bullet_ptr| {
            raylib.DrawRectanglePro(bullet_ptr.object, bullet_ptr.origin, 0, raylib.DARKPURPLE);
        }
    }
};
