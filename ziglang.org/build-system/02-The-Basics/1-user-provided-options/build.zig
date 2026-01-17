const std = @import("std");

pub fn build(b: *std.Build) void {
    // The option() function takes in the type to pass, a name/id for the dependency flag,
    // and a description for the flag your defining. The name along with the description
    // can be seen under the "Project-Specific Options:" when you run 'zig build --help'.
    // When a project depends on a Zig package as a dependency, it programmatically sets
    // these options when calling the dependency's build.zig script as a function.
    // `null` is returned when an option is left to default.
    // This option is used below with the .os_tag under .target.
    const windows = b.option(bool, "windows", "Target Microsoft Windows") orelse false;

    const exe = b.addExecutable(.{
        .name = "hello",
        .root_module = b.createModule(.{
            .root_source_file = b.path("example.zig"),
            // The first step in resolveTargetQuery is checking if isNative() for the Query type.
            // If ran with -Dwindows=true, it tries to run with .windows being passed. The
            // return type of the function is ResolvedTargetQuery struct, passing in the Query
            // and determining a result via the same function resolveTargetQuery, but
            // instead of /usr/lib/zig/std/Build.zig, it's in:
            // /usr/lib/zig/std/zig/system.zig. This function (if passed the flag above
            // via 'zig build -Dwindows` builds with this to resolve to the windows target,
            // and will create a .exe binary file instead.
            .target = b.resolveTargetQuery(.{
                .os_tag = if (windows) .windows else null,
            }),
        }),
    });

    b.installArtifact(exe);
}
