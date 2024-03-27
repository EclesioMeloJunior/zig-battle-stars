const std = @import("std");
const raylib = @cImport({
    @cInclude("raylib.h");
});
const game = @import("game.zig");

const SCREEN_WIDTH: c_int = 800;
const SCREEN_HEIGHT: c_int = 450;

pub fn main() !void {
    const window_title: [*c]const u8 = "ziground";

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

    var player = try game.Player.init(
        SCREEN_WIDTH,
        SCREEN_HEIGHT,
        allocator,
    );
    defer player.deinit();

    var game_state = game.GameState{
        .canvas = .{ .x = SCREEN_WIDTH, .y = SCREEN_HEIGHT },
        .player = player,
    };

    raylib.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, window_title);
    raylib.SetTargetFPS(60);

    while (!raylib.WindowShouldClose()) {
        try game.GameState.update(&game_state);

        raylib.BeginDrawing();
        raylib.ClearBackground(raylib.RAYWHITE);

        game.GameState.draw(&game_state);
        raylib.EndDrawing();
    }

    raylib.CloseWindow();
}
