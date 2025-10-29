# zxb 快速参考

## 核心概念

### SQL 占位符 & 参数绑定

```zig
var builder = zxb.of(allocator, "users");
defer builder.deinit();

_ = try builder.eq("status", @as(i64, 1));
_ = try builder.eq("name", "Alice");

const sql = try builder.sqlOfSelect();
//    → "SELECT * FROM users WHERE status = ? AND name = ?"

var args = try builder.args();
//    → [1, "Alice"]

// 数据库驱动会将 ? 替换为对应的参数值
// 最终执行: SELECT * FROM users WHERE status = 1 AND name = 'Alice'
```

---

## API 速查

### 创建 Builder

```zig
var builder = zxb.of(allocator, "table_name");
defer builder.deinit();  // ⚠️ 必须调用！
```

### 条件方法

| 方法 | SQL | 示例 |
|------|-----|------|
| `eq(key, value)` | `=` | `builder.eq("id", 123)` ✅ |
| `ne(key, value)` | `!=` | `builder.ne("status", "banned")` |
| `gt(key, value)` | `>` | `builder.gt("age", 18)` ✅ |
| `gte(key, value)` | `>=` | `builder.gte("score", 80)` ✅ |
| `lt(key, value)` | `<` | `builder.lt("price", 100.0)` ✅ |
| `lte(key, value)` | `<=` | `builder.lte("stock", 10)` ✅ |
| `like(key, value)` | `LIKE` | `builder.like("name", "Alice")` → `%Alice%` |
| `likeLeft(key, value)` | `LIKE` | `builder.likeLeft("sku", "PROD")` → `PROD%` |

**LIKE 模式说明**:
- ✅ `like()` - 包含匹配 (`%value%`) - 最常用
- ✅ `likeLeft()` - 前缀匹配 (`value%`) - 可使用索引优化
- ❌ **不提供** `likeRight()` (`%value`) - 后缀匹配无法使用索引，性能差

### 排序 & 分页

```zig
// 排序
_ = try builder.sort("created_at", zxb.DESC);
_ = try builder.sort("id", zxb.ASC);

// 分页
_ = builder.limit(20);
_ = builder.offset(40);
```

### 生成 SQL

```zig
// ✅ 方式 1: 一次性获取（推荐）
var result = try builder.build();
defer result.deinit(allocator);  // ⚠️ 必须释放！
// result.sql, result.args

// ⚠️ 方式 2: 分别获取（兼容旧代码）
const sql = try builder.sqlOfSelect();
defer allocator.free(sql);  // ⚠️ 必须释放！

var args = try builder.args();
defer args.deinit();  // ⚠️ 必须释放！
```

---

## 完整示例

```zig
const std = @import("std");
const zxb = @import("zxb");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // 1. 创建 Builder
    var builder = zxb.of(allocator, "users");
    defer builder.deinit();

    // 2. 添加条件
    _ = try builder.eq("status", 1);    // ✅ 直接用整数
    _ = try builder.gte("age", 18);     // ✅ 简洁！
    _ = try builder.like("name", "Alice");
    _ = try builder.sort("id", zxb.DESC);
    _ = builder.limit(10);

    // 3. 生成 SQL（推荐用 build()）
    var result = try builder.build();
    defer result.deinit(allocator);

    // 4. 打印结果
    std.debug.print("SQL: {s}\n", .{result.sql});
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
    std.debug.print("]\n", .{});

    // 5. 使用数据库驱动（伪代码）
    // var rows = try db.query(sql, args.items);
}
```

---

## 自动过滤

zxb 会自动过滤以下值：

| 类型 | 过滤条件 |
|------|----------|
| `int` | `== 0` |
| `float` | `== 0.0` |
| `string` | `len == 0` |
| `null` | 总是过滤 |
| `bool` | ❌ 不过滤 |

**示例**:

