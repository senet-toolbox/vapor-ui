const std = @import("std");
const vapor = @import("vapor");

/// What every build of the app shares, whatever its target.
const AppOptions = struct {
    static: bool,
    atomic: bool,
    build_options: *std.Build.Module,
};

const App = struct {
    vapor_dep: *std.Build.Dependency,
    imports: []const std.Build.Module.Import,
};

/// Wired builds, one per target and optimize mode: `b.dependency` hands out
/// the same vapor module for the same arguments, so wiring it twice would
/// give it two `theme` imports.
var wired: std.ArrayList(struct { arch: std.Target.Cpu.Arch, optimize: std.builtin.OptimizeMode, app: App }) = .empty;

/// The app's modules for `target`: vapor with the app's config and theme,
/// vaporize, opaque-ui and keystone.
fn app(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, options: AppOptions) App {
    const arch = target.result.cpu.arch;
    for (wired.items) |w| {
        if (w.arch == arch and w.optimize == optimize) return w.app;
    }
    const wired_app = wire(b, target, optimize, options);
    wired.append(b.allocator, .{ .arch = arch, .optimize = optimize, .app = wired_app }) catch @panic("OOM");
    return wired_app;
}

fn wire(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, options: AppOptions) App {
    const config_module = b.createModule(.{
        .root_source_file = b.path("src/config.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Vapor — core framework
    const vapor_dep = b.dependency("vapor", .{
        .target = target,
        .optimize = optimize,
        .static = options.static,
        .atomic = options.atomic,
    });
    const vapor_module = vapor_dep.module("vapor");
    vapor_module.addImport("config", config_module);

    // Theme — styling layer (depends on vapor)
    const theme_module = b.createModule(.{
        .root_source_file = b.path("src/Theme.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "vapor", .module = vapor_module },
        },
    });
    vapor_module.addImport("theme", theme_module);

    // Vaporize — utility layer (depends on vapor)
    const vaporize_module = b.dependency("vaporize", .{
        .target = target,
        .optimize = optimize,
    }).module("vaporize");
    vaporize_module.addImport("vapor", vapor_module);

    // Opaque UI — component library (depends on vapor, theme, config)
    const opaque_ui_module = b.dependency("opaque_ui", .{
        .target = target,
        .optimize = optimize,
    }).module("opaque_ui");
    opaque_ui_module.addImport("vapor", vapor_module);
    opaque_ui_module.addImport("theme", theme_module);
    opaque_ui_module.addImport("config", config_module);

    return .{
        .vapor_dep = vapor_dep,
        .imports = b.allocator.dupe(std.Build.Module.Import, &.{
            .{ .name = "vapor", .module = vapor_module },
            .{ .name = "theme", .module = theme_module },
            .{ .name = "config", .module = config_module },
            .{ .name = "vaporize", .module = vaporize_module },
            .{ .name = "opaque-ui", .module = opaque_ui_module },
            .{ .name = "keystone", .module = vapor_dep.module("keystone") },
            .{ .name = "build_options", .module = options.build_options },
        }) catch @panic("OOM"),
    };
}

/// The app's wasm, as the runtime loads it: no entry point, every export kept.
fn wasmExe(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, options: AppOptions) *std.Build.Step.Compile {
    const exe = b.addExecutable(.{
        .name = "vapor",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = app(b, target, optimize, options).imports,
        }),
    });
    exe.entry = .disabled;
    exe.rdynamic = true;
    return exe;
}

/// Prerenders every page into release/ (src/generator.zig), on the host.
fn generator(b: *std.Build, options: AppOptions) *std.Build.Step.Compile {
    const host = b.graph.host;
    return b.addExecutable(.{
        .name = "generator",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/generator.zig"),
            .target = host,
            .optimize = .Debug,
            .imports = app(b, host, .Debug, options).imports,
        }),
    });
}

