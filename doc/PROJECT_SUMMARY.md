# zxb 项目总结

## 项目概述

**zxb** = **Z**ig e**X**tensible **B**uilder

一个受 [xb (Go)](https://github.com/fndome/xb) 启发的 Zig SQL 查询构建器，专为 **AI 时代**设计。

## 创建时间

2025-10-29

## 设计哲学

### 核心理念：相信 AI

> **"AI 时代，编程语言得相信 AI，所以 Zig 可能是一门好语言。"**

### 为什么选择 Zig？

1. **学习成本不高**
   - `!` 错误处理（Swift/Kotlin 也有）
   - `?` 可选类型（TypeScript/Rust 也有）
   - `try` 错误传播（Rust/Swift 也有）
   - `defer` 延迟执行（Go 也有）

2. **使用成本高（对人类）**
   - allocator 到处都要传递
   - try/defer 写得到处都是
   - 手动内存管理需要思考

3. **AI 开发速度太快（使用成本消失）**
   - AI 1 秒生成 1000 行代码
   - allocator？AI 自动添加
   - defer？AI 分析控制流自动插入
   - 内存安全？AI 分析并验证

### 与其他语言比较

| 特性 | **Go** | **Rust** | **Zig** |
|------|--------|----------|---------|
| **内存管理** | GC（AI 无需关心） | 生命周期（AI 困惑） | 手动（AI 可优化） |
| **错误处理** | error/nil（隐式） | Result<T,E>（显式） | !T（简洁显式） |
| **AI 友好度** | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **人类友好度** | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ |
| **性能潜力** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

## 项目结构

```
zxb/
├── build.zig              # 构建配置
├── build.zig.zon          # 依赖管理
├── .gitignore
├── LICENSE
├── README.md              # 项目文档
├── DESIGN.md              # 设计哲学
├── GETTING_STARTED.md     # 快速开始
├── INSTALL_ZIG.md         # Zig 安装指南
├── PROJECT_SUMMARY.md     # 本文件
├── src/
│   ├── main.zig          # 库入口
│   ├── value.zig         # Value 类型（tagged union）
│   ├── bb.zig            # 核心 Bb 结构体
│   └── builder.zig       # 查询构建器
└── examples/
    └── basic.zig         # 使用示例
```

## 核心设计：Bb 结构体

### 继承自 xb (Go)

```go
// xb (Go) - 4 个字段
type Bb struct {
    op    string
    key   string
    value interface{}  // 任意类型
    subs  []Bb
}
```

### zxb (Zig) 实现

```zig
// zxb (Zig) - 4 个字段
pub const Bb = struct {
    op: []const u8,        // 操作符：=, >, LIKE...
    key: []const u8,       // 字段名
    value: Value,          // 值（tagged union）
    subs: []Bb,           // 子条件（AND/OR）
};

pub const Value = union(enum) {
    string: []const u8,
    int: i64,
    float: f64,
    bool: bool,
    null_value: void,
};
```

**仅 4 个字段 - 表达所有 SQL 查询！**

## 主要特性

### 1. 自动过滤（Auto-Filtering）

```zig
var builder = zxb.of(allocator, "users");
defer builder.deinit();

_ = try builder.eq("status", @as(i64, 0));  // ✅ 自动过滤（零值）
_ = try builder.eq("name", "");             // ✅ 自动过滤（空字符串）
_ = try builder.eq("age", @as(i64, 18));    // ✅ 包含

// SQL: SELECT * FROM users WHERE age = ?
// 只有非零/非空条件被包含！
```

### 2. 链式 API

```zig
var builder = zxb.of(allocator, "users");
defer builder.deinit();

_ = try builder.eq("status", @as(i64, 1));
_ = try builder.gte("age", @as(i64, 18));
_ = try builder.like("name", "Alice");
_ = try builder.sort("created_at", zxb.DESC);
_ = builder.limit(10);

const sql = try builder.sqlOfSelect();
defer allocator.free(sql);
```

### 3. comptime 类型检查

```zig
pub fn eq(self: *Builder, key: []const u8, value: anytype) !*Builder {
    const val = Value.from(@TypeOf(value), value);  // 编译时类型转换
    // ...
}
```

### 4. 显式内存管理

```zig
// AI 可以选择最优分配器策略：

// 短生命周期 → ArenaAllocator（批量释放）
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
defer arena.deinit();
const allocator = arena.allocator();

// 长生命周期 → GeneralPurposeAllocator（精细控制）
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
defer _ = gpa.deinit();
const allocator = gpa.allocator();

// 固定大小 → FixedBufferAllocator（零堆分配）
var buffer: [4096]u8 = undefined;
var fba = std.heap.FixedBufferAllocator.init(&buffer);
const allocator = fba.allocator();
```

**AI 分析代码模式并自动选择最佳分配器！**

这在 Go 的 GC 下是不可能的！

## 演进历史

### sqli (Java) → xb (Go) → zxb (Zig)

```
2015-2022: sqli (Java)
  教训：
  - Java 太重（Spring Boot 依赖）
  - Interface 地狱（到处实现接口）
  - 3 级缓存复杂度（MyBatis L1 + sqli L2 + Spring Boot L3）
  
2023-2025: xb (Go)
  突破：
  - 轻量（零依赖）
  - 简单（4 字段 Bb 结构体）
  - AI 友好（函数组合）
  - 向量数据库支持（Qdrant/pgvector）
  
2025+: zxb (Zig)
  目标：
  - 相信 AI（给予完全控制）
  - 性能（手动内存管理）
  - comptime 魔法（零成本抽象）
```

## 对比其他框架

### MyBatis Plus (Java)
```
问题：过度封装，概念太多
- BaseMapper
- ServiceImpl
- Wrapper
- LambdaQueryWrapper
- QueryWrapper
- UpdateWrapper
- ...（概念爆炸）

AI 需要理解大量无用抽象
```

### sqli (Java)
```
改进：统一的 Builder
- 但依然很重（Spring Boot 绑定）
- 需要框架预留 interface
- 缓存复杂（3 级）

AI 可以理解，但生成代码冗长
```

### xb (Go)
```
突破：极简设计
- 仅 4 字段表达所有查询
- 零依赖
- 自动过滤

AI 完美生成，代码简洁优雅
```

### zxb (Zig)
```
终极：AI 时代优化
- 继承 xb 的简洁
- 增加性能控制
- AI 可优化内存策略

AI 生成高性能代码，无 GC 开销
```

## Roadmap

### v0.1.0（当前）
- [x] 核心 Builder（Eq, Ne, Gt, Lt, Like, Sort, Limit, Offset）
- [x] 自动过滤（nil/0/empty）
- [x] SELECT 查询生成
- [x] 单元测试
- [x] 示例代码

### v0.2.0（未来）
- [ ] INSERT 支持
- [ ] UPDATE 支持
- [ ] DELETE 支持
- [ ] IN 子句
- [ ] OR 条件
- [ ] JOIN 支持

### v1.0.0（愿景）
- [ ] 向量数据库支持（Qdrant JSON 生成）
- [ ] pgvector 支持
- [ ] 混合查询（Hybrid Search）
- [ ] 生产环境验证

## 安装使用

### 1. 安装 Zig

参考 `INSTALL_ZIG.md`

### 2. 构建项目

```bash
cd D:\MyDev\server\zxb

# 运行测试
zig build test

# 运行示例
zig build example

# 构建库
zig build
```

### 3. 集成到项目

在 `build.zig.zon` 中添加：

```zig
.dependencies = .{
    .zxb = .{
        .url = "https://github.com/fndome/zxb/archive/refs/tags/v0.1.0.tar.gz",
    },
},
```

## 引用

> **"总有一天，大模型能理解美和丑，丑陋的东西不永恒。"**

> **"AI 时代，编程语言得相信 AI。"**

> **"像 ! ，在其他语言里也很常见，可能会为 null，zig 学习成本不高，使用成本高。但 AI 编程速度太快。"**

## 致谢

- **xb (Go)**: 设计灵感 - https://github.com/fndome/xb
- **sqli (Java)**: 7 年经验积累 - https://github.com/x-ream/sqli
- **fndome**: "fn do me" - AI 来完成工作

---

**"在 AI 时代，简洁优雅的代码将胜出。"**

zxb - 为 AI 辅助开发设计的 SQL Builder 🤖✨

