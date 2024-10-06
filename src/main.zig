const std = @import("std");

const vm_i = @import("vm.zig");
const VM = vm_i.VM;
const InterpretResult = vm_i.InterpretResult;

const chunk_i = @import("chunk.zig");
const Chunk = chunk_i.Chunk;
const OpCode = chunk_i.OpCode;

fn repl(vm: *VM) !void {
    var buffer: [256]u8 = undefined;
    while (true) {
        const stdin = std.io.getStdIn().reader();
        const line = try stdin.readUntilDelimiter(buffer[0..], '\n');
        // const line = try stdin.readUntilDelimiterAlloc(allocator, '\n', 8192);

        if (line.len == 0) {
            std.debug.print("exiting...\n", .{});
            break;
        }

        const interpret_result = vm.interpretFromSource(line);
        if (interpret_result != InterpretResult.INTERPRET_OK) {
            std.debug.print("ERROR: {any}\n", .{interpret_result});
            return error.InterpretError;
        }
    }
}

pub fn main1() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        //fail test; can't try in defer as defer is executed after we return
        if (deinit_status == .leak) {
            @panic("LEAKED MEMORY");
        }
    }

    var vm: VM = VM.init(allocator);
    defer vm.deinit();
    var chunk: Chunk = Chunk.init(allocator);
    defer chunk.deinit();

    try chunk.writeConstant(1.2, 123);
    try chunk.writeConstant(3.4, 123);

    try chunk.writeChunk(@intFromEnum(OpCode.OP_ADD), 123);

    try chunk.writeConstant(5.6, 123);
    try chunk.writeChunk(@intFromEnum(OpCode.OP_DIVIDE), 123);
    try chunk.writeChunk(@intFromEnum(OpCode.OP_NEGATE), 123);

    try chunk.writeChunk(@intFromEnum(OpCode.OP_RETURN), 123);

    _ = try vm.interpretFromChunk(&chunk);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        //fail test; can't try in defer as defer is executed after we return
        if (deinit_status == .leak) {
            @panic("LEAKED MEMORY");
        }
    }

    var vm: VM = VM.init(allocator);
    defer vm.deinit();

    try repl(&vm);
}
