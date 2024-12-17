const std = @import("std");

const DOT: usize = std.math.maxInt(usize);

const Disk = struct {
    map: []usize,
    data: []usize,

    pub fn init(arena: std.mem.Allocator, bytes: []u8) !Disk {
        // Parse Block Map
        var _map = std.ArrayList(usize).init(arena);
        var _data = std.ArrayList(usize).init(arena);
        var dot = false;
        var num: usize = 0;
        for (0..bytes.len) |i| {
            const n = try std.fmt.parseInt(usize, bytes[i .. i + 1], 10);
            try _map.append(n);
            // std.debug.print("{d},", .{num});
            if (dot) {
                try _data.appendNTimes(DOT, n);
            } else {
                try _data.appendNTimes(num, n);
                num += 1;
            }
            dot = !dot;
        }

        // Compact Data
        // std.debug.print("\nBEFORE:\n", .{});
        // log(_data.items);
        try compact(&_data);
        // std.debug.print("\nAFTER:\n", .{});
        // log(_data.items);

        return .{
            .map = try _map.toOwnedSlice(),
            .data = try _data.toOwnedSlice(),
        };
    }

    pub fn checksum(self: Disk) usize {
        var sum: usize = 0;
        for (self.data, 0..) |n, i| {
            if (n == DOT) break;
            sum += n * i;
        }
        std.debug.print("\n\n", .{});
        return sum;
    }
};
fn log(data: []usize) void {
    for (data) |n| {
        if (n == DOT) {
            std.debug.print(".", .{});
        } else {
            std.debug.print("{d}", .{n});
        }
    }
}
pub fn compact(data: *std.ArrayList(usize)) !void {
    var last: usize = data.items.len - 1;
    while (std.mem.indexOfScalar(usize, data.items, DOT)) |first| {
        for (1..data.items.len) |j| {
            last = data.items.len - j;
            if (first >= last) break;
            if (data.items[last] == DOT) continue;
            // std.debug.print("swap: {d},{d}\n", .{ first, last });
            data.items[first] = data.items[last];
            data.items[last] = DOT;
            break;
        }
        if (first >= last) break;
    }
}

test "compact" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    // var nums = [_]usize{ 0, 0, DOT, DOT, DOT, 1, 1, 1, DOT, DOT, DOT, 2, DOT, DOT, DOT, 3, 3, 3, DOT, 4, 4, DOT, 5, 5, 5, 5, DOT, 6, 6, 6, 6, DOT, 7, 7, 7, DOT, 8, 8, 8, 8, 9, 9, 9, DOT, DOT, DOT, DOT, 10, 10, 10, 10, 10, 10, 10 };
    var ans = [_]usize{ 0, 0, 10, 10, 10, 1, 1, 1, 10, 10, 10, 2, 10, 9, 9, 3, 3, 3, 9, 4, 4, 8, 5, 5, 5, 5, 8, 6, 6, 6, 6, 8, 7, 7, 7, 8, DOT, DOT, DOT, DOT, DOT, DOT, DOT, DOT, DOT, DOT, DOT, DOT, DOT, DOT, DOT, DOT, DOT, DOT };

    var input = "233313312141413140347".*;
    const disk = try Disk.init(alloc, &input);

    const eq = std.mem.eql(usize, disk.data, &ans);
    std.testing.expect(eq) catch std.debug.print("FAILED ", .{});
    std.debug.print("\n\ncompacting disk (len={d})", .{disk.data.len});
    std.debug.print("\ngot:\n", .{});
    log(disk.data);
    std.debug.print("\nans:\n", .{});
    log(&ans);
}

test "checksum" {
    // Arena Memory Allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var input = "2333133121414131402".*;
    const disk = try Disk.init(alloc, &input);
    // std.debug.print("disk: {any}\n", .{disk});
    const sum = disk.checksum();
    const ans = 1928;
    std.testing.expect(sum == ans) catch std.debug.print("FAILED ", .{});
    std.debug.print("checksum:\nans: {d}\ngot: {d}\n\n", .{ ans, sum });
}

pub fn sln() !void {
    // Read File
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    // Read File
    const file = try std.fs.cwd().openFile("data/day09.txt", .{});
    defer file.close();
    const bytes = try file.readToEndAlloc(alloc, 1024 * 1024);

    const disk = try Disk.init(alloc, bytes);

    log(disk.data);

    const sum = disk.checksum();

    std.debug.print("Day 9 Part 1\nchecksum: {d}\n\n", .{sum});
}
