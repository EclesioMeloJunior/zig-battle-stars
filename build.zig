const std = @import("std");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const exe = b.addExecutable(.{
        .name = "ziground",
        .root_source_file = .{
            .path = "src/main.zig",
        },
        .target = target,
        .optimize = optimize,
    });

    exe.linkLibC();
    exe.addIncludePath(std.build.LazyPath.relative("vendor/raylib/zig-out/include"));
    exe.addLibraryPath(std.build.LazyPath.relative("vendor/raylib/zig-out/lib"));
    exe.linkSystemLibrary("raylib");
    exe.linkFramework("CoreVideo");
    exe.linkFramework("IOKit");
    exe.linkFramework("Cocoa");
    exe.linkFramework("GLUT");
    exe.linkFramework("OpenGL");

    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);
}
