const std = @import("std");

pub const Report = []usize;

pub fn is_safe(report: Report) bool {
    var prev: usize = report[0];
    const desc = (prev > report[1]);

    for (report[1..]) |lvl| {
        if (desc) {
            if (prev <= lvl or prev - lvl > 3) return false;
        } else {
            if (prev >= lvl or lvl - prev > 3) return false;
        }
        prev = lvl;
    }
    return true;
}

pub fn count_safe_reports(reports: []Report) usize {
    var num_safe: usize = 0;
    for (reports) |report| {
        if (is_safe(report)) {
            num_safe += 1;
        }
    }
    return num_safe;
}

pub fn parse_reports(aa: std.mem.Allocator, bytes: []u8) ![]Report {
    // Count Reports
    var num_lines: usize = 0;
    var iter_lines = std.mem.tokenizeAny(u8, bytes, "\r\n");
    while (iter_lines.next()) |_| {
        num_lines += 1;
    }
    iter_lines.reset();

    // Allocate result
    var reports = try aa.alloc(Report, num_lines);
    for (0..num_lines) |i_rep| {
        var num_lvl: usize = 0;
        const buf = iter_lines.next().?;
        var iter_lvl = std.mem.tokenizeAny(u8, buf, " ");
        while (iter_lvl.next()) |_| {
            num_lvl += 1;
        }
        iter_lvl.reset();
        var levels = try aa.alloc(usize, num_lvl);
        for (0..num_lvl) |i_lvl| {
            const str_lvl = iter_lvl.next().?;
            levels[i_lvl] = try std.fmt.parseInt(usize, str_lvl, 10);
        }
        reports[i_rep] = levels;
    }
    return reports;
}

pub fn sln() !usize {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const aa = arena.allocator();

    // Read Input File
    const file = try std.fs.cwd().openFile("src/day2/input.txt", .{});
    defer file.close();
    const bytes = try file.readToEndAlloc(aa, 1024 * 1024);

    const reports = try parse_reports(aa, bytes);

    // Count Safe Reports
    const num_safe = count_safe_reports(reports);

    std.debug.print("Safe Reports: {d} of {d}", .{ num_safe, reports.len });
    return num_safe;
}

test "check reports" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const aa = arena.allocator();

    var str = "7 6 4 2 1\n1 2 7 8 9\n9 7 6 2 1\n1 3 2 4 5\n8 6 4 4 1\n1 3 6 7 9\n".*;
    str[0] = str[0];
    const reports = try parse_reports(aa, &str);

    const n = count_safe_reports(reports);

    try std.testing.expect(n == 2); //2
}
