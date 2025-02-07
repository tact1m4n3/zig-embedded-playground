const root = @import("root");
const builtin = @import("builtin");
const std = @import("std");

const options = @import("options");
const cpu_kind = options.cpu_kind;

pub const SetupConfig = struct {
    initial_stack_pointer: usize,
    linker: LinkerConfig = .{},
    interrupts: []const Interrupt = &.{},
};

pub const LinkerConfig = struct {
    flash_start_section: []const u8 = ".flash_start",
    bss_start_symbol: []const u8 = "_bss_start",
    bss_end_symbol: []const u8 = "_bss_end",
    data_start_symbol: []const u8 = "_data_start",
    data_end_symbol: []const u8 = "_data_end",
    data_load_start_symbol: []const u8 = "_data_load_start",
};

pub const Interrupt = struct {
    name: [:0]const u8,
    index: isize,
};

const impl = switch (cpu_kind) {
    .cortex_m0plus => @import("cortex_m.zig"),
};

pub fn setup(comptime config: SetupConfig) void {
    impl.setup(config);
}

pub fn zcpu_main() callconv(.C) void {
    if (!@hasDecl(root, "main")) {
        @compileError("main function not defined");
    }
    const main = root.main;

    const main_info = @typeInfo(@TypeOf(main));
    const invalid_main_msg = "main must be either 'pub fn main() void' or 'pub fn main() !void'.";
    if (main_info != .@"fn" or main_info.@"fn".params.len > 0)
        @compileError(invalid_main_msg);

    const return_type = main_info.@"fn".return_type orelse @compileError(invalid_main_msg);

    if (@typeInfo(return_type) == .error_union) {
        main() catch |err| {
            if (builtin.strip_debug_info) {
                @panic("main() returned error");
            } else {
                var msg: [64]u8 = undefined;
                @panic(std.fmt.bufPrint(&msg, "main() returned error {s}", .{@errorName(err)}) catch @panic("main() returned error"));
            }
        };
    } else {
        main();
    }
}

pub fn initialize_memory(comptime config: LinkerConfig) void {
    const symbols = struct {
        pub var bss_start = @extern(*const anyopaque, .{ .name = config.bss_start_symbol });
        pub var bss_end = @extern(*const anyopaque, .{ .name = config.bss_end_symbol });
        pub var data_start = @extern(*const anyopaque, .{ .name = config.data_start_symbol });
        pub var data_end = @extern(*const anyopaque, .{ .name = config.data_end_symbol });
        pub const data_load_start = @extern(*const anyopaque, .{ .name = config.data_load_start_symbol });
    };

    // fill .bss with zeroes
    {
        const bss_start: [*]u8 = @ptrCast(&symbols.bss_start);
        const bss_end: [*]u8 = @ptrCast(&symbols.bss_end);
        const bss_len = @intFromPtr(bss_end) - @intFromPtr(bss_start);

        @memset(bss_start[0..bss_len], 0);
    }

    // load .data from flash
    {
        const data_start: [*]u8 = @ptrCast(&symbols.data_start);
        const data_end: [*]u8 = @ptrCast(&symbols.data_end);
        const data_len = @intFromPtr(data_end) - @intFromPtr(data_start);
        const data_src: [*]const u8 = @ptrCast(&symbols.data_load_start);

        @memcpy(data_start[0..data_len], data_src[0..data_len]);
    }
}
