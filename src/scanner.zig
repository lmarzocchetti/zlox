const std = @import("std");

fn isDigit(c: u8) bool {
    return c >= '0' and c <= '9';
}

fn isAlpha(c: u8) bool {
    return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or c == '_';
}

pub const TokenType = enum {
    // Single-character tokens.
    TOKEN_LEFT_PAREN,
    TOKEN_RIGHT_PAREN,
    TOKEN_LEFT_BRACE,
    TOKEN_RIGHT_BRACE,
    TOKEN_COMMA,
    TOKEN_DOT,
    TOKEN_MINUS,
    TOKEN_PLUS,
    TOKEN_SEMICOLON,
    TOKEN_SLASH,
    TOKEN_STAR,

    // One or two character tokens
    TOKEN_BANG,
    TOKEN_BANG_EQUAL,
    TOKEN_EQUAL,
    TOKEN_EQUAL_EQUAL,
    TOKEN_GREATER,
    TOKEN_GREATER_EQUAL,
    TOKEN_LESS,
    TOKEN_LESS_EQUAL,

    // Literals
    TOKEN_IDENTIFIER,
    TOKEN_STRING,
    TOKEN_NUMBER,

    // Keywords
    TOKEN_AND,
    TOKEN_CLASS,
    TOKEN_ELSE,
    TOKEN_FALSE,
    TOKEN_FOR,
    TOKEN_FUN,
    TOKEN_IF,
    TOKEN_NIL,
    TOKEN_OR,
    TOKEN_PRINT,
    TOKEN_RETURN,
    TOKEN_SUPER,
    TOKEN_THIS,
    TOKEN_TRUE,
    TOKEN_VAR,
    TOKEN_WHILE,

    TOKEN_ERROR,
    TOKEN_EOF,
};

pub const Token = struct {
    ttype: TokenType,
    start: []u8,
    line: usize,
};

