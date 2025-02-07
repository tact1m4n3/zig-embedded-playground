const std = @import("std");
const root = @import("root.zig");

const options = @import("options");
const cpu_kind = options.cpu_kind;

const impl = switch (cpu_kind) {
    .cortex_m0plus => @import("cortex_m/cortex_m0plus.zig"),
};

const Interrupt = root.Interrupt;
const InterruptHandler = *const fn () callconv(.C) void;
fn unhandled_interrupt() callconv(.C) void {
    @panic("unhandled interrupt");
}

pub fn setup(comptime config: root.SetupConfig) void {
    const interrupts_unsorted: []const Interrupt = impl.exceptions ++ config.interrupts;
    var interrupts: [interrupts_unsorted.len]Interrupt = undefined;
    std.mem.copyForwards(Interrupt, &interrupts, interrupts_unsorted);
    std.mem.sort(Interrupt, &interrupts, {}, struct {
        pub fn lessThanFn(_: void, lhs: Interrupt, rhs: Interrupt) bool {
            return lhs.index < rhs.index;
        }
    }.lessThanFn);

    const VectorTable = blk: {
        var interrupt_field_names: []const [:0]const u8 = &.{};
        var last_index: isize = -14;

        for (interrupts) |interrupt| {
            while (last_index < interrupt.index) : (last_index += 1) {
                interrupt_field_names = interrupt_field_names ++ .{"_reserved" ++ std.fmt.comptimePrint("{}", .{last_index + 15})};
            }
            interrupt_field_names = interrupt_field_names ++ .{interrupt.name};
            last_index += 1;
        }

        var fields: [2 + interrupt_field_names.len]std.builtin.Type.StructField = undefined;
        fields[0] = .{
            .name = "initial_stack_pointer",
            .type = u32,
            .default_value_ptr = null,
            .is_comptime = false,
            .alignment = @alignOf(u32),
        };

        fields[1] = .{
            .name = "Reset",
            .type = InterruptHandler,
            .default_value_ptr = null,
            .is_comptime = false,
            .alignment = @alignOf(InterruptHandler),
        };

        for (interrupt_field_names, 0..) |name, i| {
            fields[2 + i] = .{
                .name = name,
                .type = InterruptHandler,
                .default_value_ptr = @as(*const anyopaque, @ptrCast(&@as(InterruptHandler, unhandled_interrupt))),
                .is_comptime = false,
                .alignment = @alignOf(InterruptHandler),
            };
        }

        break :blk @Type(.{ .@"struct" = .{
            .layout = .@"extern",
            .fields = &fields,
            .decls = &.{},
            .is_tuple = false,
        } });
    };

    const startup_logic = struct {
        pub const vector_table: VectorTable = blk: {
            var tmp: VectorTable = .{
                .initial_stack_pointer = config.initial_stack_pointer,
                .Reset = _start,
            };

            tmp.Reset = _start;

            break :blk tmp;
        };

        pub fn _start() callconv(.C) void {
            root.initialize_memory(config.linker);
            root.zcpu_main();
        }
    };

    @export(&startup_logic._start, .{
        .name = "_start",
    });

    @export(&startup_logic.vector_table, .{
        .name = "_vector_table",
        .section = config.linker.flash_start_section,
    });
}
