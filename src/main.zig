const std = @import("std");
const raylib = @cImport({
    @cInclude("raylib.h");
});
const game = @import("game.zig");
const bullet = @import("bullet.zig");
const level = @import("level.zig");

const SCREEN_WIDTH: c_int = 800;
const SCREEN_HEIGHT: c_int = 450;

pub fn main() !void {
    const window_title: [*c]const u8 = "ziground";
    raylib.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, window_title);
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
        SCREEN_WIDTH,
        SCREEN_HEIGHT,
        bullet_collection,
        allocator,
    );
    defer player.deinit();

    const current_canvas = .{ .x = SCREEN_WIDTH, .y = SCREEN_HEIGHT };

    var game_state = game.GameState{
        .allocator = allocator,
        .canvas = current_canvas,
        .player = player,
        .current_level = level.CreateEmptyLevel(),
    };

    while (!raylib.WindowShouldClose()) {
        try game.GameState.update(&game_state);

        raylib.BeginDrawing();
        raylib.ClearBackground(raylib.RAYWHITE);

        game.GameState.draw(&game_state);
        raylib.EndDrawing();
    }

    raylib.CloseWindow();
}
