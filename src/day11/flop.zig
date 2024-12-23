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

// const Val = struct {
//     left: usize,
//     right: usize,
//     count: usize,
// };

const Pair = struct {
    left: usize,
    right: usize,
    count: usize,
};

const Solo = struct {
    v: usize,
    count: usize,
};

const PSet = std.AutoHashMap(usize, Pair);
const SSet = std.AutoHashMap(usize, Solo);
const List = std.ArrayList(usize);

const Ctx = struct {
    input: List,
    pair_set: PSet,
    solo_set: SSet,
    iter: usize,
    pairs: [76]PSet,
    solos: [76]SSet,

    pub fn init(alloc: std.mem.Allocator) !Ctx {
        return .{
            .input = List.init(alloc),
            .pairs = .{PSet.init(alloc)} ** 76,
            .solos = .{SSet.init(alloc)} ** 76,
            .pair_set = PSet.init(alloc),
            .solo_set = SSet.init(alloc),
            .iter = 0,
        };
    }

    pub fn add_stone(ctx: *Ctx, stone: []const u8) !void {
        const n = try std.fmt.parseInt(usize, stone, 10);
        try ctx.input.append(n);
    }

    pub fn handle_item(ctx: *Ctx, item: usize) !void {
        if (ctx.solos[ctx.iter].getPtr(item)) |v| {
            v.count += 1;
            return;
        }
        if (ctx.pairs[ctx.iter].getPtr(item)) |v| {
            v.count += 1;
            return;
        }
        if (ctx.solo_set.get(item)) |v| {
            try ctx.solos[ctx.iter].put(item, v);
            return;
        }
        if (ctx.pair_set.get(item)) |v| {
            try ctx.pairs[ctx.iter].put(item, v);
            return;
        }

        if (item == 0) {
            try ctx.solos[ctx.iter].put(item, .{ .v = 1, .count = 1 });
            try ctx.solo_set.put(item, .{ .v = 1, .count = 1 });
            return;
        }

        const count = try digit_count(item);
        if (count % 2 == 1) {
            try ctx.solos[ctx.iter].put(item, .{ .v = item * 2024, .count = 1 });
            try ctx.solo_set.put(item, .{ .v = item * 2024, .count = 1 });
            return;
        }

        const pow = std.math.pow(usize, 10, count / 2);
        const left = item / pow;
        const right = item - (left * pow);
        const v = Pair{ .left = left, .right = right, .count = 1 };
        try ctx.pairs[ctx.iter].put(item, v);
        try ctx.pair_set.put(item, v);
    }

    pub fn expand_fast(ctx: *Ctx) !void {
        // std.debug.print("\nExpanding: {d}\n", .{ctx.iter});

        if (ctx.iter == 0) {
            for (ctx.input.items) |item| {
                // std.debug.print("HAND: {d}\n", .{item});
                try ctx.handle_item(item);
            }
            ctx.iter += 1;
            return;
        }

        const iter = ctx.iter - 1;
        // Singles
        var solos = ctx.solos[iter].iterator();
        while (solos.next()) |entry| {
            try ctx.handle_item(entry.value_ptr.v);
        }

        // Pairs
        var pairs = ctx.pairs[iter].iterator();
        while (pairs.next()) |entry| {
            try ctx.handle_item(entry.value_ptr.left);
            try ctx.handle_item(entry.value_ptr.right);
        }
        ctx.iter += 1;
    }

    pub fn tally_stats(ctx: Ctx) usize {
        var total: usize = 0;

        // std.debug.print("\nPRE TALLY\n", .{});
        // log(ctx, 4);

        for (0..ctx.iter + 1) |_i| {
            const i = ctx.iter - _i;
            // std.debug.print("tally ({d})\n", .{i});
            var pair_iter = ctx.pairs[i].iterator();
            while (pair_iter.next()) |pair| {
                // std.debug.print("pair.\n", .{});
                const L = pair.value_ptr.left;
                var NL: usize = 1;
                if (i == ctx.iter) {
                    NL = 1;
                } else if (ctx.pairs[i + 1].get(L)) |val| {
                    NL = val.count;
                } else if (ctx.solos[i + 1].get(L)) |val| {
                    NL = val.count;
                }

                const R = pair.value_ptr.right;
                var NR: usize = 1;
                if (i == ctx.iter) {
                    NR = 1;
                } else if (ctx.pairs[i + 1].get(R)) |val| {
                    NR = val.count;
                } else if (ctx.solos[i + 1].get(R)) |val| {
                    NR = val.count;
                }

                pair.value_ptr.count *= NL + NR;
                if (i == 0) {
                    std.debug.print("i: {d}, count: {d}\n", .{ i, pair.value_ptr.count });
                    // std.debug.print("NL: {d}, NR: {d}\n", .{ NL, NR });
                    total += pair.value_ptr.count;
                }
            }

            // std.debug.print("\npair total: {d}\n", .{total});

            var solo_iter = ctx.solos[i].iterator();
            while (solo_iter.next()) |solo| {
                // std.debug.print("solo.\n", .{});
                // std.debug.print("k:{d} v:{any}\n", .{ pair.key_ptr.*, pair.value_ptr.* });
                const V = solo.value_ptr.v;
                var NV: usize = 1;
                if (i == ctx.iter) {
                    NV = 1;
                } else if (ctx.pairs[i + 1].get(V)) |val| {
                    NV = val.count;
                } else if (ctx.solos[i + 1].get(V)) |val| {
                    NV = val.count;
                }

                if (NV != 1) {
                    std.debug.print("i: {d} | NV: {d}\n", .{ i, NV });
                }

                solo.value_ptr.count *= NV;
                if (i == 0) {
                    total += solo.value_ptr.count;
                }
            }
            // std.debug.print("\npair total: {d}\n\n", .{total});
        }
        // std.debug.print("\nPOST TALLY: {d}\n", .{total});
        // log(ctx, 4);
        return total;
    }

    pub fn log(ctx: Ctx, i: usize) void {
        for (0..i) |idx| {
            std.debug.print("\ni: {d}\n", .{idx});
            std.debug.print("pairs: {d}\n", .{ctx.pairs[idx].count()});
            var pair_iter = ctx.pairs[idx].iterator();
            while (pair_iter.next()) |pair| {
                std.debug.print("k:{d} v:{any}\n", .{ pair.key_ptr.*, pair.value_ptr.* });
            }
            std.debug.print("solos: {d}\n", .{ctx.solos[idx].count()});
            var solo_iter = ctx.solos[idx].iterator();
            while (solo_iter.next()) |solo| {
                std.debug.print("k:{d} v:{any}\n", .{ solo.key_ptr.*, solo.value_ptr.* });
            }
        }
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
    for (0..75) |_| {
        // ctx.iters[i] = Set.init(alloc);
        try ctx.expand_fast();
        // std.debug.print("{d}:  stones={d}  sets={d}\n", .{ i + 1, ctx.stones(), ctx.set.count() });
    }
    // Tally
    const result = ctx.tally_stats();
    std.debug.print("Day 11 Part 2\nstats: {d}\n", .{result});
}

test "expand fast 1" {
    // Arena Memory Allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var ctx = try Ctx.init(alloc);
    try ctx.add_stone("125");
    try ctx.add_stone("17");

    try ctx.expand_fast();

    // ctx.log(1);

    const n = ctx.tally_stats();

    std.testing.expect(n == 3) catch std.debug.print("1. got: {d}\n", .{n});
    try std.testing.expect(n == 3);
}

test "expand fast 2" {
    // Arena Memory Allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var ctx = try Ctx.init(alloc);
    try ctx.add_stone("125");
    try ctx.add_stone("17");

    std.debug.print("2\n", .{});

    try ctx.expand_fast();
    try ctx.expand_fast();

    // ctx.log(2);

    const n = ctx.tally_stats();

    std.testing.expect(n == 4) catch std.debug.print("2. got: {d}\n", .{n});
    try std.testing.expect(n == 4);
}

test "expand fast 3" {
    // Arena Memory Allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var ctx = try Ctx.init(alloc);
    try ctx.add_stone("125");
    try ctx.add_stone("17");

    try ctx.expand_fast();
    try ctx.expand_fast();
    try ctx.expand_fast();

    const n = ctx.tally_stats();
    std.testing.expect(n == 5) catch std.debug.print("got: {d}\n", .{n});
    try std.testing.expect(n == 5);
}

test "expand fast 4" {
    // Arena Memory Allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var ctx = try Ctx.init(alloc);
    try ctx.add_stone("125");
    try ctx.add_stone("17");

    try ctx.expand_fast();
    try ctx.expand_fast();
    try ctx.expand_fast();
    try ctx.expand_fast();

    // 512 72 2024 2 0 2 4 2867 6032
    // ctx.log(4);

    const n = ctx.tally_stats();
    std.testing.expect(n == 9) catch std.debug.print("got: {d}\n", .{n});
    try std.testing.expect(n == 9);
}

test "expand fast 5" {
    // Arena Memory Allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var ctx = try Ctx.init(alloc);
    try ctx.add_stone("125");
    try ctx.add_stone("17");

    try ctx.expand_fast();
    try ctx.expand_fast();
    try ctx.expand_fast();
    try ctx.expand_fast();
    try ctx.expand_fast();

    const n = ctx.tally_stats();
    std.testing.expect(n == 13) catch std.debug.print("got: {d}\n", .{n});
    try std.testing.expect(n == 13);
}

pub fn run_test() !void {
    // Arena Memory Allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var ctx = try Ctx.init(alloc);
    try ctx.add_stone("125");
    try ctx.add_stone("17");

    try ctx.expand_fast();
    try ctx.expand_fast();
    try ctx.expand_fast();
    try ctx.expand_fast();
    try ctx.expand_fast();

    ctx.log(5);

    const n = ctx.tally_stats();

    ctx.log(5);

    std.testing.expect(n == 13) catch std.debug.print("got: {d}\n", .{n});
    try std.testing.expect(n == 13);
}

// test "expand fast 6" {
//     // Arena Memory Allocator
//     var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
//     defer arena.deinit();
//     const alloc = arena.allocator();
//     var ctx = try Ctx.init(alloc);
//     try ctx.add_stone("125");
//     try ctx.add_stone("17");

//     try ctx.expand_fast();
//     try ctx.expand_fast();
//     try ctx.expand_fast();
//     try ctx.expand_fast();
//     try ctx.expand_fast();
//     try ctx.expand_fast();

//     const n = ctx.tally_stats();
//     std.testing.expect(n == 22) catch std.debug.print("got: {d}\n", .{n});
//     try std.testing.expect(n == 22);
// }
