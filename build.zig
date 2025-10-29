const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Library
    const lib = b.addStaticLibrary(.{
        .name = "zxb",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(lib);

    // Module for other projects to use
    const zxb_module = b.addModule("zxb", .{
        .root_source_file = b.path("src/main.zig"),
    });

    // Tests
    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);

    // Example
    const example = b.addExecutable(.{
        .name = "example",
        .root_source_file = b.path("examples/basic.zig"),
        .target = target,
        .optimize = optimize,
    });
    example.root_module.addImport("zxb", zxb_module);

    const run_example = b.addRunArtifact(example);
    const example_step = b.step("example", "Run example");
    example_step.dependOn(&run_example.step);

    // Database usage example
    const db_example = b.addExecutable(.{
        .name = "database_usage",
        .root_source_file = b.path("examples/database_usage.zig"),
        .target = target,
        .optimize = optimize,
    });
    db_example.root_module.addImport("zxb", zxb_module);

    const run_db_example = b.addRunArtifact(db_example);
    const db_example_step = b.step("db-example", "Run database usage example");
    db_example_step.dependOn(&run_db_example.step);

    // Build method example
    const build_example = b.addExecutable(.{
        .name = "build_method",
        .root_source_file = b.path("examples/build_method.zig"),
        .target = target,
        .optimize = optimize,
    });
    build_example.root_module.addImport("zxb", zxb_module);

    const run_build_example = b.addRunArtifact(build_example);
    const build_example_step = b.step("build-example", "Run build() method example");
    build_example_step.dependOn(&run_build_example.step);
}
