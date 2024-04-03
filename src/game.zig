const std = @import("std");
const raylib = @cImport({
    @cInclude("raylib.h");
});
const bullet = @import("bullet.zig");
const mem = std.mem;
const Allocator = mem.Allocator;

const ACTOR_SIZE: c_int = 100;
const PROJECTILE_SIZE: c_int = 15;
const CHARGING_DELAY: i32 = 30; // 2s (given 60FPS)

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

    pub fn init(comptime screen_width: comptime_int, comptime screen_height: comptime_int, bullet_collection: bullet.BulletCollection, allocator: Allocator) !Player {
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

        for (self.player.shoots.items, 0..) |*projectile, idx| {
            if (projectile.dest.y <= 0) {
                try indexes_to_remove.append(idx);
            } else {
                projectile.*.dest.y -= 1.0;
            }
        }

        for (indexes_to_remove.items) |bullet_idx| {
            self.player.destroy_bullet(bullet_idx);
        }
    }

    pub fn draw(self: *GameState) void {
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
