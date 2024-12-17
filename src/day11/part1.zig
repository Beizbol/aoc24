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

pub fn expand(list: *std.ArrayList(usize)) !void {
    const len = list.items.len;
    for (0..len) |_i| {
        const i = len - (_i + 1);
        const item = list.items[i];
        if (item == 0) {
            list.items[i] = 1;
            continue;
        }
        const count = try digit_count(item);
        if (count % 2 == 0) {
            const half = count / 2;
            const pow = std.math.pow(usize, 10, half);
            const left = item / pow;
            const right = item - (left * pow);
            list.items[i] = right;
            try list.insert(i, left);
            continue;
        }
        list.items[i] = list.items[i] * 2024;
    }
}

test "expand" {

    // Arena Memory Allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var list = std.ArrayList(usize).init(alloc);
    try list.append(125);
    try list.append(17);

    try expand(&list);
    const ans = [_]usize{ 253000, 1, 7 };
    var eq = std.mem.eql(usize, list.items, &ans);
    std.testing.expect(eq) catch std.debug.print("got: {any}\n", .{list.items});

    try expand(&list);
    const ans1 = [_]usize{ 253, 0, 2024, 14168 };
    eq = std.mem.eql(usize, list.items, &ans1);
    try std.testing.expect(eq);

    try expand(&list);
    const ans2 = [_]usize{ 512072, 1, 20, 24, 28676032 };
    eq = std.mem.eql(usize, list.items, &ans2);
    try std.testing.expect(eq);

    try expand(&list);
    const ans3 = [_]usize{ 512, 72, 2024, 2, 0, 2, 4, 2867, 6032 };
    eq = std.mem.eql(usize, list.items, &ans3);
    try std.testing.expect(eq);

    try expand(&list);
    const ans4 = [_]usize{ 1036288, 7, 2, 20, 24, 4048, 1, 4048, 8096, 28, 67, 60, 32 };
    eq = std.mem.eql(usize, list.items, &ans4);
    try std.testing.expect(eq);

    try expand(&list);
    const ans5 = [_]usize{ 2097446912, 14168, 4048, 2, 0, 2, 4, 40, 48, 2024, 40, 48, 80, 96, 2, 8, 6, 7, 6, 0, 3, 2 };
    eq = std.mem.eql(usize, list.items, &ans5);
    try std.testing.expect(eq);
}

pub fn sln() !void {
    // Arena Memory Allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    // Open and Read File
    const file = try std.fs.cwd().openFile("data/day11.txt", .{});
    defer file.close();
    const bytes = try file.readToEndAlloc(alloc, 1024 * 1024);

    var stones = std.ArrayList(usize).init(alloc);
    // Parse
    var iter = std.mem.tokenizeAny(u8, bytes, " \r\n");
    while (iter.next()) |token| {
        const n = try std.fmt.parseInt(usize, token, 10);
        try stones.append(n);
    }
    // Expand
    for (0..25) |i| {
        try expand(&stones);
        std.debug.print("{d}: {d}\n", .{ i, stones.items.len });
    }
    std.debug.print("Day 11 Part 1\nstones: {d}\n", .{stones.items.len});
}
