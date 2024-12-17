const std = @import("std");

const Arena = std.mem.Allocator;

const Eq = struct {
    ans: usize,
    nums: []usize,

    pub fn init(arena: Arena, line: []const u8) !Eq {
        var list = std.ArrayList(usize).init(arena);
        const split = std.mem.indexOfScalar(u8, line, ':') orelse {
            std.debug.print("cant find ':' in line:\n'{s}'\n\n", .{line});
            unreachable;
        };
        var iter = std.mem.tokenizeScalar(u8, line[split + 1 ..], ' ');
        while (iter.next()) |token| {
            const n = try std.fmt.parseInt(usize, token, 10);
            try list.append(n);
        }
        return Eq{
            .ans = try std.fmt.parseInt(usize, line[0..split], 10),
            .nums = try list.toOwnedSlice(),
        };
    }

    pub fn is_valid(eq: Eq) bool {
        std.debug.print("\nEq: {d}:{any}\n", .{ eq.ans, eq.nums });
        const max = std.math.pow(usize, 2, eq.nums.len);
        for (0..max) |idx| {
            var sum: usize = 0;
            for (eq.nums, 0..) |n, i| {
                const bit = std.math.pow(usize, 2, i);
                if (idx & bit == 0) {
                    sum += n;
                } else {
                    sum *= n;
                }
            }
            if (sum == eq.ans) return true;
        }
        return false;
    }
};

pub fn sum_valid_ops(arena: Arena, bytes: []u8) !usize {
    var total: usize = 0;
    var iter = std.mem.tokenizeAny(u8, bytes, "\r\n");
    while (iter.next()) |line| {
        const eq = try Eq.init(arena, line);
        if (eq.is_valid()) {
            total += eq.ans;
            std.debug.print("valid.\n", .{});
        }
    }
    return total;
}

test "p1" {
    var input =
        \\190: 10 19
        \\3267: 81 40 27
        \\83: 17 5
        \\156: 15 6
        \\7290: 6 8 6 15
        \\161011: 16 10 13
        \\192: 17 8 14
        \\21037: 9 7 18 13
        \\292: 11 6 16 20
        \\
    .*;
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const aa = arena.allocator();
    const total = try sum_valid_ops(aa, &input);

    std.testing.expect(total == 3749) catch std.debug.print("Expected 3749 got: {d}", .{total});
}

pub fn sln() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const aa = arena.allocator();

    // Read File
    const file = try std.fs.cwd().openFile("data/day07.txt", .{});
    defer file.close();
    const bytes = try file.readToEndAlloc(aa, 1024 * 1024);

    const total = try sum_valid_ops(aa, bytes);
    std.debug.print("Day 7 Part 1:\ntotal = {d}\n", .{total});
}