pub const Scanner = struct {
    source: []u8,
    current: usize,
    tok_len: usize,
    line: usize,

    pub fn init(source: []u8) Scanner {
        return Scanner{
            .source = source,
            .current = 0,
            .tok_len = 0,
            .line = 1,
        };
    }

    pub fn scanToken(self: *Scanner) Token {
        self.tok_len = 1;

        self.skipWhitespace();

        if (self.isAtEnd()) {
            return self.makeToken(.TOKEN_EOF, false);
        }

        const c = self.advance();

        if (isAlpha(c)) {
            return self.identifier();
        }

        if (isDigit(c)) {
            return self.number();
        }

        switch (c) {
            '(' => return self.makeToken(.TOKEN_LEFT_PAREN, false),
            ')' => return self.makeToken(.TOKEN_RIGHT_PAREN, false),
            '{' => return self.makeToken(.TOKEN_LEFT_BRACE, false),
            '}' => return self.makeToken(.TOKEN_RIGHT_BRACE, false),
            ';' => return self.makeToken(.TOKEN_SEMICOLON, false),
            ',' => return self.makeToken(.TOKEN_COMMA, false),
            '.' => return self.makeToken(.TOKEN_DOT, false),
            '-' => return self.makeToken(.TOKEN_MINUS, false),
            '+' => return self.makeToken(.TOKEN_PLUS, false),
            '/' => return self.makeToken(.TOKEN_SLASH, false),
            '*' => return self.makeToken(.TOKEN_STAR, false),
            '!' => {
                if (self.match('=')) {
                    self.tok_len += 1;
                    return self.makeToken(.TOKEN_BANG_EQUAL, false);
                } else {
                    return self.makeToken(.TOKEN_BANG, false);
                }
            },
            '=' => {
                if (self.match('=')) {
                    self.tok_len += 1;
                    return self.makeToken(.TOKEN_EQUAL_EQUAL, false);
                } else {
                    return self.makeToken(.TOKEN_EQUAL, false);
                }
            },
            '<' => {
                if (self.match('=')) {
                    self.tok_len += 1;
                    return self.makeToken(.TOKEN_LESS_EQUAL, false);
                } else {
                    return self.makeToken(.TOKEN_LESS, false);
                }
            },
            '>' => {
                if (self.match('=')) {
                    self.tok_len += 1;
                    return self.makeToken(.TOKEN_GREATER_EQUAL, false);
                } else {
                    return self.makeToken(.TOKEN_GREATER, false);
                }
            },
            '"' => {
                self.tok_len = 0;
                return self.string();
            },
            else => return self.errorToken("Unexpected character."), // TODO: Verify this error token, maybe disallow some things
        }

        return self.errorToken("Unexpected character.");
    }

    fn isAtEnd(self: *Scanner) bool {
        return self.source.len == self.current;
    }

    fn advance(self: *Scanner) u8 {
        self.current += 1;
        return self.source[self.current - 1];
    }

    fn peek(self: *Scanner) u8 {
        if (self.isAtEnd()) {
            return 0;
        }

        return self.source[self.current];
    }

    fn peekNext(self: *Scanner) u8 {
        if (self.isAtEnd()) {
            return 0;
        }

        return self.source[self.current + 1];
    }

    fn match(self: *Scanner, expected: u8) bool {
        if (self.isAtEnd()) {
            return false;
        }

        if (self.source[self.current] != expected) {
            return false;
        }

        self.current += 1;
        return true;
    }

    fn skipWhitespace(self: *Scanner) void {
        while (true) {
            const c = self.peek();
            switch (c) {
                ' ', '\r', '\t' => {
                    _ = self.advance();
                },
                '\n' => {
                    self.line += 1;
                    _ = self.advance();
                },
                '/' => {
                    if (self.peekNext() == '/') {
                        while (self.peek() != '\n' and !self.isAtEnd()) {
                            _ = self.advance();
                        }
                    } else {
                        return;
                    }
                },
                else => return,
            }
        }
    }

    fn string(self: *Scanner) Token {
        const starting: usize = self.current;

        while (self.peek() != '"' and !self.isAtEnd()) {
            if (self.peek() == '\n') {
                self.line += 1;
            }
            _ = self.advance();
            self.tok_len += 1;
        }

        if (self.isAtEnd()) {
            return self.errorToken("Unterminated string.");
        }

        _ = self.advance();

        return Token{
            .ttype = .TOKEN_STRING,
            .start = self.source[starting..(starting + self.tok_len)],
            .line = self.line,
        };
    }

    fn number(self: *Scanner) Token {
        const starting: usize = self.current - 1;

        while (isDigit(self.peek())) {
            _ = self.advance();
            self.tok_len += 1;
        }

        if (self.peek() == '.' and isDigit(self.peekNext())) {
            _ = self.advance();
            self.tok_len += 1;

            while (isDigit(self.peek())) {
                _ = self.advance();
                self.tok_len += 1;
            }
        }

        return Token{
            .ttype = .TOKEN_NUMBER,
            .start = self.source[starting..(starting + self.tok_len)],
            .line = self.line,
        };
    }

    fn checkKeyword(self: *Scanner, length: usize, skipped: usize, rest: []const u8, ttype: TokenType) TokenType {
        if (skipped == length + 1 and std.mem.eql(u8, self.source[(self.current - length)..(self.current)], rest)) {
            return ttype;
        }

        return TokenType.TOKEN_IDENTIFIER;
    }

    fn identifierType(self: *Scanner, skipped: usize) TokenType {
        switch (self.source[self.current - skipped]) {
            'a' => return self.checkKeyword(2, skipped, "nd", .TOKEN_AND),
            'c' => return self.checkKeyword(4, skipped, "lass", .TOKEN_CLASS),
            'e' => return self.checkKeyword(3, skipped, "lse", .TOKEN_ELSE),
            'f' => {
                switch (self.source[self.current - skipped + 1]) {
                    'a' => return self.checkKeyword(4, skipped, "alse", .TOKEN_FALSE),
                    'o' => return self.checkKeyword(2, skipped, "or", .TOKEN_FOR),
                    'u' => return self.checkKeyword(2, skipped, "un", .TOKEN_FUN),
                    else => @panic("Unknown keyword"),
                }
            },
            'i' => return self.checkKeyword(1, skipped, "f", .TOKEN_IF),
            'n' => return self.checkKeyword(2, skipped, "il", .TOKEN_NIL),
            'o' => return self.checkKeyword(1, skipped, "r", .TOKEN_OR),
            'p' => return self.checkKeyword(4, skipped, "rint", .TOKEN_PRINT),
            'r' => return self.checkKeyword(5, skipped, "eturn", .TOKEN_RETURN),
            's' => return self.checkKeyword(4, skipped, "uper", .TOKEN_SUPER),
            't' => {
                switch (self.source[self.current - skipped + 1]) {
                    'h' => return self.checkKeyword(3, skipped, "his", .TOKEN_THIS),
                    'r' => return self.checkKeyword(3, skipped, "rue", .TOKEN_TRUE),
                    else => @panic("Unknown keyword"),
                }
            },
            'v' => return self.checkKeyword(2, skipped, "ar", .TOKEN_VAR),
            'w' => return self.checkKeyword(4, skipped, "hile", .TOKEN_WHILE),
            else => @panic("Unknown keyword"),
        }

        return TokenType.TOKEN_IDENTIFIER;
    }

    fn identifier(self: *Scanner) Token {
        const starting: usize = self.current - 1;
        var skipped: usize = 1;

        while (isAlpha(self.peek()) or isDigit(self.peek())) {
            _ = self.advance();
            self.tok_len += 1;
            skipped += 1;
        }

        return Token{
            .ttype = self.identifierType(skipped),
            .start = self.source[starting..(starting + self.tok_len)],
            .line = self.line,
        };
    }

    fn makeToken(self: *Scanner, ttype: TokenType, matched: bool) Token {
        if (ttype == .TOKEN_EOF) {
            return Token{ .ttype = ttype, .start = "", .line = self.line };
        }

        if (matched) {
            return Token{
                .ttype = ttype,
                .start = self.source[(self.current - 2)..(self.current - 2 + self.tok_len)],
                .line = self.line,
            };
        }

        return Token{
            .ttype = ttype,
            .start = self.source[(self.current - 1)..(self.current - 1 + self.tok_len)],
            .line = self.line,
        };
    }

    fn errorToken(self: *Scanner, message: []const u8) Token {
        return Token{
            .ttype = .TOKEN_ERROR,
            .start = @constCast(message),
            .line = self.line,
        };
    }
};
