const std = @import("std");
const d = @import("day11/part1.zig");
const day = @import("day11/part2.zig");

pub fn main() !void {
    try d.answers();
    try day.sln();
}

test {
    _ = day;
}
