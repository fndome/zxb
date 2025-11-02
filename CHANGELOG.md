# Changelog

## v0.0.3 (2025-01-XX) - API Simplification 🎨

### 🎯 设计简化（对齐 xb v1.2.0）

**Design Philosophy**: Don't add concepts to solve problems. Less is more.

### Removed
- ❌ `MySQLCustom.withUpsert()` - Use manual configuration instead
- ❌ `MySQLCustom.withIgnore()` - Use manual configuration instead
- ❌ `QdrantCustom.highPrecision()` - Use manual configuration instead
- ❌ `QdrantCustom.highSpeed()` - Use manual configuration instead

### Changed
- Only basic constructors remain: `MySQLCustom.init()`, `QdrantCustom.init()`
- Users configure via struct fields (e.g., `custom.use_upsert = true`)

### Why Simplify?
- Reduces API surface (4 fewer methods)
- Clearer: manual configuration is explicit
- Consistent with xb (Go) v1.2.0 design philosophy

### Usage

**Before (v0.0.2)**:
```zig
var mysql = MySQLCustom.withUpsert();
var qdrant = QdrantCustom.highPrecision();
```

**After (v0.0.3)**:
```zig
var mysql = MySQLCustom.init();
mysql.use_upsert = true;  // Explicit

var qdrant = QdrantCustom.init();
qdrant.default_hnsw_ef = 512;  // Explicit
```

---

## v0.0.2 (2025-01-XX) - Custom Interface 🎨

### ✨ 新特性

- **Custom Interface** - 数据库专属功能的统一抽象
  - 单一 VTable 设计，处理所有数据库类型
  - 支持 SQL 数据库（返回 `SQLResult`）和向量数据库（返回 JSON）
  - 灵感来自 xb (Go) v1.1.0 Custom 接口设计

- **官方 Custom 实现**:
  - `MySQLCustom` - MySQL 专属功能（UPSERT, INSERT IGNORE）
  - `QdrantCustom` - Qdrant 向量数据库（highPrecision/highSpeed 模式）

- **Builder 增强**:
  - `setCustom()` - 设置 Custom 实现
  - `build()` - 支持 Custom 代理
  - `jsonOfSelect()` - 生成 JSON 查询（向量数据库）

### 📊 架构设计

```zig
pub const Custom = struct {
    ptr: *anyopaque,
    vtable: *const VTable,
    
    pub const Result = union(enum) {
        sql: SQLResult,    // SQL databases
        json: []const u8,  // Vector databases
    };
};
```

**设计亮点**:
- ✅ Zig 的 VTable 模式实现多态
- ✅ Tagged Union 实现类型安全的结果
- ✅ `null` Custom 表示默认 SQL 生成

### 📖 文档

- 更新 README.md 添加 Custom 接口示例
- MySQL UPSERT 使用示例
- Qdrant JSON 生成示例

### 🧪 测试

- Custom 接口测试
- MySQLCustom 测试
- QdrantCustom 测试
- 所有测试通过 ✅

---

## v0.0.1 (2025-10-29) - 首次发布 🎉

### 🎯 首次发布

zxb (Zig eXtensible Builder) - 一个轻量、类型安全的 SQL 查询构建器，灵感来自 xb (Go)。

### 📚 文档重组

- **文档整理** - 所有文档移至 `doc/` 目录
  - `doc/QUICK_REFERENCE.md` - API 速查手册
  - `doc/HOW_IT_WORKS.md` - 工作原理详解
  - `doc/BUILD_METHOD.md` - build() 方法详解
  - `doc/LIKE_PATTERNS.md` - LIKE 模式详解
  - `doc/DESIGN.md` - 设计哲学
  - `doc/GETTING_STARTED.md` - 快速开始
  - `doc/INSTALL_ZIG.md` - Zig 安装说明
  - `doc/PROJECT_SUMMARY.md` - 项目总结
  - `doc/README.md` - 文档索引

### ✨ 新特性

- **新增 `build()` 方法** - 一次性获取 SQL 和参数
  ```zig
  var result = try builder.build();
  defer result.deinit(allocator);
  // result.sql:  "SELECT * FROM users WHERE name = ?"
  // result.args: ["Alice"]
  ```
  
  对比：
  ```go
  // xb (Go)
  sql, args, _ := builder.Build().SqlOfSelect()
  
  // zxb (Zig)
  var result = try builder.build();
  defer result.deinit(allocator);
  ```

