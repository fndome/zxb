# build() 方法详解

## 问题：为什么需要 `build()` 方法？

在之前的版本中，获取 SQL 和参数需要**两次调用**：

```zig
// ❌ 旧方式：分别调用两个方法
const sql = try builder.sqlOfSelect();
defer allocator.free(sql);

var args = try builder.args();
defer args.deinit();

// 使用
var rows = try db.query(sql, args.items);
```

**问题**：
1. 需要记住调用两个方法
2. 需要记住分别释放内存
3. 代码啰嗦

---

## 解决方案：`build()` 方法

### ✅ 新方式：一次性获取

```zig
// ✅ 新方式：一次调用
var result = try builder.build();
defer result.deinit(allocator);

// 使用
var rows = try db.query(result.sql, result.args.items);
```

**优势**：
1. ✅ 一次调用获取所有数据
2. ✅ 一次释放内存
3. ✅ 代码更简洁
4. ✅ 与 xb (Go) 的 API 风格一致

---

## API 对比

### zxb (Zig) - 新方式

```zig
var result = try builder.build();
defer result.deinit(allocator);

// result.sql:  "SELECT * FROM users WHERE name = ?"
// result.args: ["Alice"]
```

### xb (Go)

```go
sql, args, _ := builder.Build().SqlOfSelect()

// sql:  "SELECT * FROM users WHERE name = ?"
// args: []interface{}{"Alice"}
```

### sqli (Java)

```java
Bb bb = builder.build();
String sql = bb.getSql();
Object[] args = bb.getArgs();
```

---

## QueryResult 结构体

```zig
pub const QueryResult = struct {
    sql: []const u8,              // SQL 字符串
    args: std.ArrayList(Value),   // 参数数组

    pub fn deinit(self: *QueryResult, allocator: Allocator) void {
        allocator.free(self.sql);  // 释放 SQL
        self.args.deinit();        // 释放参数
    }
};
```

---

## 使用示例

### 示例 1: 基本用法

```zig
const std = @import("std");
const zxb = @import("zxb");

pub fn getUsers(allocator: std.mem.Allocator, status: i64) ![]User {
    var builder = zxb.of(allocator, "users");
    defer builder.deinit();

    _ = try builder.eq("status", status);
    _ = try builder.sort("id", zxb.DESC);

    // ✅ 一次性获取
    var result = try builder.build();
    defer result.deinit(allocator);

    // 传给数据库驱动
    return try db.query(User, result.sql, result.args.items);
}
```

### 示例 2: 复杂查询

```zig
pub fn searchProducts(
    allocator: std.mem.Allocator,
    keyword: []const u8,
    min_price: f64,
    max_price: f64,
) ![]Product {
    var builder = zxb.of(allocator, "products");
    defer builder.deinit();

    _ = try builder.like("name", keyword);
    _ = try builder.gte("price", min_price);
    _ = try builder.lte("price", max_price);
    _ = try builder.eq("status", 1);
    _ = try builder.sort("price", zxb.ASC);
    _ = builder.limit(50);

    // ✅ 一次性获取
    var result = try builder.build();
    defer result.deinit(allocator);

    return try db.query(Product, result.sql, result.args.items);
}
```

### 示例 3: 分页

```zig
pub fn getUsersPaged(
    allocator: std.mem.Allocator,
    page: i32,
    page_size: i32,
) ![]User {
    var builder = zxb.of(allocator, "users");
    defer builder.deinit();

    _ = try builder.eq("status", 1);
    _ = try builder.sort("created_at", zxb.DESC);
    _ = builder.limit(page_size);
    _ = builder.offset((page - 1) * page_size);

    // ✅ 一次性获取
    var result = try builder.build();
    defer result.deinit(allocator);

    return try db.query(User, result.sql, result.args.items);
}
```

---

## 兼容性

### 旧代码仍然可用

```zig
// ⚠️ 旧方式（仍然支持）
const sql = try builder.sqlOfSelect();
defer allocator.free(sql);

var args = try builder.args();
defer args.deinit();

// 可以正常使用
var rows = try db.query(sql, args.items);
```

### 迁移建议

逐步迁移到 `build()` 方法：

```zig
// Before:
const sql = try builder.sqlOfSelect();
defer allocator.free(sql);
var args = try builder.args();
defer args.deinit();
var rows = try db.query(sql, args.items);

// After:
var result = try builder.build();
defer result.deinit(allocator);
var rows = try db.query(result.sql, result.args.items);
```

---

## 性能

### 开销分析

```zig
// build() 内部实现
pub fn build(self: *Builder) !QueryResult {
    const sql = try self.sqlOfSelect();        // 构建 SQL
    const query_args = try self.args();        // 构建参数
    return QueryResult{
        .sql = sql,
        .args = query_args,
    };
}
```

**结论**：
- ✅ 没有额外的内存分配
- ✅ 只是封装了两次调用
- ✅ 性能与分别调用完全一致

---

## 常见问题

### Q1: 为什么还保留 `sqlOfSelect()` 和 `args()`？

**A**: 兼容性和灵活性
- 兼容旧代码
- 某些场景只需要 SQL（如调试）
- 某些场景需要单独处理参数

### Q2: `build()` 会调用两次吗？

**A**: 不会。每个方法只会遍历一次 conditions 列表。

### Q3: 内存如何管理？

**A**: `result.deinit(allocator)` 会同时释放 SQL 和参数：

```zig
pub fn deinit(self: *QueryResult, allocator: Allocator) void {
    allocator.free(self.sql);  // 释放 SQL 字符串
    self.args.deinit();        // 释放参数数组
}
```

---

## 总结

| 方法 | 优势 | 劣势 | 推荐度 |
|------|------|------|--------|
| **`build()`** | 简洁、一致 | 无 | ⭐⭐⭐⭐⭐ |
| `sqlOfSelect()` + `args()` | 灵活 | 啰嗦 | ⭐⭐ |

**建议**：新代码优先使用 `build()`，旧代码可以逐步迁移。

---

**zxb = Zig eXtensible Builder** 🚀

简洁、安全、易用！

