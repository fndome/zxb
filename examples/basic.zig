const std = @import("std");
const zxb = @import("zxb");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("\n=== zxb - Zig SQL Builder ===\n\n", .{});

    // Example 1: Basic query
    {
        std.debug.print("Example 1: Basic Query\n", .{});

        var builder = zxb.of(allocator, "users");
        defer builder.deinit();

        _ = try builder.eq("status", 1); // ✅ 直接用整数
        _ = try builder.eq("role", "admin");
        _ = try builder.sort("created_at", zxb.DESC);
        _ = builder.limit(10);

        const sql = try builder.sqlOfSelect();
        defer allocator.free(sql);

        std.debug.print("SQL: {s}\n\n", .{sql});
    }

    // Example 2: Auto-filtering
    {
        std.debug.print("Example 2: Auto-Filtering (nil/0/empty)\n", .{});

        var builder = zxb.of(allocator, "products");
        defer builder.deinit();

        _ = try builder.eq("category", "electronics");
        _ = try builder.eq("stock", 0); // ✅ 自动过滤
        _ = try builder.eq("description", ""); // ✅ 自动过滤
        _ = try builder.gte("price", 100.0); // ✅ 直接用浮点数

        const sql = try builder.sqlOfSelect();
        defer allocator.free(sql);

        std.debug.print("SQL: {s}\n", .{sql});
        std.debug.print("Note: stock=0 and empty description are auto-filtered\n\n", .{});
    }

    // Example 3: Complex query
    {
        std.debug.print("Example 3: Complex Query\n", .{});

        var builder = zxb.of(allocator, "orders");
        defer builder.deinit();

        _ = try builder.eq("user_id", 123); // ✅ 整数
        _ = try builder.gte("total", 100.0); // ✅ 浮点数
        _ = try builder.lte("total", 1000.0);
        _ = try builder.ne("status", "cancelled");
        _ = try builder.sort("created_at", zxb.DESC);
        _ = try builder.sort("id", zxb.DESC);
        _ = builder.limit(20);
        _ = builder.offset(0);

        const sql = try builder.sqlOfSelect();
        defer allocator.free(sql);

        std.debug.print("SQL: {s}\n\n", .{sql});
    }

    // Example 4: Get query arguments
    {
        std.debug.print("Example 4: Query Arguments\n", .{});

        var builder = zxb.of(allocator, "users");
        defer builder.deinit();

        _ = try builder.eq("name", "Alice");
        _ = try builder.gte("age", 18); // ✅ 简洁！

        const sql = try builder.sqlOfSelect();
        defer allocator.free(sql);

        var query_args = try builder.args();
        defer query_args.deinit();

        std.debug.print("SQL: {s}\n", .{sql});
        std.debug.print("Args count: {d}\n", .{query_args.items.len});
        for (query_args.items, 0..) |arg, i| {
            std.debug.print("  Arg[{d}]: ", .{i});
            switch (arg) {
                .string => |s| std.debug.print("string = '{s}'\n", .{s}),
                .int => |n| std.debug.print("int = {d}\n", .{n}),
                .float => |f| std.debug.print("float = {d}\n", .{f}),
                .bool => |b| std.debug.print("bool = {}\n", .{b}),
                .null_value => std.debug.print("NULL\n", .{}),
            }
        }
        std.debug.print("\n", .{});
    }

    // Example 5: LIKE patterns
    {
        std.debug.print("Example 5: LIKE Patterns\n", .{});

        var builder = zxb.of(allocator, "products");
        defer builder.deinit();

        _ = try builder.like("name", "Phone"); // 包含: %Phone%
        _ = try builder.likeLeft("sku", "PROD"); // 前缀: PROD%

        const sql = try builder.sqlOfSelect();
        defer allocator.free(sql);

        var query_args = try builder.args();
        defer query_args.deinit();

        std.debug.print("SQL: {s}\n", .{sql});
        std.debug.print("Args: [", .{});
        for (query_args.items, 0..) |arg, i| {
            if (i > 0) std.debug.print(", ", .{});
            switch (arg) {
                .string => |s| std.debug.print("\"{s}\"", .{s}),
                .int => |n| std.debug.print("{d}", .{n}),
                .float => |f| std.debug.print("{d}", .{f}),
                .bool => |b| std.debug.print("{}", .{b}),
                .null_value => std.debug.print("NULL", .{}),
            }
        }
        std.debug.print("]\n", .{});
        std.debug.print("注意: like() 生成 %Phone%, likeLeft() 生成 PROD%\n\n", .{});
    }

    std.debug.print("=== All examples completed! ===\n\n", .{});
}
