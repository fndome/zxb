const std = @import("std");
const Value = @import("value.zig").Value;
const Allocator = std.mem.Allocator;

/// Building Block - Core structure of zxb
/// Inspired by xb (Go): 4 fields to express all queries
pub const Bb = struct {
    op: []const u8,
    key: []const u8,
    value: Value,
    subs: []Bb,

    /// Create a simple condition Bb
    pub fn condition(op: []const u8, key: []const u8, value: Value) Bb {
        return Bb{
            .op = op,
            .key = key,
            .value = value,
            .subs = &[_]Bb{},
        };
    }

    /// Create a compound Bb (AND/OR with sub-conditions)
    pub fn compound(allocator: Allocator, op: []const u8, subs: []const Bb) !Bb {
        const subs_copy = try allocator.dupe(Bb, subs);
        return Bb{
            .op = op,
            .key = "",
            .value = .{ .null_value = {} },
            .subs = subs_copy,
        };
    }

    /// Free memory for compound Bb
    pub fn deinit(self: *Bb, allocator: Allocator) void {
        if (self.subs.len > 0) {
            for (self.subs) |*sub| {
                sub.deinit(allocator);
            }
            allocator.free(self.subs);
        }
    }
};

test "Bb basic condition" {
    const bb = Bb.condition("=", "name", Value.from([]const u8, "Alice"));
    try std.testing.expectEqualStrings("=", bb.op);
    try std.testing.expectEqualStrings("name", bb.key);
}

test "Bb compound" {
    const allocator = std.testing.allocator;

    const cond1 = Bb.condition("=", "status", Value.from(i64, 1));
    const cond2 = Bb.condition(">", "age", Value.from(i64, 18));

    var bb = try Bb.compound(allocator, "AND", &[_]Bb{ cond1, cond2 });
    defer bb.deinit(allocator);

    try std.testing.expectEqualStrings("AND", bb.op);
    try std.testing.expectEqual(@as(usize, 2), bb.subs.len);
}
