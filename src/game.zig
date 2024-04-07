const std = @import("std");
const raylib = @cImport({
    @cInclude("raylib.h");
});
const bullet = @import("bullet.zig");
const level = @import("level.zig");
const mem = std.mem;
const Allocator = mem.Allocator;

const ACTOR_SIZE: c_int = 100;
const PROJECTILE_SIZE: c_int = 15;
const CHARGING_DELAY: i32 = 10; // 2s (given 60FPS)

fn cintToFloat32(value: c_int) f32 {
    return @as(f32, @floatFromInt(value));
}

pub const Player = struct {
    bullet_collection: bullet.BulletCollection,
    spaceship: raylib.Texture2D,
    spaceship_source: raylib.Rectangle,
    spaceship_dest: raylib.Rectangle,

    recharging: i32,
    shoots: std.ArrayList(bullet.Bullet),

    pub fn init(
        comptime screen_width: comptime_int,
        comptime screen_height: comptime_int,
        bullet_collection: bullet.BulletCollection,
        allocator: Allocator,
    ) !Player {
        const texture = raylib.LoadTexture("./resources/spaceship_blue.PNG");

        return Player{
            .bullet_collection = bullet_collection,
            .spaceship = texture,
            .spaceship_source = .{
                .x = 0,
                .y = 0,
                .width = cintToFloat32(texture.width),
                .height = cintToFloat32(texture.height),
            },
            .spaceship_dest = .{
                .x = cintToFloat32((screen_width / 2) - (ACTOR_SIZE / 2)),
                .y = cintToFloat32(screen_height - ACTOR_SIZE),
                .width = cintToFloat32(ACTOR_SIZE),
                .height = cintToFloat32(ACTOR_SIZE),
            },
            .shoots = try std.ArrayList(bullet.Bullet).initCapacity(allocator, 40),
            .recharging = 0,
        };
    }

    pub fn deinit(self: *Player) void {
        self.shoots.deinit();
        std.debug.print("deinit player\n", .{});
    }

    fn shoot(self: *Player) !void {
        var local_x: f32 = self.spaceship_dest.x + (ACTOR_SIZE / 2) - (PROJECTILE_SIZE / 2);
        var local: raylib.Rectangle = .{
            .height = PROJECTILE_SIZE,
            .width = PROJECTILE_SIZE,
            .x = local_x,
            .y = self.spaceship_dest.y - PROJECTILE_SIZE + 20,
        };

        var projectile = self.bullet_collection.simple_bullet(local);
        try self.shoots.append(projectile);

        self.recharging = CHARGING_DELAY;
    }

    fn destroy_bullet(self: *Player, remove_idx: usize) void {
        _ = self.shoots.orderedRemove(remove_idx);
    }

    fn update_recharge(self: *Player) void {
        // limit the amount of shoots per second
        if (self.recharging > 0) {
            self.recharging -= 1;
        }
    }
};

pub const GameState = struct {
    canvas: raylib.Vector2,
    player: Player,
    current_level: level.Level,
    allocator: Allocator,

    pub fn init(
        canvas: raylib.Vector2,
        player: Player,
        allocator: Allocator,
    ) GameState {
        return GameState{
            .allocator = allocator,
            .canvas = canvas,
            .player = player,
            .current_level = level.CreateEmptyLevel(),
        };
    }

    pub fn deinit(self: *GameState) void {
        self.current_level.deinit();
    }

    pub fn update(self: *GameState) !void {
        const should_change = self.should_change_level();
        if (should_change) {
            self.current_level.deinit();
            try self.next_level();
        }

        self.player.update_recharge();
        try self.update_bullet();
        try self.handle_keyboard_input();
    }

    fn should_change_level(self: *GameState) bool {
        if (self.current_level.number == 0) {
            return true;
        }

        if (self.current_level.enemies) |enemies| {
            return enemies.items.len < 1;
        }

        return false;
    }

    fn next_level(self: *GameState) !void {
        self.current_level = try level.CreateNextLevel(
            self.current_level.number + 1,
            self.canvas,
            self.allocator,
        );
    }

    fn handle_keyboard_input(self: *GameState) !void {
        if (raylib.IsKeyDown(raylib.KEY_RIGHT)) {
            const player_x_pos = self.player.spaceship_dest.x;
            if (player_x_pos <= (self.canvas.x - @as(f32, @floatFromInt(self.player.spaceship.width - 10)))) {
                self.player.spaceship_dest.x += 3.5;
            }
        }

        if (raylib.IsKeyDown(raylib.KEY_LEFT)) {
            if (self.player.spaceship_dest.x >= 10) {
                self.player.spaceship_dest.x -= 3.5;
            }
        }

        if (raylib.IsKeyDown(raylib.KEY_SPACE) and self.player.recharging == 0) {
            try self.player.shoot();
        }
    }

    fn update_bullet(self: *GameState) !void {
        if (self.player.shoots.items.len < 0) {
            return;
        }

        var indexes_to_remove: std.ArrayList(usize) = std.ArrayList(usize).init(std.heap.page_allocator);
        defer indexes_to_remove.deinit();

        for (self.player.shoots.items, 0..) |*projectile, bullet_idx| {
            if (self.current_level.enemies) |enemies| {
                for (enemies.items, 0..) |enemy, enemy_idx| {
                    if (projectile.collision_happened(enemy.object)) {
                        std.debug.print("bullet {d} hit enemy {d}\n", .{ bullet_idx, enemy_idx });
                        try indexes_to_remove.append(bullet_idx);
                    }
                }
            }

            const is_out = projectile.bullet_out_of_canvas(self.canvas);
            if (is_out) {
                try indexes_to_remove.append(bullet_idx);
            } else {
                projectile.update_y(-1.0);
            }
        }

        for (indexes_to_remove.items) |bullet_idx| {
            self.player.destroy_bullet(bullet_idx);
        }
    }

    pub fn draw(self: *GameState) void {
        if (self.current_level.enemies) |enemies| {
            for (enemies.items) |enemy| {
                raylib.DrawRectanglePro(
                    enemy.object,
                    .{ .x = 0, .y = 0 },
                    0,
                    raylib.GREEN,
                );
            }
        }

        // var outer = self.player.spaceship_dest;
        // raylib.DrawRectanglePro(
        //     outer,
        //     .{ .x = 0, .y = 0 },
        //     0,
        //     raylib.RED,
        // );

        raylib.DrawTexturePro(
            self.player.spaceship,
            self.player.spaceship_source,
            self.player.spaceship_dest,
            .{ .x = 0, .y = 0 },
            0.0,
            raylib.WHITE,
        );

        for (self.player.shoots.items) |projectile| {
            // raylib.DrawRectanglePro(
            //     projectile.dest,
            //     .{ .x = 0, .y = 0 },
            //     0,
            //     raylib.GREEN,
            // );

            raylib.DrawTexturePro(
                projectile.texture,
                projectile.source,
                projectile.dest,
                projectile.origin,
                0,
                raylib.WHITE,
            );
        }
    }
};
