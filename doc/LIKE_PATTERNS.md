# LIKE 模式详解

## zxb 提供的 LIKE 方法

### 1. `like()` - 包含匹配

```zig
_ = try builder.like("name", "Alice");
// SQL: name LIKE ?
// Args: ["%Alice%"]
// 匹配: "Alice", "Alice Smith", "Bob Alice", "Alice's Store"
```

**使用场景**:
- ✅ 全文搜索
- ✅ 模糊查询
- ✅ 用户输入搜索

**性能**: 无法使用索引，全表扫描

---

### 2. `likeLeft()` - 前缀匹配

```zig
_ = try builder.likeLeft("sku", "PROD");
// SQL: sku LIKE ?
// Args: ["PROD%"]
// 匹配: "PROD001", "PROD123", "PRODUCT"
```

**使用场景**:
- ✅ SKU/订单号前缀查询
- ✅ 分类代码查询
- ✅ 时间字符串前缀（"2024-01"）
- ✅ URL 路径匹配

**性能**: ✅ **可以使用索引！**（如果字段有索引）

```sql
-- 假设 sku 字段有索引
CREATE INDEX idx_sku ON products(sku);

-- likeLeft 可以利用索引
SELECT * FROM products WHERE sku LIKE 'PROD%';  -- ✅ 使用索引

-- like 无法利用索引
SELECT * FROM products WHERE sku LIKE '%PROD%'; -- ❌ 全表扫描
```

---

## ❌ 为什么不提供 `likeRight()`？

### `likeRight()` 会是什么？

```zig
// 假设的 likeRight() 实现
_ = try builder.likeRight("email", "@gmail.com");
// SQL: email LIKE ?
// Args: ["%@gmail.com"]
// 匹配: "alice@gmail.com", "bob@gmail.com"
```

### 不提供的原因

#### 1️⃣ **性能极差**

```sql
-- 后缀匹配无法使用索引
SELECT * FROM users WHERE email LIKE '%@gmail.com';  -- ❌ 全表扫描

-- 即使有索引也无法使用
CREATE INDEX idx_email ON users(email);
-- 上面的查询仍然是全表扫描！
```

#### 2️⃣ **极少使用**

在实际开发中，后缀匹配的使用场景**极少**：

| 场景 | 更好的方案 |
|------|-----------|
| 查找所有 Gmail 用户 | 提取域名到单独字段 + 精确匹配 |
| 查找特定扩展名文件 | 提取扩展名到单独字段 |
| 查找特定后缀 | 使用反向索引或全文搜索 |

#### 3️⃣ **更好的替代方案**

**场景 1: 查找邮箱域名**

```zig
// ❌ 不推荐
_ = try builder.likeRight("email", "@gmail.com");

// ✅ 推荐: 提取域名字段
_ = try builder.eq("email_domain", "gmail.com");
```

数据库设计:
```sql
CREATE TABLE users (
    id BIGINT PRIMARY KEY,
    email VARCHAR(255),
    email_domain VARCHAR(100),  -- 提取的域名
    INDEX idx_domain (email_domain)
);
```

**场景 2: 文件扩展名**

```zig
// ❌ 不推荐
_ = try builder.likeRight("filename", ".pdf");

// ✅ 推荐: 提取扩展名字段
_ = try builder.eq("file_ext", "pdf");
```

**场景 3: 必须使用后缀匹配**

```zig
// 如果真的需要，可以手动构造
var builder = zxb.of(allocator, "users");
defer builder.deinit();

// 手动创建后缀匹配条件
const pattern = try std.fmt.allocPrint(allocator, "%{s}", .{"@gmail.com"});
defer allocator.free(pattern);

try builder.conditions.append(
    zxb.Bb.condition("LIKE", "email", zxb.Value{ .string = pattern })
);
```

---

## 性能对比

### 测试环境
- 表: `products` (1,000,000 行)
- 字段: `sku VARCHAR(50)` with INDEX

### 查询性能

| 模式 | SQL | 索引使用 | 执行时间 |
|------|-----|---------|---------|
| **精确匹配** | `sku = 'PROD123'` | ✅ 使用 | ~0.001s |
| **前缀匹配** | `sku LIKE 'PROD%'` | ✅ 使用 | ~0.01s |
| **包含匹配** | `sku LIKE '%PROD%'` | ❌ 全表扫描 | ~2.5s |
| **后缀匹配** | `sku LIKE '%123'` | ❌ 全表扫描 | ~2.5s |

**结论**: 
- ✅ `likeLeft()` 性能可接受（可使用索引）
- ❌ `likeRight()` 性能极差（无法使用索引）

---

## 使用建议

### ✅ 推荐使用

```zig
// 1. 精确匹配（最快）
_ = try builder.eq("status", "active");

// 2. 前缀匹配（可使用索引）
_ = try builder.likeLeft("order_no", "2024");
_ = try builder.likeLeft("sku", "PROD");

// 3. 包含匹配（用于搜索功能）
_ = try builder.like("product_name", keyword);
```

### ⚠️ 谨慎使用

```zig
// 包含匹配 - 只用于必要的搜索场景
_ = try builder.like("description", keyword);  // 全表扫描

// 考虑使用全文搜索引擎
// - PostgreSQL: GIN 索引 + to_tsvector
// - MySQL: FULLTEXT 索引
// - Elasticsearch / Meilisearch
```

### ❌ 避免使用

```zig
// 后缀匹配 - 性能极差
// ❌ 不要这样做
WHERE email LIKE '%@gmail.com'

// ✅ 改为提取域名字段
WHERE email_domain = 'gmail.com'
```

---

## 完整示例

```zig
const std = @import("std");
const zxb = @import("zxb");

pub fn searchProducts(
    allocator: std.mem.Allocator,
    keyword: []const u8,
    category_prefix: []const u8,
) ![]Product {
    var builder = zxb.of(allocator, "products");
    defer builder.deinit();

    // 1. 前缀匹配 - 可使用索引
    if (category_prefix.len > 0) {
        _ = try builder.likeLeft("category_code", category_prefix);
    }

    // 2. 包含匹配 - 用于搜索
    if (keyword.len > 0) {
        _ = try builder.like("name", keyword);
    }

    // 3. 精确匹配 - 最快
    _ = try builder.eq("status", 1);

    const sql = try builder.sqlOfSelect();
    defer allocator.free(sql);

    var args = try builder.args();
    defer args.deinit();

    return try db.query(Product, sql, args.items);
}
```

---

## 总结

| 方法 | 模式 | 索引 | 性能 | 使用场景 |
|------|------|------|------|---------|
| `eq()` | `= value` | ✅ | ⚡⚡⚡ | 精确匹配 |
| `likeLeft()` | `value%` | ✅ | ⚡⚡ | 前缀查询 |
| `like()` | `%value%` | ❌ | ⚡ | 全文搜索 |
| ~~`likeRight()`~~ | `%value` | ❌ | 💀 | **不提供** |

**设计原则**: 
- ✅ 只提供**有实际价值**的功能
- ✅ 避免提供**性能陷阱**
- ✅ 引导用户使用**最佳实践**

---

**zxb = Zig eXtensible Builder** 🚀

简洁、安全、性能优先！

