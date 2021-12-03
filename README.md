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
