# zxb 工作原理 - SQL 占位符 & 参数绑定

## 核心机制：预编译语句（Prepared Statements）

### 问题：xb 返回了 sql 和 [value]，sql 里有 = ?，然后 driver 用 value 替换？

**回答：是的！这正是预编译语句的工作方式。**

---

## 工作流程

```
1. zxb 构建查询
   ↓
2. 生成带 ? 占位符的 SQL
   ↓
3. 生成对应的参数数组
   ↓
4. 传给数据库驱动
   ↓
5. 驱动用参数替换 ? 
   ↓
6. 执行查询
```

---

## 示例演示

### Zig 代码

```zig
var builder = zxb.of(allocator, "users");
defer builder.deinit();

_ = try builder.eq("status", @as(i64, 1));
_ = try builder.eq("name", "Alice");
_ = try builder.gte("age", @as(i64, 18));

const sql = try builder.sqlOfSelect();
defer allocator.free(sql);

var args = try builder.args();
defer args.deinit();
```

### 输出

```
SQL:  SELECT * FROM users WHERE status = ? AND name = ? AND age >= ?
Args: [1, "Alice", 18]
```

### 数据库驱动做什么？

```zig
// 伪代码（实际由数据库驱动库实现）

// 1. 准备语句
var stmt = try db.prepare(sql);
//    → db 收到: "SELECT * FROM users WHERE status = ? AND name = ? AND age >= ?"

// 2. 绑定参数
try stmt.bind(args.items[0]); // 绑定 1 到第一个 ?
try stmt.bind(args.items[1]); // 绑定 "Alice" 到第二个 ?
try stmt.bind(args.items[2]); // 绑定 18 到第三个 ?

// 3. 执行
var rows = try stmt.query();
//    → db 实际执行: SELECT * FROM users WHERE status = 1 AND name = 'Alice' AND age >= 18
```

---

## 为什么用 `?` 占位符？

### ✅ **优势 1: 防止 SQL 注入**

**不安全的方式（字符串拼接）**：
```zig
// ❌ 危险！
const name = "Alice'; DROP TABLE users; --";
const sql = "SELECT * FROM users WHERE name = '" ++ name ++ "'";
// 结果: SELECT * FROM users WHERE name = 'Alice'; DROP TABLE users; --'
// 💥 数据库被删除！
```

**安全的方式（参数化查询）**：
```zig
// ✅ 安全！
_ = try builder.eq("name", "Alice'; DROP TABLE users; --");

// SQL:  SELECT * FROM users WHERE name = ?
// Args: ["Alice'; DROP TABLE users; --"]
// 
// 数据库会把整个字符串当作**普通字符串**处理，不会执行 SQL 命令
// 结果: 查询名字为 "Alice'; DROP TABLE users; --" 的用户（不存在）
```

### ✅ **优势 2: 性能优化（语句缓存）**

```
第一次执行:
  db.prepare("SELECT * FROM users WHERE status = ?")
  → 数据库编译并缓存查询计划
  
第二次执行:
  db.prepare("SELECT * FROM users WHERE status = ?")
  → 直接使用缓存的查询计划（快 10-100 倍！）
```

### ✅ **优势 3: 类型安全**

```zig
pub const Value = union(enum) {
    string: []const u8,
    int: i64,
    float: f64,
    bool: bool,
    null_value: void,
};
```

数据库驱动会根据 `Value` 的类型正确处理：
- `int` → PostgreSQL `bigint`
- `string` → 自动转义特殊字符
- `float` → PostgreSQL `double precision`

---

## 完整示例

### Example 1: 简单查询

```zig
var builder = zxb.of(allocator, "users");
defer builder.deinit();

_ = try builder.eq("id", @as(i64, 123));

const sql = try builder.sqlOfSelect();
defer allocator.free(sql);

var args = try builder.args();
defer args.deinit();

// 输出:
// SQL:  SELECT * FROM users WHERE id = ?
// Args: [123]
```

### Example 2: 复杂查询（包含 LIKE）

```zig
var builder = zxb.of(allocator, "orders");
defer builder.deinit();

_ = try builder.eq("user_id", 123);
_ = try builder.gte("total", 100.0);
_ = try builder.lte("total", 1000.0);
_ = try builder.ne("status", "cancelled");
_ = try builder.like("product_name", "Phone");      // 包含: %Phone%
_ = try builder.likeLeft("order_no", "2024");       // 前缀: 2024%

const sql = try builder.sqlOfSelect();
defer allocator.free(sql);

var args = try builder.args();
defer args.deinit();

// 输出:
// SQL:  SELECT * FROM orders WHERE user_id = ? AND total >= ? AND total <= ? AND status != ? AND product_name LIKE ? AND order_no LIKE ?
// Args: [123, 100.0, 1000.0, "cancelled", "%Phone%", "2024%"]
```

