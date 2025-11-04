# zxb - Zig SQL Or JSON Query Builder

**A lightweight, type-safe SQL Or JSON query builder for Zig, inspired by [xb (Go)](https://github.com/fndome/xb).**

> 🎉 **v0.0.4**: Builder Pattern - Dynamic default value handling for database configurations!

## Why zxb?

- ✅ **Simple**: Only 4 fields (`Bb` struct) to express all queries
- ✅ **Type-Safe**: Compile-time type checking with `anytype`
- ✅ **Auto-Filtering**: Automatically filters nil/0/empty values
- ✅ **Custom Interface**: Extensible for MySQL, Qdrant, and more (v0.2.0)
- ✅ **Zero Dependencies**: Pure Zig implementation
- ✅ **AI-Friendly**: Clean API that AI can easily understand and generate

## Core Concept

### The `Bb` (Building Block)

```zig
pub const Bb = struct {
    op: []const u8,        // Operator: "=", ">", "LIKE"...
    key: []const u8,       // Field name
    value: Value,          // Value (string/int/float/bool/null)
    subs: []Bb,           // Sub-conditions (for AND/OR)
};
```

**Just 4 fields - expressing all SQL queries!** 

Inspired by xb (Go)'s elegant design, refined over 7 years of experience from sqli (Java).

## Quick Start

### Installation

Add `zxb` to your `build.zig.zon`:

```zig
.{
    .name = "my-app",
    .version = "0.1.0",
    .dependencies = .{
        .zxb = .{
            .url = "https://github.com/fndome/zxb/archive/refs/tags/v0.1.0.tar.gz",
        },
    },
}
```

### Basic Usage

```zig
const std = @import("std");
const zxb = @import("zxb");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a query builder
    var builder = zxb.of(allocator, "users");
    defer builder.deinit();

    // Build query with chaining
    _ = try builder.eq("status", 1);      // ✅ 直接用整数
    _ = try builder.eq("role", "admin");
    _ = try builder.gte("age", 18);       // ✅ 简洁！
    _ = try builder.sort("created_at", zxb.DESC);
    _ = builder.limit(10);

    // Generate SQL
    const sql = try builder.sqlOfSelect();
    defer allocator.free(sql);

    std.debug.print("SQL: {s}\n", .{sql});
    // Output: SELECT * FROM users WHERE status = ? AND role = ? AND age >= ? ORDER BY created_at DESC LIMIT 10
}
```

## Features

### 1. Auto-Filtering

zxb automatically filters out nil, zero, and empty values:

```zig
var builder = zxb.of(allocator, "users");
defer builder.deinit();

_ = try builder.eq("status", 0);   // ✅ Filtered (zero)
_ = try builder.eq("name", "");    // ✅ Filtered (empty)
_ = try builder.eq("age", 18);     // ✅ Included

const sql = try builder.sqlOfSelect();
defer allocator.free(sql);

// SQL: SELECT * FROM users WHERE age = ?
// Only non-zero/non-empty conditions are included!
```

### 2. Rich Condition Methods

```zig
_ = try builder.eq("status", 1);          // Equal
_ = try builder.ne("role", "guest");      // Not equal
_ = try builder.gt("age", 18);            // Greater than
_ = try builder.gte("price", 100.0);      // Greater than or equal
_ = try builder.lt("stock", 1000);        // Less than
_ = try builder.lte("discount", 0.5);     // Less than or equal

// LIKE patterns
_ = try builder.like("name", "Alice");    // 包含: %Alice%
_ = try builder.likeLeft("sku", "PROD");  // 前缀: PROD%

// ✅ 支持所有整数/浮点数类型
_ = try builder.eq("id", 123);            // comptime_int
_ = try builder.eq("count", @as(i32, 10)); // i32
_ = try builder.eq("big", @as(i64, 999)); // i64
_ = try builder.eq("uint", @as(u32, 50)); // u32
```

**注意**: 
- ✅ `like()` - 包含匹配（最常用）
- ✅ `likeLeft()` - 前缀匹配（用于索引优化）
- ❌ 不提供 `likeRight()` - 后缀匹配无法使用索引，性能差，极少使用

### 3. Sorting

```zig
_ = try builder.sort("created_at", zxb.DESC);  // Descending
_ = try builder.sort("id", zxb.ASC);           // Ascending
```

### 4. Pagination

```zig
_ = builder.limit(20);   // LIMIT 20
_ = builder.offset(40);  // OFFSET 40
```

### 5. Build Query (SQL + Args)

```zig
var builder = zxb.of(allocator, "users");
defer builder.deinit();

_ = try builder.eq("name", "Alice");
_ = try builder.gte("age", 18);  // ✅ 直接用整数

// ✅ 推荐：一次性获取 SQL 和参数
var result = try builder.build();
defer result.deinit(allocator);

// result.sql:  "SELECT * FROM users WHERE name = ? AND age >= ?"
// result.args: ["Alice", 18]

// 或者分别获取（兼容旧代码）
const sql = try builder.sqlOfSelect();
defer allocator.free(sql);

var args = try builder.args();
defer args.deinit();
```

### 6. Custom Interface (v0.2.0)

Database-specific features via Custom interface:

#### MySQL with UPSERT

```zig
var builder = zxb.of(allocator, "users");
defer builder.deinit();

// ⭐ Set MySQL Custom (v0.0.4 - Builder pattern recommended)
// Method 1: Builder pattern (recommended)
var mb = zxb.MySQLBuilder.init();
const mysql_custom = mb.useUpsert(true).build();
_ = builder.custom(mysql_custom.custom());

// Method 2: Direct field setting
// var mysql = zxb.MySQLCustom.init();
// mysql.use_upsert = true;
// _ = builder.custom(mysql.custom());

_ = try builder.eq("id", 1);
_ = try builder.eq("name", "Alice");

var result = try builder.build();
defer result.deinit(allocator);
// Future: Will generate INSERT ... ON DUPLICATE KEY UPDATE ...
```

#### Qdrant Vector Database

```zig
var builder = zxb.of(allocator, "vectors");
defer builder.deinit();

// ⭐ Set Qdrant Custom (v0.0.4 - Builder pattern recommended)
// Method 1: Builder pattern (recommended - dynamic default handling)
var qb = zxb.QdrantBuilder.init();
const qdrant_custom = qb.hnswEf(512)
    .scoreThreshold(0.85)
    .withVector(false)
    .build();
_ = builder.custom(qdrant_custom.custom());

// Method 2: Direct field setting
// var qdrant = zxb.QdrantCustom.init();
// qdrant.default_hnsw_ef = 512;
// _ = builder.custom(qdrant.custom());

const json = try builder.jsonOfSelect();
defer allocator.free(json);
// Returns: {"vector": [], "limit": 10, "params": {"hnsw_ef": 512}}
```

**Architecture**:
- ✅ One `Custom` interface for all databases
- ✅ SQL databases return `SQLResult` (sql + args)
- ✅ Vector databases return JSON string
- ✅ Inspired by xb (Go) v1.1.0 design

## Comparison with Other Languages

### zxb (Zig)
```zig
var builder = zxb.of(allocator, "users");
defer builder.deinit();

_ = try builder.eq("status", @as(i64, 1));
_ = try builder.sort("id", zxb.DESC);

const sql = try builder.sqlOfSelect();
defer allocator.free(sql);
```

### xb (Go)
```go
builder := xb.Of(&User{}).
    Eq("status", 1).
    Sort("id", xb.DESC)

sql, _, _ := builder.Build().SqlOfSelect()
```

### Diesel (Rust)
```rust
users::table
    .filter(users::status.eq(1))
    .order(users::id.desc())
    .load::<User>(&mut conn)
```

## Design Philosophy

### Inspired by xb (Go)

zxb inherits xb's core principles:
1. **Simplicity** - 4 fields express all queries
2. **Explicitness** - No magic, what you see is what you get
3. **Auto-Filtering** - Reduces boilerplate code
4. **AI-Friendly** - Clean API for AI assistants

### Why Zig?

> **"In the AI era, programming languages must trust AI."**

Zig's advantages for AI-assisted development:
- ✅ **No lifetimes** - Simpler than Rust for AI to generate
- ✅ **comptime** - Elegant metaprogramming AI can understand
- ✅ **Manual memory** - AI can optimize allocator strategies
- ✅ **`!` error handling** - Simpler than Rust's `Result<T, E>`

## Building & Testing

```bash
# Build library
zig build

# Run tests
zig build test

# Run example
zig build example

# Or run example directly
zig build run-example
```

## Project Structure

```
zxb/
├── build.zig           # Build configuration
├── src/
│   ├── main.zig       # Library entry point
│   ├── value.zig      # Value type (union)
│   ├── bb.zig         # Core Bb struct
│   └── builder.zig    # Query builder
├── examples/
│   └── basic.zig      # Usage examples
├── doc/                # Documentation
│   ├── QUICK_REFERENCE.md
│   ├── HOW_IT_WORKS.md
│   ├── DESIGN.md
│   └── ...
├── LICENSE
└── README.md
```

## Roadmap

- [x] Core Builder (Eq, Ne, Gt, Lt, Like, Sort, Limit, Offset)
- [x] Auto-filtering (nil/0/empty)
- [x] SELECT query generation
- [ ] INSERT support
- [ ] UPDATE support
- [ ] DELETE support
- [ ] IN clause
- [ ] OR conditions
- [ ] JOIN support
- [ ] Vector DB support (Qdrant JSON generation)

## Comparison: sqli → xb → zxb

| Project | Language | Year | Status |
|---------|----------|------|--------|
| **sqli** | Java | 2015-2022 | 7 years of lessons learned |
| **xb** | Go | 2023-2025 | v1.0.0 - Production ready |
| **zxb** | Zig | 2025+ | Experimental - AI-optimized |

**Evolution**:
- sqli: Heavy (Spring Boot), but proven in production
- xb: Lightweight (zero dependencies), perfect for humans
- zxb: Performance-focused, designed for AI-assisted development

## Documentation

- **[Quick Reference](doc/QUICK_REFERENCE.md)** - API 速查手册
- **[How It Works](doc/HOW_IT_WORKS.md)** - SQL 占位符和参数绑定详解
- **[Build Method](doc/BUILD_METHOD.md)** - build() 方法详解
- **[LIKE Patterns](doc/LIKE_PATTERNS.md)** - LIKE 模式详解
- **[Design Philosophy](doc/DESIGN.md)** - 设计哲学：sqli → xb → zxb
- **[Getting Started](doc/GETTING_STARTED.md)** - 快速开始指南
- **[Install Zig](doc/INSTALL_ZIG.md)** - Zig 安装说明
- **[Project Summary](doc/PROJECT_SUMMARY.md)** - 项目总结

## License

Apache License 2.0

## Contributing

**我们欢迎所有形式的贡献！** 🎉

- 🐛 报告 Bug
- 💡 提出新功能
- 📝 改进文档
- 💻 提交代码

请阅读 [CONTRIBUTING.md](CONTRIBUTING.md) 了解如何参与。

## Acknowledgments

- **xb (Go)**: The design inspiration - https://github.com/fndome/xb
- **sqli (Java)**: 7 years of experience - https://github.com/x-ream/sqli
- **fndome**: "fn do me" - AI does the work

---

**"Ugly things are not eternal. In the AI era, simple and beautiful code will prevail."** 

zxb = **Z**ig e**X**tensible **B**uilder 🚀

