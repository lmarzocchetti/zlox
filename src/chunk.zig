const std = @import("std");
const Allocator = std.mem.Allocator;
const Vec = std.ArrayList;

pub const Value = f64;

pub fn printValue(value: Value) void {
    std.debug.print("{any}", .{value});
}

pub const OpCode = enum(u8) {
    OP_CONSTANT,
    OP_CONSTANT_LONG,
    OP_ADD,
    OP_SUBTRACT,
    OP_MULTIPLY,
    OP_DIVIDE,
    OP_NEGATE,
    OP_RETURN,
};

pub const Chunk = struct {
    code: Vec(u8),
    lines: Vec(i64),
    constants: Vec(Value),

    pub fn init(allocator: Allocator) Chunk {
        return Chunk{
            .code = Vec(u8).init(allocator),
            .lines = Vec(i64).init(allocator),
            .constants = Vec(Value).init(allocator),
        };
    }

    pub fn deinit(self: *Chunk) void {
        self.code.deinit();
        self.lines.deinit();
        self.constants.deinit();
    }

    pub fn writeChunk(self: *Chunk, byte: u8, line: i64) !void {
        try self.code.append(byte);
        try self.lines.append(line);
    }

    pub fn addConstant(self: *Chunk, value: Value) !usize {
        try self.constants.append(value);
        return self.constants.items.len - 1;
    }

    pub fn writeConstant(self: *Chunk, value: Value, line: i64) !void {
        const constant = try self.addConstant(value);

        if (constant <= 255) {
            try self.writeChunk(@intFromEnum(OpCode.OP_CONSTANT), line);
            try self.writeChunk(@truncate(constant), line);
        } else {
            try self.writeChunk(@intFromEnum(OpCode.OP_CONSTANT_LONG), line);
            try self.writeChunk(@truncate((constant & 0xFF)), line);
            try self.writeChunk(@truncate(((constant >> 8)) & 0xFF), line);
            try self.writeChunk(@truncate(((constant >> 16)) & 0xFF), line);
        }
    }

    pub fn count(self: *Chunk) usize {
        return self.code.items.len;
    }
};
