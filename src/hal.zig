pub const cpu = @import("hal/cpu.zig");

pub const regs = @import("hal/regs.zig");
pub const types = regs.types;
pub const peripherals = regs.devices.RP2040;
