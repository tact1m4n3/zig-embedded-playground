const root = @import("root");
const hal = @import("../hal.zig");

const stack_top: usize = 0x20_040_000;
const vector_table: hal.chip.VectorTable = .{
    .initial_stack_pointer = stack_top,
    .Reset = _start,
};

comptime {
    @export(&vector_table, .{
        .name = "_vector_table",
        .section = ".vector_table",
        .linkage = .strong,
    });
}

pub const sections = struct {
    extern var _data_start: anyopaque;
    extern var _data_end: anyopaque;
    extern var _bss_start: anyopaque;
    extern var _bss_end: anyopaque;
    extern const _data_load_start: anyopaque;
};

pub export fn _start() callconv(.C) void {
    // fill .bss with zeroes
    {
        const bss_start: [*]u8 = @ptrCast(&sections._bss_start);
        const bss_end: [*]u8 = @ptrCast(&sections._bss_end);
        const bss_len = @intFromPtr(bss_end) - @intFromPtr(bss_start);

        @memset(bss_start[0..bss_len], 0);
    }

    // load .data from flash
    {
        const data_start: [*]u8 = @ptrCast(&sections._data_start);
        const data_end: [*]u8 = @ptrCast(&sections._data_end);
        const data_len = @intFromPtr(data_end) - @intFromPtr(data_start);
        const data_src: [*]const u8 = @ptrCast(&sections._data_load_start);

        @memcpy(data_start[0..data_len], data_src[0..data_len]);
    }

    root.main() catch unreachable;
}
