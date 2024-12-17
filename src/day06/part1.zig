const std = @import("std");

const Kind = enum {
    safe,
    red,
    wall,
    up,
    down,
    left,
    right,
};

const Dir = enum { N, E, S, W };

const Grid = struct {
    w: usize,
    h: usize,
    guard: usize,
    dir: Dir,
    kinds: []Kind,

    pub fn init(aa: std.mem.Allocator, bytes: []u8) !Grid {
        var grid = std.ArrayList(Kind).init(aa);
        var lines: usize = 0;
        var width: usize = 0;
        var guard: usize = 0;
        var facing = Dir.N;
        var idx: usize = 0;
        var iter = std.mem.tokenizeAny(u8, bytes, "\r\n");
        while (iter.next()) |line| {
            width = line.len;
            var kind = Kind.safe;
            for (line) |ch| {
                switch (ch) {
                    '.' => kind = Kind.safe,
                    '#' => kind = Kind.wall,
                    '^' => {
                        kind = Kind.up;
                        facing = Dir.N;
                        guard = idx;
                    },
                    'v' => {
                        kind = Kind.down;
                        facing = Dir.S;
                        guard = idx;
                    },
                    '<' => {
                        kind = Kind.left;
                        facing = Dir.W;
                        guard = idx;
                    },
                    '>' => {
                        kind = Kind.right;
                        facing = Dir.E;
                        guard = idx;
                    },
                    else => unreachable,
                }
                try grid.append(kind);
                idx += 1;
            }
            lines += 1;
        }
        return .{
            .w = width,
            .h = lines,
            .guard = guard,
            .dir = facing,
            .kinds = try grid.toOwnedSlice(),
        };
    }

    fn get(self: Grid, idx: usize) !Kind {
        if (idx < 0 or idx >= self.kinds.len) return error.OutOfBounds;
        return;
    }

    fn next(self: Grid) !usize {
        const g: isize = @intCast(self.guard);
        const w: isize = @intCast(self.w);
        const i = switch (self.dir) {
            Dir.N => g - w,
            Dir.S => g + w,
            Dir.E => g + 1,
            Dir.W => g - 1,
        };
        if (i < 0 or i >= self.kinds.len) return error.OutOfBounds;
        return @intCast(i);
    }

    fn turn(self: *Grid) !void {
        self.dir = switch (self.dir) {
            Dir.N => Dir.E,
            Dir.S => Dir.W,
            Dir.E => Dir.S,
            Dir.W => Dir.N,
        };
        self.kinds[self.guard] = switch (self.dir) {
            Dir.N => Kind.up,
            Dir.S => Kind.down,
            Dir.E => Kind.right,
            Dir.W => Kind.left,
        };
    }

    fn guard_walk(self: *Grid) !usize {
        var _next: usize = 0;
        while (true) {
            self.kinds[self.guard] = Kind.red;
            _next = self.next() catch break;
            if (self.kinds[_next] == Kind.wall) {
                try self.turn();
            } else {
                self.kinds[_next] = switch (self.dir) {
                    Dir.N => Kind.up,
                    Dir.S => Kind.down,
                    Dir.E => Kind.right,
                    Dir.W => Kind.left,
                };
                self.guard = _next;
            }
        }
        // Count Guarded Cells
        var count: usize = 0;
        for (self.kinds) |cell| {
            if (cell == Kind.red) count += 1;
        }
        return count;
    }
};

test "p1" {
    var input =
        \\....#.....
        \\.........#
        \\..........
        \\..#.......
        \\.......#..
        \\..........
        \\.#..^.....
        \\........#.
        \\#.........
        \\......#...
        \\
    .*;
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const aa = arena.allocator();

    var grid = try Grid.init(aa, &input);
    const n = try grid.guard_walk();

    std.testing.expect(n == 41) catch std.debug.print("Expected 41 got: {d}\n", .{n});
}

pub fn sln() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const aa = arena.allocator();

    // Read Input File
    const file = try std.fs.cwd().openFile("data/day06.txt", .{});
    defer file.close();
    const bytes = try file.readToEndAlloc(aa, 1024 * 1024);

    var grid = try Grid.init(aa, bytes);
    const n = try grid.guard_walk();

    std.debug.print("Day 6 Part 1: {d}", .{n});
}
