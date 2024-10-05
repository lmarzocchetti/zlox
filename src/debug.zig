const std = @import("std");
const printf = std.debug.print;
const chunk_i = @import("chunk.zig");
const Chunk = chunk_i.Chunk;
const OpCode = chunk_i.OpCode;

pub fn disassembleChunk(chunk: *Chunk, name: []u8) void {
    printf("== {any} ==\n", .{name});

    var offset = 0;
    while (offset < chunk.count()) {
        offset = disassembleInstruction(chunk, offset);
    }
}

fn constantInstruction(name: []u8, chunk: *Chunk, offset: i64) i64 {
    const constant = chunk.code[offset + 1];
    printf("{any}      {any} '", .{ name, constant });
    chunk_i.printValue(chunk.constants[constant]);
    printf("'\n", .{});
    return offset + 2;
}

fn constantLongInstruction(name: []u8, chunk: *Chunk, offset: i64) i64 {
    const constant_1b = chunk.code[offset + 1];
    const constant_2b = chunk.code[offset + 2];
    const constant_3b = chunk.code[offset + 3];

    var index: usize = 0;
    index = (index) | constant_3b;
    index = (index << 8) | constant_2b;
    index = (index << 8) | constant_1b;

    printf("{any}      {any} '", .{ name, index });
    chunk_i.printValue(chunk.constants[index]);
    printf("'\n", .{});

    return offset + 4;
}

fn simpleInstruction(name: []u8, offset: i64) i64 {
    printf("{any}\n", .{name});
    return offset + 1;
}

pub fn disassembleInstruction(chunk: *Chunk, offset: i64) void {
    printf("{any}", .{offset});

    if (offset > 0 and chunk.lines[offset] == chunk.lines[offset - 1]) {
        printf("    | ", .{});
    } else {
        printf("{any}", .{chunk.lines[offset]});
    }

    const instruction = chunk.code[offset];

    switch (instruction) {
        OpCode.OP_CONSTANT => return constantInstruction("OP_CONSTANT", chunk, offset),
        OpCode.OP_CONSTANT_LONG => return constantLongInstruction("OP_CONSTANT_LONG", chunk, offset),
        OpCode.OP_ADD => return simpleInstruction("OP_ADD", offset),
        OpCode.OP_SUBTRACT => return simpleInstruction("OP_SUBTRACT", offset),
        OpCode.OP_MULTIPLY => return simpleInstruction("OP_MULTIPLY", offset),
        OpCode.OP_DIVIDE => return simpleInstruction("OP_DIVIDE", offset),
        OpCode.OP_NEGATE => return simpleInstruction("OP_NEGATE", offset),
        OpCode.OP_RETURN => return simpleInstruction("OP_RETURN", offset),
        else => {
            printf("Unknown opcode {any}\n", .{instruction});
            return offset + 1;
        },
    }
}
