const std = @import("std");

pub fn part2() !usize {
    return 0;
}

test "p2" {
    var input =
        \\
        \\
    .*;
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const aa = arena.allocator();

    const n = try part2(aa, &input);

    std.testing.expect(n == 123) catch std.debug.print("Expected 123 got: {d}\n", .{n});
}

pub fn sln() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const aa = arena.allocator();

    // Read Input File
    const file = try std.fs.cwd().openFile("data/day06.txt", .{});
    defer file.close();
    const bytes = try file.readToEndAlloc(aa, 1024 * 1024);

    const sum = try part2(aa, bytes);

    std.debug.print("Day 6 Part 2: {d}", .{sum});
}
