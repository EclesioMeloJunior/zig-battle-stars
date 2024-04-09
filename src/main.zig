const std = @import("std");
const raylib = @cImport({
    @cInclude("raylib.h");
});
const screen = @import("screen.zig");
const game = @import("game.zig");
const bullet = @import("bullet.zig");
const level = @import("level.zig");

pub fn main() !void {
    const window_title: [*c]const u8 = "zig-battle-stars";
    raylib.InitWindow(screen.SCREEN_WIDTH, screen.SCREEN_HEIGHT, window_title);
    raylib.SetTargetFPS(60);

    var gpa = std.heap.GeneralPurposeAllocator(.{
        .verbose_log = true,
        .safety = true,
    }){};

    const allocator = gpa.allocator();
    defer {
        std.debug.print("deinit gpa\n", .{});
        const deinit_status = gpa.deinit();

        if (deinit_status == .leak) @panic("MEMORY LEAK");
    }

    var bullet_collection = bullet.BulletCollection.init();
    var player = try game.Player.init(
        screen.SCREEN_WIDTH,
        screen.SCREEN_HEIGHT,
        bullet_collection,
        allocator,
    );
    defer player.deinit();

    const current_canvas = .{ .x = screen.SCREEN_WIDTH, .y = screen.SCREEN_HEIGHT };
    var game_state = game.GameState.init(
        current_canvas,
        player,
        allocator,
    );
    defer game_state.deinit();

    while (!raylib.WindowShouldClose()) {
        try game.GameState.update(&game_state);

        raylib.BeginDrawing();
        raylib.ClearBackground(raylib.RAYWHITE);

        game.GameState.draw(&game_state);
        raylib.EndDrawing();
    }

    raylib.CloseWindow();
}
