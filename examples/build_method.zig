const std = @import("std");
const zxb = @import("zxb");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("\n=== zxb build() 方法演示 ===\n\n", .{});

    // 方式 1: 使用 build() - 一次性获取 SQL 和参数
    {
        std.debug.print("方式 1: 使用 build() 方法\n", .{});
        std.debug.print("--------------------\n", .{});

        var builder = zxb.of(allocator, "users");
        defer builder.deinit();

        _ = try builder.eq("status", 1);
        _ = try builder.eq("name", "Alice");
        _ = try builder.gte("age", 18);

        // ✅ 一次性获取 SQL 和参数
        var result = try builder.build();
        defer result.deinit(allocator);

        std.debug.print("SQL:  {s}\n", .{result.sql});
        std.debug.print("Args: [", .{});
        for (result.args.items, 0..) |arg, i| {
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

        std.debug.print("// 使用数据库驱动执行:\n", .{});
        std.debug.print("// var rows = try db.query(result.sql, result.args.items);\n\n", .{});
    }

    // 方式 2: 分别获取 SQL 和参数（兼容旧代码）
    {
        std.debug.print("方式 2: 分别获取 SQL 和参数\n", .{});
        std.debug.print("--------------------\n", .{});

        var builder = zxb.of(allocator, "orders");
        defer builder.deinit();

        _ = try builder.eq("user_id", 123);
        _ = try builder.gte("total", 100.0);

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

    // 对比 xb (Go) 的用法
    {
        std.debug.print("对比 xb (Go) 的用法\n", .{});
        std.debug.print("--------------------\n", .{});
        std.debug.print("// xb (Go):\n", .{});
        std.debug.print("// sql, args, _ := builder.Build().SqlOfSelect()\n\n", .{});

        std.debug.print("// zxb (Zig):\n", .{});
        std.debug.print("// var result = try builder.build();\n", .{});
        std.debug.print("// defer result.deinit(allocator);\n", .{});
        std.debug.print("// // result.sql, result.args\n\n", .{});
    }

    std.debug.print("=== 演示完成 ===\n\n", .{});
}

