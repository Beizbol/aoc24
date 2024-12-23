const std = @import("std");

fn digit_count(num: usize) usize {
    if (num == 0) return 1;
    for (0..1024) |i| {
        const pow = std.math.pow(usize, 10, i);
        if (num < pow) return i;
    }
    unreachable;
}

test "digits" {
    var n: usize = 0;
    n = digit_count(0);
    std.testing.expect(n == 1) catch std.debug.print("ans: 1 | got: {d}\n", .{n});
    n = digit_count(1);
    std.testing.expect(n == 1) catch std.debug.print("ans: 1 | got: {d}\n", .{n});
    n = digit_count(9);
    std.testing.expect(n == 1) catch std.debug.print("ans: 1 | got: {d}\n", .{n});

    n = digit_count(10);
    std.testing.expect(n == 2) catch std.debug.print("ans: 2 | got: {d}\n", .{n});
    n = digit_count(11);
    std.testing.expect(n == 2) catch std.debug.print("ans: 2 | got: {d}\n", .{n});
    n = digit_count(99);
    std.testing.expect(n == 2) catch std.debug.print("ans: 2 | got: {d}\n", .{n});

    n = digit_count(100);
    std.testing.expect(n == 3) catch std.debug.print("ans: 3 | got: {d}\n", .{n});
    n = digit_count(101);
    std.testing.expect(n == 3) catch std.debug.print("ans: 3 | got: {d}\n", .{n});
    n = digit_count(999);
    std.testing.expect(n == 3) catch std.debug.print("ans: 3 | got: {d}\n", .{n});

    n = digit_count(1000);
    std.testing.expect(n == 4) catch std.debug.print("ans: 4 | got: {d}\n", .{n});
    n = digit_count(1001);
    std.testing.expect(n == 4) catch std.debug.print("ans: 4 | got: {d}\n", .{n});
    n = digit_count(9999);
    std.testing.expect(n == 4) catch std.debug.print("ans: 4 | got: {d}\n", .{n});
}

const Key = struct {
    k: usize,
    i: usize,
};

const Set = std.AutoHashMap(Key, usize);
const List = std.ArrayList(usize);
const Ctx = struct {
    input: List,
    set: Set,
    iter: usize,
    depth: usize,

    pub fn init(alloc: std.mem.Allocator) !Ctx {
        return .{
            .input = List.init(alloc),
            .set = Set.init(alloc),
            .iter = 0,
            .depth = 0,
        };
    }

    pub fn add_stone(ctx: *Ctx, stone: []const u8) !void {
        const n = try std.fmt.parseInt(usize, stone, 10);
        try ctx.input.append(n);
    }

    pub fn tally(ctx: *Ctx, depth: usize) !usize {
        ctx.depth = depth;
        var total: usize = 0;
        for (ctx.input.items) |n| {
            total += ctx.r_expand(n, 0);
        }
        return total;
    }

    // recursive expand and tally
    fn r_expand(ctx: *Ctx, n: usize, iter: usize) usize {
        // if (iter == 0) return ctx.input.items.len;
        // std.debug.print("\nExpanding: {d}\n", .{ctx.iter});
        const i = iter + 1;
        const even_digits = digit_count(n) % 2 == 0;
        if (i == ctx.depth) {
            return if (even_digits) 2 else 1;
        }

        if (n == 0) return r_expand(ctx, 1, i);

        if (!even_digits) return r_expand(ctx, n * 2024, i);

        const pow = std.math.pow(usize, 10, digit_count(n) / 2);
        const left = n / pow;
        const right = n - (left * pow);
        return r_expand(ctx, left, i) + r_expand(ctx, right, i);
    }

    // pub fn log_set(ctx: *Ctx) void {
    //     std.debug.print("set: {d}\n", .{ctx.set.len});
    //     var iter = ctx.set.iterator();
    //     while (iter.next()) |entry| {
    //         std.debug.print("{any}\n", .{entry.key});
    //     }
    // }

    pub fn tally_fast(ctx: *Ctx, depth: usize) !usize {
        var total: usize = 0;
        for (ctx.input.items) |n| {
            total += try ctx.r_expand_fast(n, depth);
        }
        return total;
    }

    // recursive expand and tally
    fn r_expand_fast(ctx: *Ctx, n: usize, iter: usize) !usize {
        // if (iter == 0) return ctx.input.items.len;
        // defer ctx.log_set();
        // std.debug.print("\nExpanding: {d}\n", .{ctx.iter});
        const key = Key{ .k = n, .i = iter };
        const i = iter - 1;
        if (i == 0) {
            const even_digits = digit_count(n) % 2 == 0;
            const _v: usize = if (even_digits) 2 else 1;
            // try ctx.set.put(key, _v);
            return _v;
        }

        if (n == 0) {
            const _v = try r_expand_fast(ctx, 1, i);
            // try ctx.set.put(key, _v);
            return _v;
        }

        if (ctx.set.get(key)) |v| {
            // std.debug.print("hit. key: {any}, v: {d}\n", .{ key, v });
            return v;
        }

        const even_digits = digit_count(n) % 2 == 0;
        if (i == 0) {
            const _v: usize = if (even_digits) 2 else 1;
            try ctx.set.put(key, _v);
            return _v;
        }

        if (!even_digits) {
            const _v = try r_expand_fast(ctx, n * 2024, i);
            try ctx.set.put(key, _v);
            return _v;
        }

        const pow = std.math.pow(usize, 10, digit_count(n) / 2);
        const left = n / pow;
        const right = n - (left * pow);

        const l = try r_expand_fast(ctx, left, i);
        const r = try r_expand_fast(ctx, right, i);

        try ctx.set.put(key, l + r);

        return l + r;
    }
};

