const std = @import("std");

const Claw = struct {
    ax: usize,
    ay: usize,
    bx: usize,
    by: usize,
    px: usize,
    py: usize,

    pub fn parse(str: []const u8) !Claw {
        const ax0 = std.mem.indexOfScalar(u8, str, '+').? + 1;
        const axE = ax0 + std.mem.indexOfScalar(u8, str[ax0..], ',').?;
        const ay0 = axE + std.mem.indexOfScalar(u8, str[axE..], '+').? + 1;
        const ayE = ay0 + std.mem.indexOfAny(u8, str[ay0..], "\r\n").?;
        const bx0 = ayE + std.mem.indexOfScalar(u8, str[ayE..], '+').? + 1;
        const bxE = bx0 + std.mem.indexOfScalar(u8, str[bx0..], ',').?;
        const by0 = bxE + std.mem.indexOfScalar(u8, str[bxE..], '+').? + 1;
        const byE = by0 + std.mem.indexOfAny(u8, str[by0..], "\r\n").?;
        const px0 = byE + std.mem.indexOfScalar(u8, str[byE..], '=').? + 1;
        const pxE = px0 + std.mem.indexOfScalar(u8, str[px0..], ',').?;
        const py0 = pxE + std.mem.indexOfScalar(u8, str[pxE..], '=').? + 1;
        const pyE = py0 + std.mem.indexOfAny(u8, str[py0..], "\r\n").?;
        return .{
            .ax = try std.fmt.parseInt(usize, str[ax0..axE], 10),
            .ay = try std.fmt.parseInt(usize, str[ay0..ayE], 10),
            .bx = try std.fmt.parseInt(usize, str[bx0..bxE], 10),
            .by = try std.fmt.parseInt(usize, str[by0..byE], 10),
            .px = try std.fmt.parseInt(usize, str[px0..pxE], 10),
            .py = try std.fmt.parseInt(usize, str[py0..pyE], 10),
        };
    }

    pub fn find_min_plays(claw: Claw) usize {
        var min_x: usize = 0;
        var min_y: usize = 0;
        _ = claw;
        min_x = min_x;
        min_y = min_y;
        return min_x + min_y;
    }
};

test "parsing" {
    const txt =
        \\Button A: X+94, Y+34
        \\Button B: X+22, Y+67
        \\Prize: X=8400, Y=5400
        \\
    ;
    const c = try Claw.parse(txt);
    try std.testing.expect(c.ax == 94);
    try std.testing.expect(c.ay == 34);
    try std.testing.expect(c.bx == 22);
    try std.testing.expect(c.by == 67);
    try std.testing.expect(c.px == 8400);
    try std.testing.expect(c.py == 5400);
}

pub fn sln() !void { // Arena Memory Allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    // Open and Read File
    const file = try std.fs.cwd().openFile("data/day13.txt", .{});
    defer file.close();
    const bytes = try file.readToEndAlloc(alloc, 1024 * 1024);

    var claws = std.ArrayList(Claw).init(alloc);

    var iter = std.mem.tokenizeSequence(u8, bytes, "\r\n\r\n");
    var count: usize = 0;
    while (iter.next()) |_| {
        count += 1;
    }
    std.debug.print("count: {d}\n", .{count});
    if (count > 1) iter.reset();
    while (iter.next()) |token| {
        const c = try Claw.parse(token);
        try claws.append(c);
        break;
    }

    var tokens: usize = 0;
    for (claws.items) |claw| {
        const min = claw.find_min_plays();
        tokens += min;
    }

    std.debug.print("\nDay 13 Part 1:\nmin tokens = {d}\n\n", .{tokens});
}
