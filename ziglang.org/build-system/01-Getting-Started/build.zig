// Although there is only 13 lines of real code here, let's dig a litter deeper into
// understanding what's happening underneath the hood.
// Currently on my linux system if I go to where this @import is coming from
// I'm taken to /usr/lib/zig/std/std.zig
const std = @import("std");

// Inside the /usr/lib/zig/std/std.zig file, there's this declaration:
// pub const Build = @import("Build.zig");
// When I go into this file Build.zig,
// I'm taken to /usr/lib/zig/std/Build.zig
// I think this might mean that the @import function assumes the current directory
// I'm assured in this assessment because when I go to the file:
// /usr/lib/zig/std/Build/Step.zig, I see the below @import statement:
// const std = @import("../std.zig");
// When I follow this file it takes me 1 step up, back to /usr/lib/zig/std/std.zig
// What does this star/pointer mean as a part of the type?
pub fn build(b: *std.Build) void {
    // calls the addExecutable
    const exe = b.addExecutable(.{
        .name = "hello",
        // calls the create() function in the Module.zig file
        .root_module = b.createModule(.{
            // Here we only really care about the .name and the .root_module because that's all we have
            // so far below. The .name is easy as it's just an array of []const u8 values/characters (a string),
            // which judging from the output of zig build, is the name of the executable/binary file.
            // .root_module seems to be related to this *Module section. When we dive deeper here we
            // find, that this Module refers to /usr/lib/zig/std/Build/Module.zig
            // We are calling a createModule function below which is a function belonging to
            // The Build.zig file. The doc comment says that the function creates a "private" module,
            // to be used only by the current "package" (assuming this means the bin file hello),
            // and that other packages that depend on this one, the createModule function assumes
            // privacy for those as well. The addModule seems to be the option for when you want a
            // public module set for a package, thus making it available to other packages which
            // depends on this one. So createModule for private package details, and addModule for
            // adding shared implementation details of certain packages. createModule is returning
            // return Module.create(b, options);
            // This means that the /usr/lib/zig/std/Build/Module.zig function create() is being used
            // The below function is the create() function being used from Module.zig
            // pub fn create(owner: *std.Build, options: CreateOptions) *Module {
            //     const m = owner.allocator.create(Module) catch @panic("OOM");
            //     m.init(owner, .{ .options = options });
            //     return m;
            // }
            //
            // The owner.allocator.create(Module) catch @panic("OOM"), is broken down this way...
            // owner is the build object being passed,
            // allocator is just an alias for the Allocator.zig file being used via multiple references
            // boiling up to /usr/lib/zig/std/mem/Allocator.zig function
            // When we go to the create function here we get somewhere too complicated for me to
            // currently understand, but it seems like it's holding some type of reference or pointer
            // to the real addressed memory to be stored (in this instance to our Module), and to
            // catch a panic "OOM", whatever that means. This would likely mean that since we are
            // returning a *Module, that we are returning the actual in memory module we are creating,
            // and storing that value in m, or we panic with "OOM"... I've dug deep long enough on
            // this one, time to move onto m.init
            // Therefore, if we are able to create our allocation for our Module, then we can m.init
            // This probably initializes the Module, but let's look deeper.
            // From the looks of it, this seems to pass in the in memory module we created, with
            // whatever build we are currently using as well... This weirdly enough looks like it goes
            // thruogh a filtering process via a switch statement to determine if there's any new
            // options for the Build -> Module (so far everything seems pretty intuitive)
            // Let's focus on the CreateOptions that seem to be checked via the switch statement.
            // The CreateOptions struct belongs to /usr/lib/zig/std/Build/Module.zig file, and
            // even though I'm tempted to dig deeper into all of these values, let's stick to them
            // as I need them to understand the control flow.
            .root_source_file = b.path("hello.zig"),
            // First we have the .root_source_file that is passed to the switch statement,
            // and our code call this b.path() function, passing in what seems to be a file called
            // hello.zig. There's probably going to be some error handling and file system calls,
            // but let's check it out. It seems our .root_source_file is expecting a LazyPath, or
            // a null value means that the module is made of only link_object(?), but what's a
            // LazyPath? A LazyPath is what I'll paste below (with doc comments removed):
            // pub const LazyPath = union(enum) {
            //     src_path: struct {
            //         owner: *std.Build,
            //         sub_path: []const u8,
            //     },
            //
            //     generated: struct {
            //         file: *const GeneratedFile,
            //
            //         up: usize = 0,
            //
            //         sub_path: []const u8 = "",
            //     },
            //
            //     cwd_relative: []const u8,
            //
            //     dependency: struct {
            //         dependency: *Dependency,
            //         sub_path: []const u8,
            //     },
            //
            //     pub fn dirname(lazy_path: LazyPath) LazyPath {
            //         return switch (lazy_path) {
            //             .src_path => |sp| .{ .src_path = .{
            //                 .owner = sp.owner,
            //                 .sub_path = dirnameAllowEmpty(sp.sub_path) orelse {
            //                     dumpBadDirnameHelp(null, null, "dirname() attempted to traverse outside the build root\n", .{}) catch {};
            //                     @panic("misconfigured build script");
            //                 },
            //             } },
            //             .generated => |generated| .{ .generated = if (dirnameAllowEmpty(generated.sub_path)) |sub_dirname| .{
            //                 .file = generated.file,
            //                 .up = generated.up,
            //                 .sub_path = sub_dirname,
            //             } else .{
            //                 .file = generated.file,
            //                 .up = generated.up + 1,
            //                 .sub_path = "",
            //             } },
            //             .cwd_relative => |rel_path| .{
            //                 .cwd_relative = dirnameAllowEmpty(rel_path) orelse {
            //                     if (fs.path.isAbsolute(rel_path)) {
            //                         dumpBadDirnameHelp(null, null,
            //                             \\dirname() attempted to traverse outside the root.
            //                             \\No more directories left to go up.
            //                             \\
            //                         , .{}) catch {};
            //                         @panic("misconfigured build script");
            //                     } else {
            //                         dumpBadDirnameHelp(null, null,
            //                             \\dirname() attempted to traverse outside the current working directory.
            //                             \\
            //                         , .{}) catch {};
            //                         @panic("misconfigured build script");
            //                     }
            //                 },
            //             },
            //             .dependency => |dep| .{ .dependency = .{
            //                 .dependency = dep.dependency,
            //                 .sub_path = dirnameAllowEmpty(dep.sub_path) orelse {
            //                     dumpBadDirnameHelp(null, null,
            //                         \\dirname() attempted to traverse outside the dependency root.
            //                         \\
            //                     , .{}) catch {};
            //                     @panic("misconfigured build script");
            //                 },
            //             } },
            //         };
            //     }
            //
            //     pub fn path(lazy_path: LazyPath, b: *Build, sub_path: []const u8) LazyPath {
            //         return lazy_path.join(b.allocator, sub_path) catch @panic("OOM");
            //     }
            //
            //     pub fn join(lazy_path: LazyPath, arena: Allocator, sub_path: []const u8) Allocator.Error!LazyPath {
            //         return switch (lazy_path) {
            //             .src_path => |src| .{ .src_path = .{
            //                 .owner = src.owner,
            //                 .sub_path = try fs.path.resolve(arena, &.{ src.sub_path, sub_path }),
            //             } },
            //             .generated => |gen| .{ .generated = .{
            //                 .file = gen.file,
            //                 .up = gen.up,
            //                 .sub_path = try fs.path.resolve(arena, &.{ gen.sub_path, sub_path }),
            //             } },
            //             .cwd_relative => |cwd_relative| .{
            //                 .cwd_relative = try fs.path.resolve(arena, &.{ cwd_relative, sub_path }),
            //             },
            //             .dependency => |dep| .{ .dependency = .{
            //                 .dependency = dep.dependency,
            //                 .sub_path = try fs.path.resolve(arena, &.{ dep.sub_path, sub_path }),
            //             } },
            //         };
            //     }
            //
            //     pub fn getDisplayName(lazy_path: LazyPath) []const u8 {
            //         return switch (lazy_path) {
            //             .src_path => |sp| sp.sub_path,
            //             .cwd_relative => |p| p,
            //             .generated => "generated",
            //             .dependency => "dependency",
            //         };
            //     }
            //
            //     pub fn addStepDependencies(lazy_path: LazyPath, other_step: *Step) void {
            //         switch (lazy_path) {
            //             .src_path, .cwd_relative, .dependency => {},
            //             .generated => |gen| other_step.dependOn(gen.file.step),
            //         }
            //     }
            //
            //     pub fn getPath(lazy_path: LazyPath, src_builder: *Build) []const u8 {
            //         return getPath2(lazy_path, src_builder, null);
            //     }
            //
            //     pub fn getPath2(lazy_path: LazyPath, src_builder: *Build, asking_step: ?*Step) []const u8 {
            //         const p = getPath3(lazy_path, src_builder, asking_step);
            //         return src_builder.pathResolve(&.{ p.root_dir.path orelse ".", p.sub_path });
            //     }
            //
            //     pub fn getPath3(lazy_path: LazyPath, src_builder: *Build, asking_step: ?*Step) Cache.Path {
            //         switch (lazy_path) {
            //             .src_path => |sp| return .{
            //                 .root_dir = sp.owner.build_root,
            //                 .sub_path = sp.sub_path,
            //             },
            //             .cwd_relative => |sub_path| return .{
            //                 .root_dir = Cache.Directory.cwd(),
            //                 .sub_path = sub_path,
            //             },
            //             .generated => |gen| {
            //
            //                 var file_path: Cache.Path = .{
            //                     .root_dir = Cache.Directory.cwd(),
            //                     .sub_path = gen.file.path orelse {
            //                         const w = debug.lockStderrWriter(&.{});
            //                         dumpBadGetPathHelp(gen.file.step, w, .detect(.stderr()), src_builder, asking_step) catch {};
            //                         debug.unlockStderrWriter();
            //                         @panic("misconfigured build script");
            //                     },
            //                 };
            //
            //                 if (gen.up > 0) {
            //                     const cache_root_path = src_builder.cache_root.path orelse
            //                         (src_builder.cache_root.join(src_builder.allocator, &.{"."}) catch @panic("OOM"));
            //
            //                     for (0..gen.up) |_| {
            //                         if (mem.eql(u8, file_path.sub_path, cache_root_path)) {
            //                             dumpBadDirnameHelp(gen.file.step, asking_step,
            //                                 \\dirname() attempted to traverse outside the cache root.
            //                                 \\This is not allowed.
            //                                 \\
            //                             , .{}) catch {};
            //                             @panic("misconfigured build script");
            //                         }
            //
            //                         file_path.sub_path = fs.path.dirname(file_path.sub_path) orelse {
            //                             dumpBadDirnameHelp(gen.file.step, asking_step,
            //                                 \\dirname() reached root.
            //                                 \\No more directories left to go up.
            //                                 \\
            //                             , .{}) catch {};
            //                             @panic("misconfigured build script");
            //                         };
            //                     }
            //                 }
            //
            //                 return file_path.join(src_builder.allocator, gen.sub_path) catch @panic("OOM");
            //             },
            //             .dependency => |dep| return .{
            //                 .root_dir = dep.dependency.builder.build_root,
            //                 .sub_path = dep.sub_path,
            //             },
            //         }
            //     }
            //
            //     pub fn basename(lazy_path: LazyPath, src_builder: *Build, asking_step: ?*Step) []const u8 {
            //         return fs.path.basename(switch (lazy_path) {
            //             .src_path => |sp| sp.sub_path,
            //             .cwd_relative => |sub_path| sub_path,
            //             .generated => |gen| if (gen.sub_path.len > 0)
            //                 gen.sub_path
            //             else
            //                 gen.file.getPath2(src_builder, asking_step),
            //             .dependency => |dep| dep.sub_path,
            //         });
            //     }
            //
            //     pub fn dupe(lazy_path: LazyPath, b: *Build) LazyPath {
            //         return lazy_path.dupeInner(b.allocator);
            //     }
            //
            //     fn dupeInner(lazy_path: LazyPath, allocator: std.mem.Allocator) LazyPath {
            //         return switch (lazy_path) {
            //             .src_path => |sp| .{ .src_path = .{
            //                 .owner = sp.owner,
            //                 .sub_path = sp.owner.dupePath(sp.sub_path),
            //             } },
            //             .cwd_relative => |p| .{ .cwd_relative = dupePathInner(allocator, p) },
            //             .generated => |gen| .{ .generated = .{
            //                 .file = gen.file,
            //                 .up = gen.up,
            //                 .sub_path = dupePathInner(allocator, gen.sub_path),
            //             } },
            //             .dependency => |dep| .{ .dependency = .{
            //                 .dependency = dep.dependency,
            //                 .sub_path = dupePathInner(allocator, dep.sub_path),
            //             } },
            //         };
            //     }
            // };
            //
            // WOW that's a lot of code... But I guess we should start with what a union(enum) is,
            // Since that's what this whole thing is to begin with... After reading what an enum
            // is in the ziglang.org/documentation, it seems that enums have similar properties
            // as C++ (the language I'm most familiar with). However, it seems enums can have
            // methods that are namespaced functions that are called with dot syntax, as well as
            // much more baked in functionality. I like it, and it seems real cool. It seems that
            // enums are also not compatible with C ABI unless you do enum(c_int), where c_int is
            // a C type primitive guaranteed to have C ABI compatibility. I've never used unions
            // in C++, and the zig documentation expects you already know what a union is. So here
            // is my definition of what a union is after looking it up: A union is like a struct,
            // but the address of each member in the "union" live at the same address, they share
            // the same address in memory, this means that changes to one member in the union
            // affects all members in the union and the size of the union is the largest member
            // of the union. It looks like a "tagged" union is declared with an enum tag type. But,
            // what's a tag? An enum "tag" type has to do with meta data that zig stores for what
            // the current object is right now? Not sure, I'll figure this out later. What I
            // understand currently is when you do 'const Value = enum(u2)', u2 is the 'tag type',
            // and in this context it seems 'tag type' is the value type of each enum, being u2.
            // Tags are the types within the parenthesis, so in the context of a tagged union,
            // we have from the reference material "Unions can be declared with an enum tag type.
            // This turns the union into a tagged union, which makes it eligible to use with switch
            // expressions. Tagged unions coerce to their tag type."  Instead of actually reading
            // all of the LazyPath things, let's just assume for now that it figures out the
            // OS, relative/absolute path, and current directory in relation to the previous 2
            // assumptions. Let's look at what path() does. It seems that path() references a file
            // or directory relative to the source root. Therefore, it's just a file path in our
            // current project, stored as a LazyPath union(enum) object. Simple enough.
            .target = b.graph.host,
            // now, target resolves as either a std.Build.ResolvedTarget, or as null. The
            // ResolvedTarget is a pair of target queries and a fully resolved target. This type is
            // generally required by the build system API that need to be given a target. The query
            // is kept because the Zig toolchain needs to know which parts of the targets are
            // "native". This can apply to the CPU, the OS, or even the underlying ABI. Below is
            // the struct:
            // pub const ResolvedTarget = struct {
            //     query: Target.Query,
            //     result: Target,
            // };
            // Setting it as b.graph.host means it gets the current host as the target, but this
            // also means we can specify many different targets in case we want to be able to
            // specifically target different platforms.
        }),
    });
    // LLO: Start here, make sure to go through the Step.Compile return type, and
    // Now let's rewind time because we forgot that the .create function was called in the beginning
    // What is this doing? Below is what it is doing...
    // The underlying function addExecutable() is this function below:
    // pub fn addExecutable(b: *Build, options: ExecutableOptions) *Step.Compile {
    //     return .create(b, .{
    //         .name = options.name,
    //         .root_module = options.root_module,
    //         .version = options.version,
    //         .kind = .exe,
    //         .linkage = options.linkage,
    //         .max_rss = options.max_rss,
    //         .use_llvm = options.use_llvm,
    //         .use_lld = options.use_lld,
    //         .zig_lib_dir = options.zig_lib_dir,
    //         .win32_manifest = options.win32_manifest,
    //     });
    // }
    //
    // Since the first part is a return .create(b, .{ ... });, focusing on the b section, I think
    // begining the exe = b.addExecutable is implying that the first argument is just passing
    // itself, and we only need to then focus on the Executable options struct below.
    // pub const ExecutableOptions = struct {
    //     name: []const u8,
    //     root_module: *Module,
    //     version: ?std.SemanticVersion = null,
    //     linkage: ?std.builtin.LinkMode = null,
    //     max_rss: usize = 0,
    //     use_llvm: ?bool = null,
    //     use_lld: ?bool = null,
    //     zig_lib_dir: ?LazyPath = null,
    //     /// Embed a `.manifest` file in the compilation if the object format supports it.
    //     /// https://learn.microsoft.com/en-us/windows/win32/sbscs/manifest-files-reference
    //     /// Manifest files must have the extension `.manifest`.
    //     /// Can be set regardless of target. The `.manifest` file will be ignored
    //     /// if the target object format does not support embedded manifests.
    //     win32_manifest: ?LazyPath = null,
    // };
    //
    // Additionally, Since we are returning a *Step.Compile, and we are calling the .create
    // function, we can safely assume that this .create function is actually coming from
    // /usr/lib/zig/std/Build/Step/Compile.zig. This function is below:
    //
    // pub fn create(owner: *std.Build, options: Options) *Compile {
    //     const name = owner.dupe(options.name);
    //     if (mem.indexOf(u8, name, "/") != null or mem.indexOf(u8, name, "\\") != null) {
    //         panic("invalid name: '{s}'. It looks like a file path, but it is supposed to be the library or application name.", .{name});
    //     }
    //
    //     const resolved_target = options.root_module.resolved_target orelse
    //         @panic("the root Module of a Compile step must be created with a known 'target' field");
    //     const target = &resolved_target.result;
    //
    //     const step_name = owner.fmt("compile {s} {s} {s}", .{
    //         // Avoid the common case of the step name looking like "compile test test".
    //         if (options.kind.isTest() and mem.eql(u8, name, "test"))
    //             @tagName(options.kind)
    //         else
    //             owner.fmt("{s} {s}", .{ @tagName(options.kind), name }),
    //         @tagName(options.root_module.optimize orelse .Debug),
    //         resolved_target.query.zigTriple(owner.allocator) catch @panic("OOM"),
    //     });
    //
    //     const out_filename = std.zig.binNameAlloc(owner.allocator, .{
    //         .root_name = name,
    //         .target = target,
    //         .output_mode = switch (options.kind) {
    //             .lib => .Lib,
    //             .obj, .test_obj => .Obj,
    //             .exe, .@"test" => .Exe,
    //         },
    //         .link_mode = options.linkage,
    //         .version = options.version,
    //     }) catch @panic("OOM");
    //
    //     const compile = owner.allocator.create(Compile) catch @panic("OOM");
    //     compile.* = .{
    //         .root_module = options.root_module,
    //         .verbose_link = false,
    //         .verbose_cc = false,
    //         .linkage = options.linkage,
    //         .kind = options.kind,
    //         .name = name,
    //         .step = .init(.{
    //             .id = base_id,
    //             .name = step_name,
    //             .owner = owner,
    //             .makeFn = make,
    //             .max_rss = options.max_rss,
    //         }),
    //         .version = options.version,
    //         .out_filename = out_filename,
    //         .out_lib_filename = undefined,
    //         .major_only_filename = null,
    //         .name_only_filename = null,
    //         .installed_headers = std.array_list.Managed(HeaderInstallation).init(owner.allocator),
    //         .zig_lib_dir = null,
    //         .exec_cmd_args = null,
    //         .filters = options.filters,
    //         .test_runner = null, // set below
    //         .rdynamic = false,
    //         .installed_path = null,
    //         .force_undefined_symbols = StringHashMap(void).init(owner.allocator),
    //
    //         .emit_directory = null,
    //         .generated_docs = null,
    //         .generated_asm = null,
    //         .generated_bin = null,
    //         .generated_pdb = null,
    //         .generated_implib = null,
    //         .generated_llvm_bc = null,
    //         .generated_llvm_ir = null,
    //         .generated_h = null,
    //
    //         .use_llvm = options.use_llvm,
    //         .use_lld = options.use_lld,
    //
    //         .zig_process = null,
    //     };
    //
    //     if (options.zig_lib_dir) |lp| {
    //         compile.zig_lib_dir = lp.dupe(compile.step.owner);
    //         lp.addStepDependencies(&compile.step);
    //     }
    //
    //     if (options.test_runner) |runner| {
    //         compile.test_runner = .{
    //             .path = runner.path.dupe(compile.step.owner),
    //             .mode = runner.mode,
    //         };
    //         runner.path.addStepDependencies(&compile.step);
    //     }
    //
    //     // Only the PE/COFF format has a Resource Table which is where the manifest
    //     // gets embedded, so for any other target the manifest file is just ignored.
    //     if (target.ofmt == .coff) {
    //         if (options.win32_manifest) |lp| {
    //             compile.win32_manifest = lp.dupe(compile.step.owner);
    //             lp.addStepDependencies(&compile.step);
    //         }
    //     }
    //
    //     if (compile.kind == .lib) {
    //         if (compile.linkage != null and compile.linkage.? == .static) {
    //             compile.out_lib_filename = compile.out_filename;
    //         } else if (compile.version) |version| {
    //             if (target.os.tag.isDarwin()) {
    //                 compile.major_only_filename = owner.fmt("lib{s}.{d}.dylib", .{
    //                     compile.name,
    //                     version.major,
    //                 });
    //                 compile.name_only_filename = owner.fmt("lib{s}.dylib", .{compile.name});
    //                 compile.out_lib_filename = compile.out_filename;
    //             } else if (target.os.tag == .windows) {
    //                 compile.out_lib_filename = owner.fmt("{s}.lib", .{compile.name});
    //             } else {
    //                 compile.major_only_filename = owner.fmt("lib{s}.so.{d}", .{ compile.name, version.major });
    //                 compile.name_only_filename = owner.fmt("lib{s}.so", .{compile.name});
    //                 compile.out_lib_filename = compile.out_filename;
    //             }
    //         } else {
    //             if (target.os.tag.isDarwin()) {
    //                 compile.out_lib_filename = compile.out_filename;
    //             } else if (target.os.tag == .windows) {
    //                 compile.out_lib_filename = owner.fmt("{s}.lib", .{compile.name});
    //             } else {
    //                 compile.out_lib_filename = compile.out_filename;
    //             }
    //         }
    //     }
    //
    //     return compile;
    // }
    //
    // The options which we cover in this file are: .name and .root_module.
    // These are defined in the Options struct located /usr/lib/zig/Build/Step/Compile.zig file. Below
    // is the struct that's defined:
    //
    // pub const Options = struct {
    //     name: []const u8,
    //     root_module: *Module,
    //     kind: Kind,
    //     linkage: ?std.builtin.LinkMode = null,
    //     version: ?std.SemanticVersion = null,
    //     max_rss: usize = 0,
    //     filters: []const []const u8 = &.{},
    //     test_runner: ?TestRunner = null,
    //     use_llvm: ?bool = null,
    //     use_lld: ?bool = null,
    //     zig_lib_dir: ?LazyPath = null,
    //     /// Embed a `.manifest` file in the compilation if the object format supports it.
    //     /// https://learn.microsoft.com/en-us/windows/win32/sbscs/manifest-files-reference
    //     /// Manifest files must have the extension `.manifest`.
    //     /// Can be set regardless of target. The `.manifest` file will be ignored
    //     /// if the target object format does not support embedded manifests.
    //     win32_manifest: ?LazyPath = null,
    // };
    //
    // As you can see, name is just a string, root_module is the module we created
    // via b.createModule. It's actually within the createModule that we use the other 2
    // variables that we've defined: .root_source_file, and .target. These come from the
    // CreateOptions struct below:
    //
    // /// Unspecified options here will be inherited from parent `Module` when
    // /// inserted into an import table.
    // pub const CreateOptions = struct {
    //     /// This could either be a generated file, in which case the module
    //     /// contains exactly one file, or it could be a path to the root source
    //     /// file of directory of files which constitute the module.
    //     /// If `null`, it means this module is made up of only `link_objects`.
    //     root_source_file: ?LazyPath = null,
    //
    //     /// The table of other modules that this module can access via `@import`.
    //     /// Imports are allowed to be cyclical, so this table can be added to after
    //     /// the `Module` is created via `addImport`.
    //     imports: []const Import = &.{},
    //
    //     target: ?std.Build.ResolvedTarget = null,
    //     optimize: ?std.builtin.OptimizeMode = null,
    //
    //     /// `true` requires a compilation that includes this Module to link libc.
    //     /// `false` causes a build failure if a compilation that includes this Module would link libc.
    //     /// `null` neither requires nor prevents libc from being linked.
    //     link_libc: ?bool = null,
    //     /// `true` requires a compilation that includes this Module to link libc++.
    //     /// `false` causes a build failure if a compilation that includes this Module would link libc++.
    //     /// `null` neither requires nor prevents libc++ from being linked.
    //     link_libcpp: ?bool = null,
    //     single_threaded: ?bool = null,
    //     strip: ?bool = null,
    //     unwind_tables: ?std.builtin.UnwindTables = null,
    //     dwarf_format: ?std.dwarf.Format = null,
    //     code_model: std.builtin.CodeModel = .default,
    //     stack_protector: ?bool = null,
    //     stack_check: ?bool = null,
    //     sanitize_c: ?std.zig.SanitizeC = null,
    //     sanitize_thread: ?bool = null,
    //     fuzz: ?bool = null,
    //     /// Whether to emit machine code that integrates with Valgrind.
    //     valgrind: ?bool = null,
    //     /// Position Independent Code
    //     pic: ?bool = null,
    //     red_zone: ?bool = null,
    //     /// Whether to omit the stack frame pointer. Frees up a register and makes it
    //     /// more difficult to obtain stack traces. Has target-dependent effects.
    //     omit_frame_pointer: ?bool = null,
    //     error_tracing: ?bool = null,
    //     no_builtin: ?bool = null,
    // };

    b.installArtifact(exe);
    // Finally the last thing we do is pass our well defined exe into the installArtifact function.
    // /// This creates the install step and adds it to the dependencies of the
    // /// top-level install step, using all the default options.
    // /// See `addInstallArtifact` for a more flexible function.
    // pub fn installArtifact(b: *Build, artifact: *Step.Compile) void {
    //     b.getInstallStep().dependOn(&b.addInstallArtifact(artifact, .{}).step);
    // }
    //
    // What this does is pass it into the addInstallArtifact below:
    // pub fn addInstallArtifact(
    //     b: *Build,
    //     artifact: *Step.Compile,
    //     options: Step.InstallArtifact.Options,
    // ) *Step.InstallArtifact {
    //     return Step.InstallArtifact.create(b, artifact, options);
    // }
    //
    // Then this create function is in /usr/lib/zig/Build/Step/InstallArtifact.zig below:
    //
    // pub fn create(owner: *std.Build, artifact: *Step.Compile, options: Options) *InstallArtifact {
    //     const install_artifact = owner.allocator.create(InstallArtifact) catch @panic("OOM");
    //     const dest_dir: ?InstallDir = switch (options.dest_dir) {
    //         .disabled => null,
    //         .default => switch (artifact.kind) {
    //             .obj, .test_obj => @panic("object files have no standard installation procedure"),
    //             .exe, .@"test" => .bin,
    //             .lib => if (artifact.isDll()) .bin else .lib,
    //         },
    //         .override => |o| o,
    //     };
    //     install_artifact.* = .{
    //         .step = Step.init(.{
    //             .id = base_id,
    //             .name = owner.fmt("install {s}", .{artifact.name}),
    //             .owner = owner,
    //             .makeFn = make,
    //         }),
    //         .dest_dir = dest_dir,
    //         .pdb_dir = switch (options.pdb_dir) {
    //             .disabled => null,
    //             .default => if (artifact.producesPdbFile()) dest_dir else null,
    //             .override => |o| o,
    //         },
    //         .h_dir = switch (options.h_dir) {
    //             .disabled => null,
    //             .default => if (artifact.kind == .lib) .header else null,
    //             .override => |o| o,
    //         },
    //         .implib_dir = switch (options.implib_dir) {
    //             .disabled => null,
    //             .default => if (artifact.producesImplib()) .lib else null,
    //             .override => |o| o,
    //         },
    //
    //         .dylib_symlinks = if (options.dylib_symlinks orelse (dest_dir != null and
    //             artifact.isDynamicLibrary() and
    //             artifact.version != null and
    //             std.Build.wantSharedLibSymLinks(artifact.rootModuleTarget()))) .{
    //             .major_only_filename = artifact.major_only_filename.?,
    //             .name_only_filename = artifact.name_only_filename.?,
    //         } else null,
    //
    //         .dest_sub_path = options.dest_sub_path orelse artifact.out_filename,
    //
    //         .emitted_bin = null,
    //         .emitted_pdb = null,
    //         .emitted_h = null,
    //         .emitted_implib = null,
    //
    //         .artifact = artifact,
    //     };
    //
    //     install_artifact.step.dependOn(&artifact.step);
    //
    //     if (install_artifact.dest_dir != null) install_artifact.emitted_bin = artifact.getEmittedBin();
    //     if (install_artifact.pdb_dir != null) install_artifact.emitted_pdb = artifact.getEmittedPdb();
    //     // https://github.com/ziglang/zig/issues/9698
    //     //if (install_artifact.h_dir != null) install_artifact.emitted_h = artifact.getEmittedH();
    //     if (install_artifact.implib_dir != null) install_artifact.emitted_implib = artifact.getEmittedImplib();
    //
    //     return install_artifact;
    // }
}
