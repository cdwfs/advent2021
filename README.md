My [Advent of Code 2021](https://adventofcode.com/2021) solutions, implemented in
[Zig](https://www.ziglang.org/) and built using [VS Code](https://code.visualstudio.com/).

_Based on the [Zig AoC template](https://github.com/SpexGuy/Zig-AoC-Template) provided by [@SpexGuy](https://github.com/SpexGuy/)_

## Instructions

The src/ directory contains a main file for each day.  Put your code there.  The build command `zig build dayXX [target and mode options] -- [program args]` will build and run the specified day.  You can also use `zig build install_dayXX [target and mode options]` to build the executable for a day and put it into `zig-out/bin` without executing it.  By default this template does not link libc, but you can set `should_link_libc` to `true` in build.zig to change that.  If you add new files with tests, add those files to the list of test files in test_all.zig.  The command `zig build test` will run tests in all of these files.  You can also use `zig build test_dayXX` to run tests in a specific day, or `zig build install_tests_dayXX` to create a debuggable test executable in `zig-out/bin`.

## TIL

A list of the puzzles, and what new language/tool features I learned each day:

### Useful VSCode settings (language-independent)
```
// "Suggestions" pops up a list of completions of the current word as you type.
// Arguably useful in code; definitely not useful in comments or strings.
"editor.quickSuggestions": {
    "other": true,
    "comments": false,
    "strings": false
},
// Suggestions are also automatically triggered when you type certain trigger characters such as '.' for struct fields.
// Again, great in code, not so great in comments. Ideally, this would be configurable at the same granularity
// as editor.quickSuggestions, but the best we can do is just disable it; not having suggestions pop up rampantly while
// typing comments outweights the convenience of typing "foo." to browse all members of "foo".
// You can still manually trigger suggestions with Ctrl+Space.
"editor.suggestOnTriggerCharacters": false,
// Change multi-cursor mode to my more familiar mode, where holding Alt lets you select in column mode. And Ctrl+click
// adds multiple cursors, but I don't use that too frequently.
"editor.multiCursorModifier": "ctrlCmd",
// Does what it says on the tin.
"debug.allowBreakpointsEverywhere": true,
```

### [Day 1: Sonar Sweep](https://adventofcode.com/2021/day/1)
- Basic Zig + VSCode integration
- [Multiline string literals](https://ziglang.org/documentation/master/#Multiline-String-Literals)
  - `Selection -> Switch to Ctrl+Click for Multi-Cursor` enables `Alt`+click for column select, and `Ctrl`+click for multi-cursor
- Tests use `try expect(expr)` to fail the test if `expr` is false. `assert(expr)` doesn't seem to have the same effect.
- The `std::vector` of Zig is [`std.ArrayList`](https://ziglang.org/documentation/master/std/#std;ArrayList).
  - Use `defer list.deinit()` to deallocate the list when it goes out of scope.
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
- `if` expressions (which I ultimately replaced with `switch` expressions anyway)
- Weird comptime error when using try `expectEquals(150, myfunc(x))` is due to `expectEquals()` using the type of the first parameter to determine the second. The workaround is to use `@as(u32, 150)` to cast the expected result away from `comptime_int`, but it's a [known wart](https://github.com/ziglang/zig/issues/4437) with a few proposed fixes in the works.

### [Day 3: Binary Diagnostic](https://adventofcode.com/2021/day/3)
- How to *debug* tests from VSCode? F5 doesn't work any more. If I switch the tasks.json back to `"build", "day03"` then it can't find my breakpoints, because main() is empty and everything gets stripped out.
- The compiler is _very_ aggressive about pushing things to comptime. I have to resort to `@as(i64, N)` instead of `N` far more often than I'd like.
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
- [ZLS](https://github.com/zigtools/zls) is now working properly. Maybe I forgot to configure it earlier? F12 works! Style warnings! API docs on mouse hover!
- There's some big breaking API changes going on in Zig 0.9.0-dev that I happened to catch at the wrong time, so the stdlib functions I was using and the API docs I was reading didn't always match up. Woops!
- Otherwise, no new concepts. This one felt pretty refreshingly straightforward.

### [Day 6: Lanternfish](https://adventofcode.com/2021/day/6)
- `std.mem.rotate()` to rotate array contents in-place
- `array[0..]` gives the array as a slice
- fish are fungible.
- You sure do get integer overflow errors if you use too small a variable at runtime! (unless you use one of the fancy wrapping/saturating operators).
- You can't `.initCapacity()` or `.ensureTotalCapacity()` in a struct field's default initializer, because default values for these fields are computed at compile time and stored as constants, and thus can't allocate memory. This preserves Zig's "if it doesn't look like a function call, it's not a function call" guarantee: `MyType{}` isn't a function call.

### [Day 7: The Treachery of Whales](https://adventofcode.com/2021/day/7)
- `std.math.maxInt(type)` for maximum value for a type
- `@divFloor()` and `divTrunc()` are required for integer division.
- Just brute-forced part 2, it was fine.

### [Day 8: Seven Segment Search](https://adventofcode.com/2021/day/8)
- `std.bit_set.IntegerMask` has some useful bitwise intrinsics (`.count()` for popcnt, `.findFirstSet()` for clz, etc.). Doing just basic bitwise ops with them is a bit clunky though; see if you'll use enough of these methods before deciding which type to use.

### [Day 9: Smoke Basin](https://adventofcode.com/2021/day/9)
- Didn't see a good way to create a dynamic 2D array, so I just used a fixed-size array with the hard-coded puzzle size. I guess the answer is the same as C: either dynamically allocate every row, or use a flat buffer and manually translate \[x,y\] coordinates to flat indices.
- Idiomatic sorting: `std.sort.sort(i64, array.items, {}. comptime std.sort.asc(i64))`. Why is the `comptime` keyword needed here?
- Trying to add a `set_cell()` method to my `Input` struct didn't work; it thought the input was a const pointer. Why is that?
- non-pointer Zig function parameters are implicitly `const`. So inside `fn myFunc(x:i64)`, it is a compile error to modify `x`.

### [Day 10: Syntax Scoring](https://adventofcode.com/2021/day/10)
- Solved in ~30 minutes without needing to reference the docs at all. Hitting my stride!
- Not clear what the best way to clear an array is -- I went with `.shrinkRetainingCapacity()` but need to take a closer look at the various options.

### [Day 11: Dumbo Octopus](https://adventofcode.com/2021/day/11)
- Whenever you know the length of the array you're iterating, use for(array) |element,i| instead of manually declaring a loop variable (and subsequently forgetting to reinitialize it when you copy/paste the same loop further down the function).
- `std.mem.copy()` to copy arrays/slices
- `std.StaticBitSet(size)` gives you the optimal representation for a bitset given `size` (a single int if it'll fit, an array if not) with the same interface on both types.
- If `ps` is a pointer-to-struct with field `x`, then there's no need to dereference the struct to access the field (but you can). `ps.*.x` and `ps.x` are equivalent.
- `std.BoundedArray` is a heap-less `std.ArrayList` if the max capacity is known at compile time. Slightly different API than ArrayList though.

### [Day 12: Passage Pathing](https://adventofcode.com/2021/day/12)
- `std.mem.eql(u8, s1, s2)` to compare strings for equality.
- `std.AutoHashMap()` doesn't work with string keys; use `std.StringHashMap()` instead. Nice error message pointing you in the right direction, A+!

### [Day 13: Transparent Origami](https://adventofcode.com/2021/day/13)
- `std.ArrayList().appendNTimesAssumeCapacity()` (and the `AssumeCapacity()` methods in general) are useful in cases where the array is pre-allocated.
- `std.mem.doNotOptimizeAway()` does what it says on the tin

### [Day 14: Extended Polymerization](https://adventofcode.com/2021/day/14)
- Key memory for `std.StringHashMap` is managed by the caller; using stack-allocated strings won't work correctly.
- `callconv(.Inline)` to force a function to be inlined at all call sites (with a compile error if that's not possible)
- Use `std.time.Timer` for (up to) nanosecond-resolution timing.

### [Day 15: Chiton](https://adventofcode.com/2021/day/15)
- `std.ArrayList()` has `.swapRemove()` for O(1) removal
- Dijkstra took 600ms; I should try moving to A* for fun.

### [Day 16: Packet Decoder](https://adventofcode.com/2021/day/16)
- Took my time and played with some new (to me) language features.
- My `readBits()` function takes a type and does some compile-time logic to determine the correct logic to run.
- Made an `enum`. `@intToEnum()` and `@tagName()` are handy.

### [Day 17: Trick Shot](https://adventofcode.com/2021/day/17)
- Zig-wise, not much.

### [Day 18: Snailfish](https://adventofcode.com/2021/day/18)
- Hit a compiler issue; reported as [zig#10357](https://github.com/ziglang/zig/issues/10357)
- Implemented the incorrect algorithm correctly, and spent a ton of time debugging that. Reading comprehension FTL :(
- non-trivial memory allocation. `allocator.create(type)` and `allocator.destroy(p)` for single-item allocations.
- Getting better at tagged unions. `@as(TagType, tu)` to cast a union instance to its tag value.
- Basic `std.io.Writer` use, while debugging. `std.ArrayList(u8).writer()` to get a `Writer` object, and then `writer.print()` to append string data to it.

### [Day 19: Beacon Scanner](https://adventofcode.com/2021/day/19)
- Banged my head against this one for _way_ too long.
- `std.AutoHashMap` has a `.putNoClobber()` for easy "add new entry to a hashmap"
- TODO: Plenty of optimization potential here. The rotations could be implemented as swizzles instead of matrices. The hash maps could use a custom hash function for `Point3`. `Point3` could use a significantly lower bit count (`i16` instead of `i64`, if not smaller). Only add each scanner's offsets to known space, don't recompute them from scratch between all beacons (since pairs of scanners are guaranteed to overlap with each other). Don't restart the loop over scanners after finding a match; just keep going, as entries earlier in the array are likely to still be misses anyway.

### [Day 20: Trench Map](https://adventofcode.com/2021/day/20)
- RTFD
- That's it, really. Could probably have gone with a 2D array instead of hashmaps here; the input data wasn't large enough to warrant sparse storage. But it still ran in ~1.5 seconds in a debug build, so I'm not going to sweat it.

### [Day 21: Dirac Dice](https://adventofcode.com/2021/day/21)
- universes are fungible!

### [Day 22: Reactor Reboot](https://adventofcode.com/2021/day/22)
- Iterating a a `std.ArrayList` backwards is tricky, but the `-%` operator helps.

### [Day 23: Amphipod](https://adventofcode.com/2021/day/23)
- structs with `std.BoundedArray()` fields get a copy of the array data `std.ArrayList()` gets a weird half-copy, because internally it's storing a slice (pointer+len). The pointer is shared; the len is not.

### [Day 24: Arithmetic Logic Unit](https://adventofcode.com/2021/day/24)
- `std.fmt.formatIntBuf()` seems to be the `itoa()` equivalent.
- Fun actual puzzle -- simulate a CPU, debug some assembly code, reverse-engineer an algorithm & look for patterns!

### [Day 25: Sea Cucumber](https://adventofcode.com/2021/day/25)
- predictably anticlimatic. But, done!
