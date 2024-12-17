const std = @import("std");

const Rule = struct {
    a: usize,
    b: usize,

    pub fn init(str: []const u8) !Rule {
        var _a: usize = 0;
        var _b: usize = 0;
        var iter = std.mem.tokenizeScalar(u8, str, '|');
        if (iter.next()) |token| {
            // std.debug.print("rule token: '{s}'\n", .{token});
            _a = try std.fmt.parseInt(usize, token, 10);
        }
        if (iter.next()) |token| {
            _b = try std.fmt.parseInt(usize, token, 10);
        }
        return Rule{
            .a = _a,
            .b = _b,
        };
    }
};

const Job = struct {
    pages: []usize,

    pub fn init(aa: std.mem.Allocator, str: []const u8) !Job {
        var list = std.ArrayList(usize).init(aa);
        var iter = std.mem.tokenizeAny(u8, str, " ,");
        while (iter.next()) |token| {
            const n = try std.fmt.parseInt(usize, token, 10);
            try list.append(n);
        }
        return .{
            .pages = try list.toOwnedSlice(),
        };
    }
};

const PrintQ = struct {
    rules: []Rule,
    jobs: []Job,

    pub fn init(aa: std.mem.Allocator, bytes: []u8) !PrintQ {
        // Parse Sections
        const rn = std.mem.indexOf(u8, bytes, "\r\n\r\n");
        const split = rn orelse std.mem.indexOf(u8, bytes, "\n\n").?;
        var start = split + 2;
        if (rn) |_| {
            start = split + 4;
        }

        // Parse Rules
        // std.debug.print("\nrules text:\n'{s}'\n\n", .{bytes[0..split]});
        var rules = std.ArrayList(Rule).init(aa);
        var lines_iter = std.mem.tokenizeAny(u8, bytes[0..split], "\r\n");
        while (lines_iter.next()) |line| {
            const rule = try Rule.init(line);
            try rules.append(rule);
        }

        // Parse Jobs
        // std.debug.print("\njobs text:\n'{s}'\n\n", .{bytes[start..]});
        var jobs = std.ArrayList(Job).init(aa);
        lines_iter = std.mem.tokenizeAny(u8, bytes[start..], "\r\n");
        while (lines_iter.next()) |line| {
            const job = try Job.init(aa, line);
            try jobs.append(job);
        }

        return .{
            .rules = try rules.toOwnedSlice(),
            .jobs = try jobs.toOwnedSlice(),
        };
    }
};

pub fn passes_rules(rules: []Rule, job: Job) bool {
    for (rules) |rule| {
        const a = std.mem.indexOfScalar(usize, job.pages, rule.a) orelse continue;
        const b = std.mem.indexOfScalar(usize, job.pages, rule.b) orelse continue;
        if (b < a) return false;
    }
    return true;
}

pub fn sum_mid_pages(aa: std.mem.Allocator, input: []u8) !usize {
    const queue = try PrintQ.init(aa, input);
    var sum: usize = 0;
    var count: usize = 0;
    for (queue.jobs) |job| {
        // std.debug.print("checking job: {any}\n", .{job.pages});
        if (passes_rules(queue.rules, job)) {
            sum += job.pages[job.pages.len / 2];
            count += 1;
        }
    }
    std.debug.print("{d} of {d} jobs pass\n", .{ count, queue.jobs.len });
    return sum;
}

test "p1" {
    var input =
        \\47|53
        \\97|13
        \\97|61
        \\97|47
        \\75|29
        \\61|13
        \\75|53
        \\29|13
        \\97|29
        \\53|29
        \\61|53
        \\97|53
        \\61|29
        \\47|13
        \\75|47
        \\97|75
        \\47|61
        \\75|61
        \\47|29
        \\75|13
        \\53|13
        \\
        \\75,47,61,53,29
        \\97,61,53,29,13
        \\75,29,13
        \\75,97,47,61,53
        \\61,13,29
        \\97,13,75,29,47
        \\
    .*;
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const aa = arena.allocator();

    const n = try sum_mid_pages(aa, &input);

    std.testing.expect(n == 143) catch std.debug.print("Expected 143 got: {d}\n", .{n});
}

pub fn sln() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const aa = arena.allocator();

    // Read Input File
    const file = try std.fs.cwd().openFile("src/day5/input.txt", .{});
    defer file.close();
    const bytes = try file.readToEndAlloc(aa, 1024 * 1024);

    const sum = try sum_mid_pages(aa, bytes);

    std.debug.print("Middle Page Sum: {d}", .{sum});
}
