const std = @import("std");
const zxb = @import("zxb");

/// 演示如何与数据库驱动集成
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("\n=== zxb Database Integration Demo ===\n\n", .{});

    // Example 1: 基本查询
    {
        std.debug.print("Example 1: Basic Query with Prepared Statement\n", .{});
        std.debug.print("-----------------------------------------------\n", .{});
        
        var builder = zxb.of(allocator, "users");
        defer builder.deinit();

        _ = try builder.eq("status", @as(i64, 1));
        _ = try builder.eq("name", "Alice");
        _ = try builder.gte("age", @as(i64, 18));

        const sql = try builder.sqlOfSelect();
        defer allocator.free(sql);

        var args = try builder.args();
        defer args.deinit();

        std.debug.print("SQL:  {s}\n", .{sql});
        std.debug.print("Args: [", .{});
        for (args.items, 0..) |arg, i| {
            if (i > 0) std.debug.print(", ", .{});
            switch (arg) {
                .string => |s| std.debug.print("\"{s}\"", .{s}),
                .int => |n| std.debug.print("{d}", .{n}),
                .float => |f| std.debug.print("{d}", .{f}),
                .bool => |b| std.debug.print("{}", .{b}),
                .null_value => std.debug.print("NULL", .{}),
            }
        }
        std.debug.print("]\n\n", .{});

        std.debug.print("// 使用方式 (伪代码):\n", .{});
        std.debug.print("// rows = db.query(sql, args);\n", .{});
        std.debug.print("// 数据库驱动会将 ? 替换为对应的参数值\n\n", .{});
    }

    // Example 2: 复杂查询
    {
        std.debug.print("Example 2: Complex Query\n", .{});
        std.debug.print("------------------------\n", .{});
        
        var builder = zxb.of(allocator, "orders");
        defer builder.deinit();

        _ = try builder.eq("user_id", @as(i64, 123));
        _ = try builder.gte("total", @as(f64, 100.0));
        _ = try builder.lte("total", @as(f64, 1000.0));
        _ = try builder.ne("status", "cancelled");
        _ = try builder.like("product_name", "Phone");

        const sql = try builder.sqlOfSelect();
        defer allocator.free(sql);

        var args = try builder.args();
        defer args.deinit();

        std.debug.print("SQL:  {s}\n", .{sql});
        std.debug.print("Args: [", .{});
        for (args.items, 0..) |arg, i| {
            if (i > 0) std.debug.print(", ", .{});
            switch (arg) {
                .string => |s| std.debug.print("\"{s}\"", .{s}),
                .int => |n| std.debug.print("{d}", .{n}),
                .float => |f| std.debug.print("{d}", .{f}),
                .bool => |b| std.debug.print("{}", .{b}),
                .null_value => std.debug.print("NULL", .{}),
            }
        }
        std.debug.print("]\n\n", .{});
    }

    // Example 3: 自动过滤演示
    {
        std.debug.print("Example 3: Auto-Filtering\n", .{});
        std.debug.print("-------------------------\n", .{});
        
        var builder = zxb.of(allocator, "products");
        defer builder.deinit();

        _ = try builder.eq("category", "electronics");
        _ = try builder.eq("stock", @as(i64, 0)); // ✅ 会被过滤
        _ = try builder.eq("description", ""); // ✅ 会被过滤
        _ = try builder.gte("price", @as(f64, 100.0));

        const sql = try builder.sqlOfSelect();
        defer allocator.free(sql);

        var args = try builder.args();
        defer args.deinit();

        std.debug.print("SQL:  {s}\n", .{sql});
        std.debug.print("Args: [", .{});
        for (args.items, 0..) |arg, i| {
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
        std.debug.print("注意: stock=0 和 description=\"\" 被自动过滤了！\n\n", .{});
    }

    // Example 4: 模拟实际数据库使用
    {
        std.debug.print("Example 4: Simulated Database Usage\n", .{});
        std.debug.print("------------------------------------\n", .{});
        
        std.debug.print("// Zig 数据库驱动集成示例:\n", .{});
        std.debug.print("//\n", .{});
        std.debug.print("// var builder = zxb.of(allocator, \"users\");\n", .{});
        std.debug.print("// defer builder.deinit();\n", .{});
        std.debug.print("//\n", .{});
        std.debug.print("// _ = try builder.eq(\"status\", @as(i64, 1));\n", .{});
        std.debug.print("// _ = try builder.eq(\"name\", \"Alice\");\n", .{});
        std.debug.print("//\n", .{});
        std.debug.print("// const sql = try builder.sqlOfSelect();\n", .{});
        std.debug.print("// defer allocator.free(sql);\n", .{});
        std.debug.print("//\n", .{});
        std.debug.print("// var args = try builder.args();\n", .{});
        std.debug.print("// defer args.deinit();\n", .{});
        std.debug.print("//\n", .{});
        std.debug.print("// // 传给 PostgreSQL/MySQL 驱动\n", .{});
        std.debug.print("// var stmt = try db.prepare(sql);\n", .{});
        std.debug.print("// defer stmt.deinit();\n", .{});
        std.debug.print("//\n", .{});
        std.debug.print("// for (args.items) |arg| {{\n", .{});
        std.debug.print("//     try stmt.bind(arg);\n", .{});
        std.debug.print("// }}\n", .{});
        std.debug.print("//\n", .{});
        std.debug.print("// var rows = try stmt.query();\n", .{});
        std.debug.print("// defer rows.deinit();\n\n", .{});
    }

    std.debug.print("=== Demo completed! ===\n\n", .{});

    // 安全性说明
    std.debug.print("🔒 安全性优势:\n", .{});
    std.debug.print("1. ✅ 防止 SQL 注入 - 参数通过 ? 占位符传递\n", .{});
    std.debug.print("2. ✅ 类型安全 - Value union 确保类型正确\n", .{});
    std.debug.print("3. ✅ 数据库优化 - 预编译语句可被缓存\n\n", .{});
}

