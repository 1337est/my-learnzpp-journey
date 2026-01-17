const std = @import("std");

pub fn build(b: *std.Build) void {
    // Nothin out of the ordinary for our exe so far
    const exe = b.addExecutable(.{
        .name = "app",
        .root_module = b.createModule(.{
            .root_source_file = b.path("app.zig"),
            .target = b.graph.host,
        }),
    });

    // Here we create a build option for -Dversion, and if not passed returns 0.0.0
    const version = b.option([]const u8, "version", "application version string") orelse "0.0.0";
    // Here we call a function that returns false
    const enable_foo = detectWhetherToEnableFoo();

    // Easy adding options variable so we don't have to do b.addOptions().addOption(version/libfoo);
    const options = b.addOptions();
    // Here we add the option to the build script with default values (0.0.0)
    options.addOption([]const u8, "version", version);
    // Here we add the option to the build script with default value (false)
    options.addOption(bool, "have_libfoo", enable_foo);

    // Converts a set of key-value pairs into a Zig source file, and then inserts it into
    // the Module's import table with the specified name. This makes the options importable
    // via `@import("module_name")`. Our module name in this instance is duckboi!
    exe.root_module.addOptions("duckboi", options);

    b.installArtifact(exe);

    // Now let's add the run step from previously
    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Runs the app");
    run_step.dependOn(&run_exe.step);
    // You run this via:
    // zig build -Dversion=1.1.1 --summary all run
}

fn detectWhetherToEnableFoo() bool {
    // Changing this to true breaks the program because we don't have libfoo
    return false;
}
