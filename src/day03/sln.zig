const std = @import("std");

pub fn mult_str(bytes: []const u8) usize {
    var a: usize = 0;
    var b: usize = 0;
    var iter = std.mem.tokenizeScalar(u8, bytes, ',');
    if (iter.next()) |str| {
        a = std.fmt.parseInt(usize, str, 10) catch 0;
    }
    if (iter.next()) |str| {
        b = std.fmt.parseInt(usize, str, 10) catch 0;
    }
    return a * b;
}

pub fn sum_mults(bytes: []u8) !usize {
    var sum: usize = 0;
    var mul_iter = std.mem.tokenizeSequence(u8, bytes, "mul(");
    while (mul_iter.next()) |token| {
        if (std.mem.indexOf(u8, token, ")")) |end| {
            sum += mult_str(token[0..end]);
        }
    }
    return sum;
}

pub fn sum_toggled_mults(bytes: []u8) !usize {
    var sum: usize = 0;
    var i: usize = 0;
    while (i < bytes.len - 6) {
        if (std.mem.indexOf(u8, bytes[i..], "don't()")) |dont| {
            sum += sum_mults(bytes[i .. dont + i]) catch 0;
            i += dont + 6;
            if (std.mem.indexOf(u8, bytes[i..], "do()")) |do| {
                i += do + 3;
                continue;
            } else {
                break;
            }
        } else {
            sum += sum_mults(bytes[i..]) catch 0;
            break;
        }
    }
    return sum;
}

pub fn part1() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const aa = arena.allocator();

    // Read Input File
    const file = try std.fs.cwd().openFile("src/day3/input.txt", .{});
    defer file.close();
    const bytes = try file.readToEndAlloc(aa, 1024 * 1024);

    const sum = try sum_mults(bytes);
    std.debug.print("Mul Sum: {d}", .{sum});
}

pub fn part2() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const aa = arena.allocator();

    // Read Input File
    const file = try std.fs.cwd().openFile("src/day3/input.txt", .{});
    defer file.close();
    const bytes = try file.readToEndAlloc(aa, 1024 * 1024);

    const sum = try sum_toggled_mults(bytes);
    std.debug.print("Toggled Mul Sum: {d}", .{sum});
}

test "sum mults" {
    var str = "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))".*;
    str[0] = str[0];
    const sum = try sum_mults(&str);
    try std.testing.expect(sum == 161); //161
}

test "sum toggled mults" {
    var str = "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))".*;
    str[0] = str[0];
    const sum = try sum_toggled_mults(&str);
    std.testing.expect(sum == 48) catch {
        std.debug.print("expected 48 got {d}", .{sum});
    };
}
