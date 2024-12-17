const std = @import("std");

fn digit_count(num: usize) !usize {
    if (num == 0) return 1;
    for (0..1024) |i| {
        const pow = std.math.pow(usize, 10, i);
        if (num < pow) return i;
    }
    return error.NotFound;
}

test "digits" {
    var n: usize = 0;
    n = try digit_count(0);
    std.testing.expect(n == 1) catch std.debug.print("ans: 1 | got: {d}\n", .{n});
    n = try digit_count(1);
    std.testing.expect(n == 1) catch std.debug.print("ans: 1 | got: {d}\n", .{n});
    n = try digit_count(9);
    std.testing.expect(n == 1) catch std.debug.print("ans: 1 | got: {d}\n", .{n});

    n = try digit_count(10);
    std.testing.expect(n == 2) catch std.debug.print("ans: 2 | got: {d}\n", .{n});
    n = try digit_count(11);
    std.testing.expect(n == 2) catch std.debug.print("ans: 2 | got: {d}\n", .{n});
    n = try digit_count(99);
    std.testing.expect(n == 2) catch std.debug.print("ans: 2 | got: {d}\n", .{n});

    n = try digit_count(100);
    std.testing.expect(n == 3) catch std.debug.print("ans: 3 | got: {d}\n", .{n});
    n = try digit_count(101);
    std.testing.expect(n == 3) catch std.debug.print("ans: 3 | got: {d}\n", .{n});
    n = try digit_count(999);
    std.testing.expect(n == 3) catch std.debug.print("ans: 3 | got: {d}\n", .{n});

    n = try digit_count(1000);
    std.testing.expect(n == 4) catch std.debug.print("ans: 4 | got: {d}\n", .{n});
    n = try digit_count(1001);
    std.testing.expect(n == 4) catch std.debug.print("ans: 4 | got: {d}\n", .{n});
    n = try digit_count(9999);
    std.testing.expect(n == 4) catch std.debug.print("ans: 4 | got: {d}\n", .{n});
}

const Val = struct {
    left: usize,
    right: usize,
    count: usize,
};
const Set = std.AutoHashMap(usize, Val);
const List = std.ArrayList(usize);

const Iter = struct {};

const Ctx = struct {
    iters: [75]Set,
    set: Set,
    list: List,

    pub fn init(alloc: std.mem.Allocator) !Ctx {
        return .{
            .iters = .{Set.init(alloc)} ** 75,
            .set = Set.init(alloc),
            .list = List.init(alloc),
        };
    }

    pub fn add_stone(ctx: *Ctx, stone: []const u8) !void {
        const n = try std.fmt.parseInt(usize, stone, 10);
        try ctx.list.append(n);
    }

    pub fn stones(ctx: Ctx) usize {
        return ctx.list.items.len;
    }

    pub fn expand_fast(ctx: *Ctx, iter: usize) !void {
        const len = ctx.list.items.len;
        for (0..len) |_i| {
            const i = len - (_i + 1);
            const item = ctx.list.items[i];
            // std.debug.print("i:{d},item:{d}\n", .{ i, item });
            if (item == 0) {
                ctx.list.items[i] = 1;
                continue;
            }
            if (ctx.iters[iter].getPtr(item)) |v| {
                v.count += 1;
                continue;
            }
            if (ctx.set.get(item)) |v| {
                try ctx.iters[iter].put(item, v);
                // ctx.list.items[i] = v.left;
                // try ctx.list.append(v.right);
                continue;
            }
            const count = try digit_count(item);
            if (count % 2 == 1) {
                ctx.list.items[i] = item * 2024;
                continue;
            }

            const pow = std.math.pow(usize, 10, count / 2);
            const left = item / pow;
            const right = item - (left * pow);
            // ctx.list.items[i] = left;
            // try ctx.list.append(right);
            const v = Val{ .left = left, .right = right, .count = 1 };
            try ctx.iters[iter].put(item, v);
            try ctx.set.put(item, v);
        }
    }

    pub fn tally_stats(ctx: Ctx, iter: usize) usize {
        std.debug.print("tally ({d})\n", .{iter});
        var total: usize = 0;
        for (0..iter + 1) |_i| {
            const i = iter - _i;
            // std.debug.print("i:{d},iter:{d},_i:{d}\n", .{ i, iter, _i });
            var set_iter = ctx.iters[i].iterator();
            while (set_iter.next()) |pair| {
                // std.debug.print("k:{d} v:{any}\n", .{ pair.key_ptr.*, pair.value_ptr.* });

                if (i == iter) {
                    pair.value_ptr.count = 2;
                    if (iter == 0) total += 2;
                    // std.debug.print("+2\n", .{});
                    continue;
                }
                const L = pair.value_ptr.left;
                const R = pair.value_ptr.right;

                // const prev =

                // std.debug.print("i+1:\n", .{});
                // var next_iter = ctx.iters[i + 1].iterator();
                // while (next_iter.next()) |entry| {
                //     std.debug.print("k:{d} v:{any}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
                // }
                // std.debug.print("i+1.\n", .{});

                var NL: usize = 1;
                if (ctx.iters[i + 1].get(L)) |val| {
                    NL = val.count;
                }
                var NR: usize = 1;
                if (ctx.iters[i + 1].get(R)) |val| {
                    NR = val.count;
                }

                // std.debug.print("nl: {d} | nr: {d}\n", .{ NL, NR });
                pair.value_ptr.count *= NL + NR;
                if (i == 0) {
                    total += pair.value_ptr.count;
                }
            }
            // std.debug.print("i:{d},iter:{d},_i:{d}\n", .{ i, iter, _i });
        }

        total += ctx.list.items.len;

        return total;
    }
};

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
    // Expand
    for (0..75) |i| {
        // ctx.iters[i] = Set.init(alloc);
        try ctx.expand_fast(i);
        std.debug.print("{d}:  stones={d}  sets={d}\n", .{ i + 1, ctx.stones(), ctx.set.count() });
    }
    // Tally
    const result = ctx.tally_stats();
    std.debug.print("Day 11 Part 2\nstats: {d}\n", .{result});
}

test "expand fast" {

    // Arena Memory Allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var ctx = try Ctx.init(alloc);
    try ctx.add_stone("125");
    try ctx.add_stone("17");
    try ctx.expand_fast(0);
    var n = ctx.tally_stats(0);
    std.testing.expect(n == 3) catch std.debug.print("got: {d}\n", .{n});

    try ctx.expand_fast(1);
    n = ctx.tally_stats(1);
    std.testing.expect(n == 4) catch std.debug.print("got: {d}\n", .{n});

    try ctx.expand_fast(2);
    n = ctx.tally_stats(2);
    std.testing.expect(n == 5) catch std.debug.print("got: {d}\n", .{n});

    try ctx.expand_fast(3);
    n = ctx.tally_stats(3);
    std.testing.expect(n == 9) catch std.debug.print("got: {d}\n", .{n});

    try ctx.expand_fast(4);
    n = ctx.tally_stats(4);
    std.testing.expect(n == 13) catch std.debug.print("got: {d}\n", .{n});

    try ctx.expand_fast(5);
    n = ctx.tally_stats(5);
    std.testing.expect(n == 22) catch std.debug.print("got: {d}\n", .{n});
}
