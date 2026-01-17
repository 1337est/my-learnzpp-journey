const std = @import("std");
// This config is from the build script when we did exe.root_module.addOptions("duckboi", options)
// The data provided by the duckboi module is comptime known, because it's a part of the build
// script via the default values or the values that we pass it right before compilation.
const config = @import("duckboi");

// This parse() function parses a major.minor.patch and returns a Version type
// Ultimately determined via the build script or what is passed via the -Dversion flag
const semver = std.SemanticVersion.parse(config.version) catch unreachable;

// Some external foo_bar from some presumable libfoo which we don't have (although someone might)
// If we changed the detectWhetherToEnableFoo to true, then this would try and get called...
extern fn foo_bar() void;

pub fn main() !void {
    // Here we check if the major version is less than 1, and if it is, throws an error
    if (semver.major < 1) {
        @compileError("too old");
    }
    std.debug.print("version: {s}\n", .{config.version});

    // Ultimately determined via the build script
    if (config.have_libfoo) {
        foo_bar();
    } else {
        std.debug.print("You do not have libfoo\nhave_libfoo: {}", .{config.have_libfoo});
    }
}
