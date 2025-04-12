const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const server_exe = b.addExecutable(.{
        .name = "httpz",
        .root_source_file = b.path("server.zig"),
        .target = target,
        .optimize = optimize,
    });
    server_exe.linkLibC();
    b.installArtifact(server_exe);

    const client_exe = b.addExecutable(.{
        .name = "httpz-client",
        .root_source_file = b.path("client.zig"),
        .target = target,
        .optimize = optimize,
    });
    client_exe.linkLibC();
    b.installArtifact(client_exe);
}