### Example 3: 自动过滤

```zig
var builder = zxb.of(allocator, "products");
defer builder.deinit();

_ = try builder.eq("category", "electronics");
_ = try builder.eq("stock", @as(i64, 0));  // ✅ 被过滤
_ = try builder.eq("description", "");     // ✅ 被过滤
_ = try builder.gte("price", @as(f64, 100.0));

const sql = try builder.sqlOfSelect();
defer allocator.free(sql);

var args = try builder.args();
defer args.deinit();

// 输出:
// SQL:  SELECT * FROM products WHERE category = ? AND price >= ?
// Args: ["electronics", 100.0]
//
// 注意: stock=0 和 description="" 被自动过滤了！
```

---

## 与数据库驱动集成

### PostgreSQL (pg.zig 或类似库)

```zig
const pg = @import("pg");

var builder = zxb.of(allocator, "users");
defer builder.deinit();

_ = try builder.eq("status", @as(i64, 1));
_ = try builder.eq("name", "Alice");

const sql = try builder.sqlOfSelect();
defer allocator.free(sql);

var args = try builder.args();
defer args.deinit();

// 使用 PostgreSQL 驱动
var conn = try pg.connect("postgres://localhost/mydb");
defer conn.deinit();

// 方式 1: 直接查询
var rows = try conn.query(sql, args.items);
defer rows.deinit();

// 方式 2: 预编译语句
var stmt = try conn.prepare(sql);
defer stmt.deinit();

for (args.items) |arg| {
    try stmt.bind(arg);
}

var rows = try stmt.execute();
defer rows.deinit();
```

### MySQL (mysql-zig 或类似库)

```zig
const mysql = @import("mysql");

var builder = zxb.of(allocator, "users");
defer builder.deinit();

_ = try builder.eq("id", @as(i64, 123));

const sql = try builder.sqlOfSelect();
defer allocator.free(sql);

var args = try builder.args();
defer args.deinit();

// 使用 MySQL 驱动
var conn = try mysql.connect(.{
    .host = "localhost",
    .user = "root",
    .database = "mydb",
});
defer conn.deinit();

var stmt = try conn.prepare(sql);
defer stmt.deinit();

try stmt.bind(args.items);
var rows = try stmt.execute();
defer rows.deinit();
```

---

## 占位符的不同风格

不同数据库使用不同的占位符：

| 数据库 | 占位符风格 | 示例 |
|--------|-----------|------|
| **PostgreSQL** | `$1, $2, $3` | `SELECT * FROM users WHERE id = $1 AND name = $2` |
| **MySQL** | `?` | `SELECT * FROM users WHERE id = ? AND name = ?` |
| **SQLite** | `?` 或 `:name` | `SELECT * FROM users WHERE id = ? AND name = :name` |

**zxb 当前使用 `?`（MySQL 风格）**

### 为什么选择 `?`？

1. ✅ **简单** - 最通用的占位符
2. ✅ **兼容性好** - MySQL, SQLite 都支持
3. ✅ **驱动可以转换** - PostgreSQL 驱动可以将 `?` 转换为 `$1, $2, $3`

---

## 安全性保证

### 🔒 防止 SQL 注入的 3 层防护

#### 1️⃣ **参数化查询**
```zig
// SQL 和数据分离
sql:  "SELECT * FROM users WHERE name = ?"
args: ["malicious'; DROP TABLE users; --"]

// 数据库不会执行 DROP，只会查询这个字符串
```

#### 2️⃣ **类型检查**
```zig
pub const Value = union(enum) {
    string: []const u8,  // 字符串会被转义
    int: i64,            // 数字类型安全
    float: f64,          // 浮点数类型安全
    bool: bool,          // 布尔值类型安全
    null_value: void,    // NULL 值安全
};
```

#### 3️⃣ **编译时验证**
```zig
// ❌ 编译错误
_ = try builder.eq("id", "not_a_number"); 
// Zig 会在编译时检测到类型错误
```

---

## 总结

### zxb 的工作流程

1. **构建查询** → `builder.eq("status", 1)`
2. **生成 SQL** → `"SELECT * FROM users WHERE status = ?"`
3. **生成参数** → `[1]`
4. **传给驱动** → `db.query(sql, args)`
5. **驱动替换** → `"SELECT * FROM users WHERE status = 1"`
6. **执行查询** → 返回结果

### 核心优势

| 特性 | 说明 |
|------|------|
| 🔒 **安全** | 防止 SQL 注入 |
| ⚡ **快速** | 语句缓存，性能优化 |
| ✅ **类型安全** | 编译时检查 |
| 🎯 **简洁** | API 清晰，易于使用 |
| 🤖 **AI 友好** | 结构简单，AI 容易生成 |

---

**运行示例**:
```bash
zig build db-example
```

查看完整的数据库集成演示！