- **新增 `likeLeft()` 方法** - 前缀匹配（`value%`），可利用索引优化
  ```zig
  _ = try builder.likeLeft("sku", "PROD");  // SQL: PROD%
  _ = try builder.likeLeft("order_no", "2024");  // SQL: 2024%
  ```

- **LIKE 模式说明**
  - ✅ `like()` - 包含匹配 (`%value%`) - 用于搜索
  - ✅ `likeLeft()` - 前缀匹配 (`value%`) - 可使用索引
  - ❌ **不提供** `likeRight()` (`%value`) - 后缀匹配无法使用索引，性能极差

### 🔧 改进

- **修复内存泄漏** - `like()` 和 `likeLeft()` 分配的字符串现在会正确释放
- **新增测试** - 添加 LIKE 模式测试用例

### 📚 文档

- 新增 `LIKE_PATTERNS.md` - LIKE 模式详解
  - 性能对比（精确匹配 vs 前缀匹配 vs 包含匹配 vs 后缀匹配）
  - 为什么不提供 `likeRight()`
  - 最佳实践和使用建议
- 更新 `README.md` - 添加 LIKE 模式说明
- 更新 `QUICK_REFERENCE.md` - 添加 LIKE 方法速查表
- 更新 `HOW_IT_WORKS.md` - 添加 LIKE 示例

### 🎯 核心特性

#### 查询构建

- **支持整数/浮点数字面量** - 不再需要 `@as(i64, ...)` 强制转换
  ```zig
  // ❌ 旧方式（繁琐）
  _ = try builder.eq("status", @as(i64, 1));
  _ = try builder.gte("price", @as(f64, 100.0));
  
  // ✅ 新方式（简洁）
  _ = try builder.eq("status", 1);
  _ = try builder.gte("price", 100.0);
  ```

- **支持所有整数类型** - `i32`, `i64`, `u32`, `u64`, `i16`, `i8` 等
  ```zig
  _ = try builder.eq("id", 123);           // comptime_int
  _ = try builder.eq("count", @as(i32, 10)); // i32
  _ = try builder.eq("big", @as(i64, 999));  // i64
  _ = try builder.eq("uint", @as(u32, 50));  // u32
  ```

- **支持所有浮点数类型** - `f32`, `f64`
  ```zig
  _ = try builder.eq("price", 99.99);       // comptime_float
  _ = try builder.eq("rate", @as(f32, 0.5)); // f32
  ```

### 🔧 改进

- 更新所有示例代码使用简洁语法
- 更新文档展示最佳实践
- 添加类型测试验证

### 📚 文档

- 新增 `HOW_IT_WORKS.md` - SQL 占位符和参数绑定详解
- 新增 `QUICK_REFERENCE.md` - API 快速参考
- 新增 `examples/database_usage.zig` - 数据库集成示例

---

## v0.1.0 (2025-10-29)

### 🎉 首次发布

#### ✨ 核心特性

- **4 字段 Bb 结构体** - 简洁设计，表达所有 SQL 查询
- **自动过滤** - 自动过滤 nil/0/empty 值
- **链式 API** - 流畅的查询构建体验
- **类型安全** - 编译时类型检查
- **预编译语句** - 生成带 `?` 占位符的 SQL

#### 📦 条件方法

- `eq(key, value)` - 等于
- `ne(key, value)` - 不等于
- `gt(key, value)` - 大于
- `gte(key, value)` - 大于等于
- `lt(key, value)` - 小于
- `lte(key, value)` - 小于等于
- `like(key, value)` - LIKE（自动添加 `%`）

#### 🔧 排序 & 分页

- `sort(field, direction)` - 排序（ASC/DESC）
- `limit(n)` - 限制结果数量
- `offset(n)` - 跳过前 N 条记录

#### 📚 文档

- `README.md` - 完整项目文档
- `DESIGN.md` - 设计哲学（sqli → xb → zxb）
- `PROJECT_SUMMARY.md` - 项目总结
- `INSTALL_ZIG.md` - Zig 安装指南
- `GETTING_STARTED.md` - 快速开始

#### 🧪 测试 & 示例

- 完整单元测试覆盖
- `examples/basic.zig` - 基本用法示例
- Zig 0.14.1 兼容

---

**zxb = Zig eXtensible Builder** 🚀

继承 xb (Go) 的简洁设计，专为 AI 时代优化！