```zig
_ = try builder.eq("status", 0);    // ✅ 被过滤，不会出现在 SQL 中
_ = try builder.eq("name", "");     // ✅ 被过滤
_ = try builder.eq("active", false); // ❌ 不过滤，会出现在 SQL 中
```

---

## 类型转换

```zig
// ✅ 整数（直接使用，无需 @as）
_ = try builder.eq("id", 123);          // comptime_int → i64
_ = try builder.eq("count", @as(i32, 10)); // 明确类型也可以
_ = try builder.eq("big", @as(i64, 999));  // i64
_ = try builder.eq("uint", @as(u32, 50));  // u32

// ✅ 浮点数（直接使用）
_ = try builder.eq("price", 99.99);     // comptime_float → f64
_ = try builder.eq("rate", @as(f32, 0.5)); // f32

// ✅ 字符串
_ = try builder.eq("name", "Alice");

// ✅ 布尔值
_ = try builder.eq("active", true);
```

---

## 常见模式

### 分页查询

```zig
fn getUsers(allocator: Allocator, page: i32, page_size: i32) ![]User {
    var builder = zxb.of(allocator, "users");
    defer builder.deinit();

    _ = try builder.eq("status", @as(i64, 1));
    _ = try builder.sort("created_at", zxb.DESC);
    _ = builder.limit(page_size);
    _ = builder.offset((page - 1) * page_size);

    const sql = try builder.sqlOfSelect();
    defer allocator.free(sql);

    var args = try builder.args();
    defer args.deinit();

    return try db.query(User, sql, args.items);
}
```

### 搜索功能

```zig
fn searchProducts(allocator: Allocator, keyword: []const u8) ![]Product {
    var builder = zxb.of(allocator, "products");
    defer builder.deinit();

    _ = try builder.like("name", keyword);
    _ = try builder.eq("status", @as(i64, 1));
    _ = try builder.sort("relevance", zxb.DESC);
    _ = builder.limit(50);

    const sql = try builder.sqlOfSelect();
    defer allocator.free(sql);

    var args = try builder.args();
    defer args.deinit();

    return try db.query(Product, sql, args.items);
}
```

### 范围查询

```zig
fn getOrdersByPrice(allocator: Allocator, min: f64, max: f64) ![]Order {
    var builder = zxb.of(allocator, "orders");
    defer builder.deinit();

    _ = try builder.gte("total", min);
    _ = try builder.lte("total", max);
    _ = try builder.ne("status", "cancelled");
    _ = try builder.sort("created_at", zxb.DESC);

    const sql = try builder.sqlOfSelect();
    defer allocator.free(sql);

    var args = try builder.args();
    defer args.deinit();

    return try db.query(Order, sql, args.items);
}
```

---

## 内存管理

### ✅ 正确的方式

```zig
{
    var builder = zxb.of(allocator, "users");
    defer builder.deinit();  // ✅ 自动清理

    const sql = try builder.sqlOfSelect();
    defer allocator.free(sql);  // ✅ 释放 SQL 字符串

    var args = try builder.args();
    defer args.deinit();  // ✅ 释放参数数组
}
```

### ❌ 错误的方式

```zig
var builder = zxb.of(allocator, "users");
// ❌ 忘记 defer builder.deinit()

const sql = try builder.sqlOfSelect();
// ❌ 忘记 defer allocator.free(sql)

// 💥 内存泄漏！
```

---

## 构建命令

```bash
# 运行测试
zig build test

# 运行基本示例
zig build example

# 运行数据库集成示例
zig build db-example
```

---

## 参考文档

- [README.md](../README.md) - 完整文档
- [HOW_IT_WORKS.md](./HOW_IT_WORKS.md) - 工作原理详解
- [DESIGN.md](./DESIGN.md) - 设计哲学
- [PROJECT_SUMMARY.md](./PROJECT_SUMMARY.md) - 项目总结

---

**zxb = Zig eXtensible Builder** 🚀

简洁、安全、AI 友好的 SQL Builder！