pub fn build(b: *std.Build) void {
    // ---------------------
    //  Build options
    // ---------------------
    const generate = b.option(bool, "generate", "Generate HTML") orelse false;
    const static = b.option(bool, "static", "Statically link the wasm module") orelse false;
    const atomic = b.option(bool, "atomic", "Atomically link the wasm module") orelse false;
    const backend_base_url = b.option([]const u8, "backend_base_url", "Backend base URL for client fetches (e.g. http://localhost:8080, https://api.example.com, or empty for same-origin)") orelse "http://localhost:8080";
    const optimize = b.standardOptimizeOption(.{});

    const wasm_target = b.standardTargetOptions(.{
        .default_target = .{ .cpu_arch = .wasm32, .os_tag = .wasi },
    });

    const build_options = b.addOptions();
    build_options.addOption([]const u8, "backend_base_url", backend_base_url);
    const options: AppOptions = .{
        .static = static,
        .atomic = atomic,
        .build_options = build_options.createModule(),
    };

    // ---------------------
    //  Executable
    // ---------------------
    const exe = wasmExe(b, wasm_target, optimize, options);
    const vapor_dep = app(b, wasm_target, optimize, options).vapor_dep;

    // ---------------------
    //  Memory stack size
    // ---------------------
    // exe.stack_size = 4 * 1024 * 1024;

    b.installArtifact(exe);
    b.getInstallStep().dependOn(&b.addInstallBinFile(vapor_dep.namedLazyPath("runtime"), "bundle.min.js").step);
    b.getInstallStep().dependOn(&b.addInstallBinFile(vapor_dep.namedLazyPath("runtime-browser"), "browser.min.js").step);

    // ---------------------
    //  Check step
    // ---------------------
    // Compiles every example the pages show as code (src/check_examples.zig).
    const check_obj = b.addObject(.{
        .name = "check-examples",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/check_examples.zig"),
            .target = wasm_target,
            .optimize = optimize,
            .imports = app(b, wasm_target, optimize, options).imports,
        }),
    });
    const check_step = b.step("check", "Compile every example the pages show");
    check_step.dependOn(&check_obj.step);

    // ---------------------
    //  Interaction tests
    // ---------------------
    // Builds the site, then drives every component page in headless Chrome
    // (tests/run.mjs; needs Node >= 22 and Chrome). Pass a name to run only
    // the tests whose name contains it: zig build test-ui -- slider
    const run_ui_tests = b.addSystemCommand(&.{ "node", "tests/run.mjs" });
    run_ui_tests.step.dependOn(b.getInstallStep());
    run_ui_tests.has_side_effects = true;
    if (b.args) |args| run_ui_tests.addArgs(args);
    const test_ui_step = b.step("test-ui", "Run the component interaction tests in headless Chrome");
    test_ui_step.dependOn(&run_ui_tests.step);

    // ---------------------
    //  Run step
    // ---------------------
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Optional: wire up the HTML generator before compilation
    if (generate) {
        exe.step.dependOn(&b.addRunArtifact(generator(b, options)).step);
    }

    // ---------------------
    //  Release
    // ---------------------
    // The site to deploy, in release/: the ReleaseSmall wasm and the runtime
    // under names that change with their contents, so the host can cache
    // them forever (see addRelease in vapor's build.zig). Client-rendered
    // from one index.html; -Dgenerate=true prerenders every page as well.
    const release_step = b.step("release", "Build the site to deploy into release/ (-Dgenerate=true to prerender)");
    release_step.dependOn(vapor.addRelease(b, vapor_dep, .{
        .wasm = wasmExe(b, wasm_target, .ReleaseSmall, options),
        .generate = if (generate) b.addRunArtifact(generator(b, options)) else null,
        .copy = &.{"robots.txt"},
    }));

    // The interaction tests against release/, served as a static host would.
    const run_release_tests = b.addSystemCommand(&.{ "node", "tests/run.mjs", "--release" });
    run_release_tests.step.dependOn(release_step);
    run_release_tests.has_side_effects = true;
    if (b.args) |args| run_release_tests.addArgs(args);
    const test_release_step = b.step("test-release", "Build the release, then run the interaction tests against it");
    test_release_step.dependOn(&run_release_tests.step);
}
