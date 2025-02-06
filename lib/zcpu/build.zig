const std = @import("std");
pub const CpuKind = @import("src/cpu_kind.zig").CpuKind;

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    const cpu_kind = b.option(CpuKind, "cpu", "cpu kind") orelse @panic("`cpu` option required");

    const options = b.addOptions();
    options.addOption(CpuKind, "cpu_kind", cpu_kind);

    const zcpu_mod = b.addModule("zcpu", .{
        .root_source_file = b.path("src/root.zig"),
        .optimize = optimize,
    });
    zcpu_mod.addOptions("options", options);
}
