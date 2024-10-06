const std = @import("std");
const printf = std.debug.print;

const Scanner = @import("scanner.zig").Scanner;

pub fn compile(source: []u8) void {
    var scanner: Scanner = Scanner.init(source);

    var line: isize = -1;

    while (true) {
        const token = scanner.scanToken();

        if (token.line != line) {
            printf("line: {any}\n", .{token.line});
            line = @intCast(token.line);
        }

        printf("        | ", .{});
        printf("{any} '{any}'\n", .{ token.ttype, token.start });

        if (token.ttype == .TOKEN_EOF) {
            break;
        }
    }
}