const p1 = @import("part1.zig");

pub fn sln() !void {
    // Arena Memory Allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    // Open and Read File
    const file = try std.fs.cwd().openFile("data/day11.txt", .{});
    defer file.close();
    const bytes = try file.readToEndAlloc(alloc, 1024 * 1024);

    // Parse
    var ctx = try Ctx.init(alloc);
    var iter = std.mem.tokenizeAny(u8, bytes, " \r\n");
    while (iter.next()) |stone| {
        try ctx.add_stone(stone);
    }
    // Expand and Tally
    var timer = try std.time.Timer.start();
    for (1..76) |i| {
        timer.reset();
        const n = try ctx.tally(i);
        const t = timer.read();
        std.debug.print("i: {d} | t: {d}us | tally: {d}\n", .{ i, t / std.time.ns_per_us, n });
        if (t >= std.time.ns_per_min) {
            std.debug.print("i: {d} took > 1 min per. Aborting.\n", .{i});
            break;
        }
    }
    for (1..76) |i| {
        timer.reset();
        const n = try ctx.tally_fast(i);
        const t = timer.read();
        std.debug.print("i: {d} | t: {d}us | tally: {d}\n", .{ i, t / std.time.ns_per_us, n });
        if (i == 75) std.debug.print("Day 11 Part 2\nstats: {d}\n", .{n});
    }
}

test "expand 1" {
    // Arena Memory Allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var ctx = try Ctx.init(alloc);
    try ctx.add_stone("125");
    try ctx.add_stone("17");

    const n = try ctx.tally(1);

    std.testing.expect(n == 3) catch std.debug.print("1. got: {d}\n", .{n});
    try std.testing.expect(n == 3);
}

test "expand 2" {
    // Arena Memory Allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var ctx = try Ctx.init(alloc);
    try ctx.add_stone("125");
    try ctx.add_stone("17");

    const n = try ctx.tally(2);

    std.testing.expect(n == 4) catch std.debug.print("2. got: {d}\n", .{n});
    try std.testing.expect(n == 4);
}

test "expand 3" {
    // Arena Memory Allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var ctx = try Ctx.init(alloc);
    try ctx.add_stone("125");
    try ctx.add_stone("17");

    const n = try ctx.tally(3);

    std.testing.expect(n == 5) catch std.debug.print("3. got: {d}\n", .{n});
    try std.testing.expect(n == 5);
}

