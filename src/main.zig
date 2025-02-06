const zcpu = @import("zcpu");
comptime {
    zcpu.setup(.{
        .initial_stack_pointer = 0x20_040_000,
    });
}

pub fn main() !void {}
