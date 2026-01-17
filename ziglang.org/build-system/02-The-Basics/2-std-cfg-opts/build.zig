const std = @import("std");

pub fn build(b: *std.Build) void {
    // This gives us some standard target options under Project-Specific Options:
    const target = b.standardTargetOptions(.{});
    // This gives us some standard optimize options under Project-Specific Options:
    const optimize = b.standardOptimizeOption(.{});
    // Try running zig build --help, and notice that we get different Project-Specific Options now
    const exe = b.addExecutable(.{
        .name = "hello",
        .root_module = b.createModule(.{
            .root_source_file = b.path("hello.zig"),
            // When we run with -Dtarget=x86_64-windows from the cmdline, that's what is passed
            .target = target,
            // When we run with -Doptimize=ReleaseSmall from the cmdline, that's what is passed
            .optimize = optimize,
        }),
    });

    b.installArtifact(exe);
}
