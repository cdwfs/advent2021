My [Advent of Code 2021](https://adventofcode.com/2021) solutions, implemented in
[Zig](https://www.ziglang.org/) and built using [VS Code](https://code.visualstudio.com/).

_Based on the [Zig AoC template](https://github.com/SpexGuy/Zig-AoC-Template) provided by [@SpexGuy](https://github.com/SpexGuy/)_

## TIL

A list of the puzzles, and what new language/tool features I learned each day:

### [Day 1: Sonar Sweep](https://adventofcode.com/2021/day/1)
- Basic Zig + VSCode integration
- [Multiline string literals](https://ziglang.org/documentation/master/#Multiline-String-Literals)
  - `Selection -> Switch to Ctrl+Click for Multi-Cursor` enables `Alt`+click for column select, and `Ctrl`+click for multi-cursor
- Tests use `try expect(expr)` to fail the test if `expr` is false. `assert(expr)` doesn't seem to have the same effect.
- The std::vector of Zig is [std.ArrayList](https://ziglang.org/documentation/master/std/#std;ArrayList).
  - Use `defer list.deinit()` to deallocate the list when it goes out of scope. (Docs don't mention `deinit()` method? Is it some sort of allocator magic?
- `std.mem.tokenize(data, "\r\n")` to get a `TokenIterator` to iterate over lines in text data. `while(iter.next()) |str| {}` to process things from the iterator until it's empty.
- `std.fmt.parseInt()` to convert a string to an integer.
  - append `catch unreachable` to an error union to say "this can never fail, just give me the value".
- No one-line for loop over a range of integers? You have to declare and initialize an `i`, and then do `while(i < max) : (i += 1) {}`?
- TODO: Go read more about Optionals and Errors again.
- Declaring a variable as `const foo = 0xFFFF;` seemed to force it into comptime-only mode; giving it an explicit type was needed to avoid build errors.

### [Day 2: Dive!](https://adventofcode.com/2021/day/2)
- How to trigger tests from VSCode
- Basic enum and struct usage
- To unconditionally unwrap optional values, use `value.?`
- `if` expressions (which I ultimately replaces with `switch` expressions anyway)
- Weird comptime error when using try `expectEquals(150, myfunc(x))` is due to `expectEquals()` using the type of the first parameter to determine the second. The workaround is to use `@as(u32, 150)` to cast the expected result away from `comptime_int`, but it's a [known wart](https://github.com/ziglang/zig/issues/4437) with a few proposed fixes in the works.
- 

### [Day 3: Binary Diagnostic](https://adventofcode.com/2021/day/3)
- How to *debug* tests from VSCode? F5 doesn't work any more. If I switch the tasks.json back to `"build", "day03"` then it can't find my breakpoints, because main() is empty and everything gets stripped out.
- This whole comptime nonsense is getting annoying real fast. I have to resort to `@as(i64, N)` instead of `N` far more often than I'd like.
- `ArrayList.ensureTotalCapacity()` is akin to `.reserve()`, not `.resize()`. You still need to `.append()` items one at a time.
- Not being able to initialize a local loop counter for cases where I'm not iterating over a collection is mildly annoying.

### [Day 4: Giant Squid](https://adventofcode.com/2021/day/4)
- VSCode stuff:
  - Don't need twenty-something different build/test targets. In this case of one file = one exe, can just use ${fileBasenameNoExtension} to invoke whatever build/test command is needed.
  - Hooked up a basic [problem matcher](https://code.visualstudio.com/Docs/editor/tasks#_defining-a-problem-matcher), so I get proper compile errors now. ([example](https://github.com/cdwfs/advent2021/blob/ccd38ef3b0bb8b96bcabededf12d05d67fa1a01d/.vscode/tasks.json))
  - Clear the terminal between runs.
- Put test code in standalone functions, called from both unit tests and main. The former is good for running & checking output, the latter lets you step through and debug.
- `AutoHashMap` is Zig's workhorse dictionary struct. It was probably overkill for this problem, but I'll need it eventually.
- Creating custom data types with non-trivial `init()` and `deinit()` functions. Still eludes me for a bit; I spent a long time fiddling with whether pointers should be pointers or not, and am not 100% clear what I did to make it work in the end.
- bitwise ops require the shift amount to have log2 the bits of the value being shifted. See [@truncate()](https://ziglang.org/documentation/master/#truncate) to lop off bits (though I used `@intCast()`).
- `@compileLog()` lets you debug-print in compile-time code; may be useful at some point.

### [Day 5: Hydrothermal Venture](https://adventofcode.com/2021/day/5)
- [ZLS](https://github.com/zigtools/zls) is totally work configuring properly. F12 works! Style warnings! API docs on mouse hover!
- There's some big breaking API changes going on in Zig 0.9.0-dev that I happened to catch at the wrong time, so the stdlib functions I was using and the API docs I was reading didn't always match up. Woops!
- Otherwise, no new concepts. This one felt pretty refreshingly straightforward.