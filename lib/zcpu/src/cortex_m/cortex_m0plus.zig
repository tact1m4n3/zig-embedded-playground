const root = @import("../root.zig");

pub const MAX_INTERRUPTS: usize = 32;

pub const exceptions: []const root.Interrupt = &.{
    .{ .name = "NMI", .index = -14 },
    .{ .name = "HardFault", .index = -13 },
    .{ .name = "SVCall", .index = -5 },
    .{ .name = "PendSV", .index = -2 },
    .{ .name = "SysTick", .index = -1 },
};
