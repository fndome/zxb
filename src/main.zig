const std = @import("std");

pub const Value = @import("value.zig").Value;
pub const Bb = @import("bb.zig").Bb;
pub const Builder = @import("builder.zig").Builder;

// ⭐ Custom Interface (v0.2.0)
pub const Custom = @import("custom.zig").Custom;
pub const MySQLCustom = @import("custom.zig").MySQLCustom;
pub const QdrantCustom = @import("custom.zig").QdrantCustom;

// Re-export constants
pub const ASC = @import("builder.zig").ASC;
pub const DESC = @import("builder.zig").DESC;

/// Create a new Builder for a table
pub fn of(allocator: std.mem.Allocator, table: []const u8) Builder {
    return Builder.init(allocator, table);
}

test "basic usage" {
    const allocator = std.testing.allocator;

    var builder = of(allocator, "users");
    defer builder.deinit();

    _ = try builder.eq("status", 1); // ✅ 直接用整数字面量
    _ = try builder.eq("name", "Alice");
    _ = try builder.sort("id", DESC);
    _ = builder.limit(10);

    const sql = try builder.sqlOfSelect();
    defer allocator.free(sql);

    std.debug.print("\nGenerated SQL: {s}\n", .{sql});

    try std.testing.expect(std.mem.indexOf(u8, sql, "SELECT * FROM users") != null);
    try std.testing.expect(std.mem.indexOf(u8, sql, "WHERE") != null);
    try std.testing.expect(std.mem.indexOf(u8, sql, "ORDER BY id DESC") != null);
    try std.testing.expect(std.mem.indexOf(u8, sql, "LIMIT 10") != null);
}

test "build() method" {
    const allocator = std.testing.allocator;

    var builder = of(allocator, "users");
    defer builder.deinit();

    _ = try builder.eq("status", 1);
    _ = try builder.eq("name", "Alice");
    _ = builder.limit(10);

    // ✅ 一次性获取 SQL 和参数
    var result = try builder.build();
    defer result.deinit(allocator);

    std.debug.print("\nbuild() result:\n", .{});
    std.debug.print("SQL: {s}\n", .{result.sql});
    std.debug.print("Args: [", .{});
    for (result.args.items, 0..) |arg, i| {
        if (i > 0) std.debug.print(", ", .{});
        switch (arg) {
            .int => |n| std.debug.print("{d}", .{n}),
            .string => |s| std.debug.print("\"{s}\"", .{s}),
            else => {},
        }
    }
    std.debug.print("]\n", .{});

    try std.testing.expectEqual(@as(usize, 2), result.args.items.len);
}

test "auto-filtering" {
    const allocator = std.testing.allocator;

    var builder = of(allocator, "users");
    defer builder.deinit();

    // These should be filtered
    _ = try builder.eq("status", 0); // ✅ 零值被过滤
    _ = try builder.eq("name", ""); // ✅ 空字符串被过滤

    // This should work
    _ = try builder.eq("age", 18); // ✅ 包含

    const sql = try builder.sqlOfSelect();
    defer allocator.free(sql);

    std.debug.print("\nAuto-filtered SQL: {s}\n", .{sql});

    // Should only have age condition
    try std.testing.expect(std.mem.indexOf(u8, sql, "age") != null);
    try std.testing.expect(std.mem.indexOf(u8, sql, "status") == null);
    try std.testing.expect(std.mem.indexOf(u8, sql, "name") == null);
}

test "like patterns" {
    const allocator = std.testing.allocator;

    var builder = of(allocator, "products");
    defer builder.deinit();

    _ = try builder.like("name", "Phone"); // %Phone%
    _ = try builder.likeLeft("sku", "PROD"); // PROD%

    const sql = try builder.sqlOfSelect();
    defer allocator.free(sql);

    std.debug.print("\nLIKE patterns SQL: {s}\n", .{sql});

    try std.testing.expect(std.mem.indexOf(u8, sql, "name LIKE ?") != null);
    try std.testing.expect(std.mem.indexOf(u8, sql, "sku LIKE ?") != null);
}

test "Custom interface - MySQL" {
    const allocator = std.testing.allocator;

    var builder = of(allocator, "users");
    defer builder.deinit();

    // ⭐ Set MySQL Custom
    var mysql = MySQLCustom.withUpsert();
    _ = builder.setCustom(mysql.custom());

    _ = try builder.eq("id", 1);
    _ = try builder.eq("name", "Alice");

    var result = try builder.build();
    defer result.deinit(allocator);

    std.debug.print("\nMySQL Custom result:\n", .{});
    std.debug.print("SQL: {s}\n", .{result.sql});

    try std.testing.expect(result.sql.len > 0);
}

test "Custom interface - Qdrant JSON" {
    const allocator = std.testing.allocator;

    var builder = of(allocator, "vectors");
    defer builder.deinit();

    // ⭐ Set Qdrant Custom
    var qdrant = QdrantCustom.highPrecision();
    _ = builder.setCustom(qdrant.custom());

    const json = try builder.jsonOfSelect();
    defer allocator.free(json);

    std.debug.print("\nQdrant Custom JSON:\n{s}\n", .{json});

    try std.testing.expect(json.len > 0);
    try std.testing.expect(std.mem.indexOf(u8, json, "hnsw_ef") != null);
}
