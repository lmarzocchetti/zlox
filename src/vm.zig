const std = @import("std");
const Allocator = std.mem.Allocator;
const printf = std.debug.print;
const ValueStack = std.ArrayList(Value);

const chunk_i = @import("chunk.zig");
const Chunk = chunk_i.Chunk;
const Value = chunk_i.Value;
const OpCode = chunk_i.OpCode;

const debug = @import("debug.zig");
const compiler = @import("compiler.zig");

const DEBUG_TRACE_EXECUTION: bool = false;

const BinaryOp = enum {
    ADD,
    SUB,
    MUL,
    DIV,
};

pub const InterpretResult = enum {
    INTERPRET_OK,
    INTERPRET_COMPILE_ERROR,
    INTERPRET_RUNTIME_ERROR,
};

pub const VM = struct {
    chunk: *Chunk,
    ip: [*]u8,
    stack: ValueStack,

    pub fn init(allocator: Allocator) VM {
        return VM{
            .chunk = undefined,
            .ip = undefined,
            .stack = ValueStack.init(allocator),
        };
    }

    pub fn deinit(self: *VM) void {
        self.stack.deinit();
    }

    fn printStack(self: *VM) !void {
        const st_copy = try self.stack.clone();

        printf("[", .{});

        while (st_copy.items.len != 0) {
            if (st_copy.items.len == 1) {
                printf("{any}", .{st_copy.pop()});
            } else {
                printf("{any}, ", .{st_copy.pop()});
            }
        }

        printf("]\n", .{});
    }

    pub fn interpretFromChunk(self: *VM, chunk: *Chunk) !InterpretResult {
        self.chunk = chunk;
        self.ip = self.chunk.code.items.ptr;
        return self.run();
    }

    pub fn interpretFromSource(self: *VM, source: []u8) InterpretResult {
        _ = self; // autofix
        compiler.compile(source);

        return InterpretResult.INTERPRET_OK;
    }

    fn binaryOp(self: *VM, op: BinaryOp) !void {
        const b = self.stack.pop();
        const a = self.stack.pop();

        switch (op) {
            BinaryOp.ADD => try self.stack.append(a + b),
            BinaryOp.SUB => try self.stack.append(a - b),
            BinaryOp.MUL => try self.stack.append(a * b),
            BinaryOp.DIV => try self.stack.append(a / b),
        }
    }

    fn readByte(self: *VM) u8 {
        self.ip += 1;
        return self.ip[0];
    }

    fn readConstant(self: *VM) Value {
        return self.chunk.constants.items[self.readByte()];
    }

    fn readConstantLong(self: *VM) Value {
        const constant_1b = self.readByte();
        const constant_2b = self.readByte();
        const constant_3b = self.readByte();

        var index: usize = 0;
        index = (index) | constant_3b;
        index = (index << 8) | constant_2b;
        index = (index << 8) | constant_1b;

        return self.chunk.constants.items[index];
    }

    pub fn run(self: *VM) !InterpretResult {
        while (true) {
            if (comptime DEBUG_TRACE_EXECUTION == true) {
                printf("        ", .{});
                self.printStack();
                debug.disassembleInstruction(self.chunk, self.ip - self.chunk.code.items.ptr);
            }

            const instruction: OpCode = @enumFromInt(self.readByte());
            switch (instruction) {
                OpCode.OP_CONSTANT => {
                    const constant: Value = self.readConstant();
                    try self.stack.append(constant);
                    chunk_i.printValue(constant);
                    printf("\n", .{});
                },
                OpCode.OP_CONSTANT_LONG => {
                    const constant: Value = self.readConstantLong();
                    try self.stack.append(constant);
                    chunk_i.printValue(constant);
                    printf("\n", .{});
                },
                OpCode.OP_ADD => try self.binaryOp(BinaryOp.ADD),
                OpCode.OP_SUBTRACT => try self.binaryOp(BinaryOp.SUB),
                OpCode.OP_MULTIPLY => try self.binaryOp(BinaryOp.MUL),
                OpCode.OP_DIVIDE => try self.binaryOp(BinaryOp.DIV),
                OpCode.OP_NEGATE => {
                    self.stack.items.ptr[self.stack.items.len - 1] = -self.stack.items.ptr[self.stack.items.len - 1];
                },
                OpCode.OP_RETURN => {
                    chunk_i.printValue(self.stack.pop());
                    printf("\n", .{});
                    return InterpretResult.INTERPRET_OK;
                },
            }
        }
    }
};
