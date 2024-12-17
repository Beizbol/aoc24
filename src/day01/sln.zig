const std = @import("std");

pub fn list_distance(a: []usize, b: []usize) usize {
    var dist: usize = 0;

    std.mem.sort(usize, a, {}, std.sort.asc(usize));
    std.mem.sort(usize, b, {}, std.sort.asc(usize));

    for (a, b) |x, y| {
        dist += @max(x, y) - @min(x, y);
    }

    return dist;
}

test "list dist" {
    var a = [_]usize{ 3, 4, 2, 1, 3, 3 };
    var b = [_]usize{ 4, 3, 5, 3, 9, 3 };

    const d = list_distance(&a, &b);

    try std.testing.expect(d == 11); //11
}

pub fn part1() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const aa = arena.allocator();

    const file = try std.fs.cwd().openFile("src/day1/input1.txt", .{});

    const bytes = try file.readToEndAlloc(aa, 1024 * 1024);
    var iter = std.mem.tokenizeAny(u8, bytes, " \r\n");
    var flag = false;

    var a = std.ArrayList(usize).init(aa);
    var b = std.ArrayList(usize).init(aa);

    while (iter.next()) |str| {
        std.debug.print("str: {s}\n", .{str});
        const num = try std.fmt.parseInt(usize, str, 10);
        if (flag) {
            try a.append(num);
        } else {
            try b.append(num);
        }
        flag = !flag;
    }

    const result = list_distance(a.items, b.items);
    std.debug.print("Total List Distance: {d}", .{result});
}

pub fn mult_by_count_and_sum(a: []usize, b: []usize) usize {
    var total: usize = 0;

    std.mem.sort(usize, a, {}, std.sort.asc(usize));
    std.mem.sort(usize, b, {}, std.sort.asc(usize));

    for (a) |x| {
        const needle = [_]usize{x};
        const count = std.mem.count(usize, b, &needle);
        total += x * count;
    }

    return total;
}

test "mult sum" {
    var a = [_]usize{ 3, 4, 2, 1, 3, 3 };
    var b = [_]usize{ 4, 3, 5, 3, 9, 3 };

    const n = mult_by_count_and_sum(&a, &b);

    try std.testing.expect(n == 31); //31
}

pub fn part2() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const aa = arena.allocator();

    const file = try std.fs.cwd().openFile("src/day01/input1.txt", .{});
    defer file.close();

    const bytes = try file.readToEndAlloc(aa, 1024 * 1024);
    var iter = std.mem.tokenizeAny(u8, bytes, " \r\n");
    var flag = false;

    var a = std.ArrayList(usize).init(aa);
    var b = std.ArrayList(usize).init(aa);

    while (iter.next()) |str| {
        std.debug.print("str: {s}\n", .{str});
        const num = try std.fmt.parseInt(usize, str, 10);
        if (flag) {
            try a.append(num);
        } else {
            try b.append(num);
        }
        flag = !flag;
    }

    const result = mult_by_count_and_sum(a.items, b.items);
    std.debug.print("Mult Count Sum: {d}", .{result});
}
