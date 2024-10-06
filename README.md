# zlox 

## Chapter that i'm implementing -> 17

### My implementation of Lox programming language from crafting interpreters but in Zig
I'm following the book, Zig is similar to C so the code is straightforward to read. Obviously Zig has something that reminds of Classes so take that in mind.
However the content is the same as the originl C code, but with some exercise solved.
For now i've implemented these extra parts:

- OP_CONSTANT_LONG: Operation in the VM to index not 1 byte like the standard OP_CONSTANT but 3 bytes (Chapter 14, num 2)
- Dynamic stack size: Implemented with the Zig standard library ArrayList, that has the methods to use it like a stack (Chapter 15, num 3)
- Faster OP_NEGATE: Instaed of popping the value, simply took the first item and negate it (Chapter 15, num 4)

### Optimization to implement 
These are some optimization that i want implement, but i'm planning to do after i can run some code:
- [ ] Run-length-encoding: for line number (Chapter 14: num 1)
- [ ] BINARY_OP with some comptime values 
