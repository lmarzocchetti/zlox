const std = @import("std");
const VM = @import("vm.zig").VM;
const Chunk = @import("chunk.zig").Chunk;
const OpCode = @import("chunk.zig").OpCode;

fn repl(allocator: std.mem.Allocator, vm: *VM) !void {
    const stdin = std.io.getStdIn().reader();
    const line = try stdin.readUntilDelimiterAlloc(allocator, '\n', 8192);

    while (true) {
        if (line.len == 0) {
            std.debug.print("exiting...\n", .{});
            break;
        }

        _ = vm.interpretFromSource(line);
    }
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
    var chunk: Chunk = Chunk.init(allocator);

    try chunk.writeConstant(1.2, 123);
    try chunk.writeConstant(3.4, 123);

    try chunk.writeChunk(@intFromEnum(OpCode.OP_ADD), 123);

    try chunk.writeConstant(5.6, 123);
    try chunk.writeChunk(@intFromEnum(OpCode.OP_DIVIDE), 123);
    try chunk.writeChunk(@intFromEnum(OpCode.OP_NEGATE), 123);

    try chunk.writeChunk(@intFromEnum(OpCode.OP_RETURN), 123);

    _ = try vm.interpretFromChunk(&chunk);
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

    try repl(allocator, &vm);
}
