const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    _ = target; // autofix
    const optimize = b.standardOptimizeOption(.{});

    const zcpu_dep = b.dependency("zcpu", .{
        .optimize = optimize,
        .cpu = .cortex_m0plus,
    });

    const zcpu_mod = zcpu_dep.module("zcpu");

    const firmware = b.addExecutable(.{
        .name = "toto-flight",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .optimize = optimize,
            .target = b.resolveTargetQuery(.{
                .cpu_arch = .thumb,
                .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m0plus },
                .os_tag = .freestanding,
                .abi = .eabi,
            }),
        }),
    });
    firmware.root_module.addImport("zcpu", zcpu_mod);
    firmware.setLinkerScript(b.path("rp2040.ld"));

    b.installArtifact(firmware);
}
