const std = @import("std");

const Grid = struct {
    w: usize,
    h: usize,
    buf: []u8,

    pub fn init(aa: std.mem.Allocator, bytes: []u8) !Grid {
        const width = std.mem.indexOfAny(u8, bytes, "\r\n").?;
        const lines = bytes.len / (width + 2) + 1;

        // std.debug.print("len: {d} | w: {d} | line calc: {d}\n", .{ bytes.len, width, lines });

        var res = .{
            .w = width,
            .h = lines,
            .buf = try aa.alloc(u8, width * lines),
        };

        // Fill Buffer
        var line_iter = std.mem.tokenizeAny(u8, bytes, "\r\n");
        var idx: usize = 0;
        var size: usize = 0;
        while (line_iter.next()) |line| {
            for (line) |ch| {
                res.buf[idx] = ch;
                idx += 1;
            }
            size += line.len;
        }

        // std.debug.print("size: {d} | idx: {d}\n", .{ size, idx });

        return res;
    }

    pub fn at(self: Grid, col: usize, row: usize) u8 {
        if (col > self.w or row > self.h) return ' ';
        const i = self.w * row + col;
        return self.buf[i];
    }
};

fn word_search_count(aa: std.mem.Allocator, text: []u8) !usize {
    const grid = try Grid.init(aa, text);

    var count: usize = 0;

    for (0..grid.h) |y| {
        for (0..grid.w) |x| {
            // std.debug.print("{c}", .{grid.at(x, y)});
            if (grid.at(x, y) != 'X') {
                continue;
            }

            const N = y >= 3;
            const S = y <= grid.h - 4;
            const E = x <= grid.w - 4;
            const W = x >= 3;

            if (N and grid.at(x, y - 1) == 'M' and grid.at(x, y - 2) == 'A' and grid.at(x, y - 3) == 'S') count += 1;
            if (S and grid.at(x, y + 1) == 'M' and grid.at(x, y + 2) == 'A' and grid.at(x, y + 3) == 'S') count += 1;
            if (E and grid.at(x + 1, y) == 'M' and grid.at(x + 2, y) == 'A' and grid.at(x + 3, y) == 'S') count += 1;
            if (W and grid.at(x - 1, y) == 'M' and grid.at(x - 2, y) == 'A' and grid.at(x - 3, y) == 'S') count += 1;
            if (N and E and grid.at(x + 1, y - 1) == 'M' and grid.at(x + 2, y - 2) == 'A' and grid.at(x + 3, y - 3) == 'S') count += 1;
            if (N and W and grid.at(x - 1, y - 1) == 'M' and grid.at(x - 2, y - 2) == 'A' and grid.at(x - 3, y - 3) == 'S') count += 1;
            if (S and E and grid.at(x + 1, y + 1) == 'M' and grid.at(x + 2, y + 2) == 'A' and grid.at(x + 3, y + 3) == 'S') count += 1;
            if (S and W and grid.at(x - 1, y + 1) == 'M' and grid.at(x - 2, y + 2) == 'A' and grid.at(x - 3, y + 3) == 'S') count += 1;
        }
        // std.debug.print("\n", .{});
    }

    return count;
}

test "word_search_count" {
    var input =
        \\MMMSXXMASM
        \\MSAMXMSMSA
        \\AMXSXMAAMM
        \\MSAMASMSMX
        \\XMASAMXAMM
        \\XXAMMXXAMA
        \\SMSMSASXSS
        \\SAXAMASAAA
        \\MAMMMXMMMM
        \\MXMXAXMASX
        \\
    .*;
    input[0] = input[0];

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const aa = arena.allocator();
    const n = try word_search_count(aa, &input);

    std.testing.expect(n == 18) catch std.debug.print("Expected 18 got: {d}\n", .{n});
}

pub fn part1() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const aa = arena.allocator();

    // Read Input File
    const file = try std.fs.cwd().openFile("src/day4/input.txt", .{});
    defer file.close();
    const bytes = try file.readToEndAlloc(aa, 1024 * 1024);

    const count = try word_search_count(aa, bytes);

    std.debug.print("Word Search Count: {d}\n", .{count});
}

fn pattern_search_count(aa: std.mem.Allocator, text: []u8) !usize {
    const grid = try Grid.init(aa, text);

    var count: usize = 0;

    for (0..grid.h) |y| {
        for (0..grid.w) |x| {
            // std.debug.print("{c}", .{grid.at(x, y)});
            if (grid.at(x, y) != 'A') {
                continue;
            }

            if (x == 0 or y == 0 or x == grid.w - 1 or y == grid.h - 1) continue;

            const NW = grid.at(x - 1, y - 1);
            const NE = grid.at(x + 1, y - 1);
            const SW = grid.at(x - 1, y + 1);
            const SE = grid.at(x + 1, y + 1);

            if (NW == 'M' and SE == 'S' and SW == 'M' and NE == 'S') count += 1;
            if (NW == 'S' and SE == 'M' and SW == 'M' and NE == 'S') count += 1;
            if (NW == 'M' and SE == 'S' and SW == 'S' and NE == 'M') count += 1;
            if (NW == 'S' and SE == 'M' and SW == 'S' and NE == 'M') count += 1;
        }
        // std.debug.print("\n", .{});
    }

    return count;
}

test "pattern search" {
    var input =
        \\MMMSXXMASM
        \\MSAMXMSMSA
        \\AMXSXMAAMM
        \\MSAMASMSMX
        \\XMASAMXAMM
        \\XXAMMXXAMA
        \\SMSMSASXSS
        \\SAXAMASAAA
        \\MAMMMXMMMM
        \\MXMXAXMASX
        \\
    .*;
    input[0] = input[0];

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const aa = arena.allocator();
    const n = try pattern_search_count(aa, &input);

    std.testing.expect(n == 9) catch std.debug.print("Expected 9 got: {d}\n", .{n});
}

pub fn part2() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const aa = arena.allocator();

    // Read Input File
    const file = try std.fs.cwd().openFile("src/day4/input.txt", .{});
    defer file.close();
    const bytes = try file.readToEndAlloc(aa, 1024 * 1024);

    const count = try pattern_search_count(aa, bytes);

    std.debug.print("Pattern Search Count: {d}\n", .{count});
}