test "expand 4" {
    // Arena Memory Allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var ctx = try Ctx.init(alloc);
    try ctx.add_stone("125");
    try ctx.add_stone("17");

    const n = try ctx.tally(4);

    std.testing.expect(n == 9) catch std.debug.print("4. got: {d}\n", .{n});
    try std.testing.expect(n == 9);
}

test "expand 5" {
    // Arena Memory Allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var ctx = try Ctx.init(alloc);
    try ctx.add_stone("125");
    try ctx.add_stone("17");

    const n = try ctx.tally(5);

    std.testing.expect(n == 13) catch std.debug.print("5. got: {d}\n", .{n});
    try std.testing.expect(n == 13);
}

pub fn run_and_debug() !void {
    // Arena Memory Allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var ctx = try Ctx.init(alloc);
    try ctx.add_stone("125");
    try ctx.add_stone("17");

    for (1..76) |i| {
        const n = try ctx.tally(i);
        std.debug.print("i: {d} | tally: {d}\n", .{ i, n });
    }
}

test "expand 6" {
    // Arena Memory Allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var ctx = try Ctx.init(alloc);
    try ctx.add_stone("125");
    try ctx.add_stone("17");

    const n = try ctx.tally(6);

    std.testing.expect(n == 22) catch std.debug.print("6 got: {d}\n", .{n});
    try std.testing.expect(n == 22);
}

test "rec expand 25" {
    // Arena Memory Allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var ctx = try Ctx.init(alloc);
    try ctx.add_stone("125");
    try ctx.add_stone("17");

    const ans_list = [_]usize{ 3, 4, 5, 9, 13, 22, 31, 42, 68, 109, 170, 235, 342, 557, 853, 1298, 1951, 2869, 4490, 6837, 10362, 15754, 23435, 36359, 55312, 83230 };

    for (ans_list, 1..) |ans, i| {
        // std.debug.print("testing: {d}\n", .{i});
        const n = try ctx.tally(i);
        // std.debug.print("i:{d}, ans:{d}, tally: {d}\n", .{ i, ans, n });
        try std.testing.expect(n == ans);
    }
}

test "struct as map key" {
    // Arena Memory Allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var set = Set.init(alloc);
    const key = Key{ .k = 1, .i = 2 };
    try set.put(key, 3);
    // std.debug.print("put (3): {any}\n", .{key});
    if (set.get(key)) |v| {
        try std.testing.expect(v == 3);
        // std.debug.print("got (3).\n", .{});
    }

    const key1 = Key{ .k = 2, .i = 2 };
    if (set.get(key1)) |v| {
        std.debug.print("key1:{any}\nfound:{any}\n", .{ key1, v });
        try std.testing.expect(v != v);
    }

    const key2 = Key{ .k = 1, .i = 3 };
    if (set.get(key2)) |v| {
        std.debug.print("key2:{any}\nfound:{any}\n", .{ key2, v });
        try std.testing.expect(v != v);
    }
    const key3 = Key{ .k = 2, .i = 3 };
    if (set.get(key3)) |v| {
        std.debug.print("key3:{any}\nfound:{any}\n", .{ key3, v });
        try std.testing.expect(v != v);
    }
}

test "fast expand 25" {
    // Arena Memory Allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var ctx = try Ctx.init(alloc);
    try ctx.add_stone("125");
    try ctx.add_stone("17");

    const ans_list = [_]usize{ 3, 4, 5, 9, 13, 22, 31, 42, 68, 109, 170, 235, 342, 557, 853, 1298, 1951, 2869, 4490, 6837, 10362, 15754, 23435, 36359, 55312, 83230 };

    var failed = false;
    for (ans_list, 1..) |ans, i| {
        const n = try ctx.tally_fast(i);
        std.debug.print("i:{d}, ans:{d}, tally: {d}\n", .{ i, ans, n });
        std.testing.expect(n == ans) catch {
            std.debug.print("i:{d}, ans:{d}, tally: {d}\n", .{ i, ans, n });
            failed = true;
        };
    }
    try std.testing.expect(failed == false);
}
