# zxb v0.0.1 发布命令

## 版本号说明

根据 Zig 惯例：
- **`build.zig.zon`**: `"0.0.1"` ✅（不带 v）
- **Git tag**: `v0.0.1` ✅（带 v）

---

## 提交步骤

### 1. 最终测试

```bash
cd D:\MyDev\server\zxb

# 运行测试
zig build test

# 运行所有示例
zig build example
zig build db-example
zig build build-example
```

### 2. 提交代码

```bash
# 查看状态
git status

# 添加所有文件
git add -A

# 提交（使用准备好的提交消息）
git commit -F COMMIT_v0.0.1.txt

# 或者手动输入提交消息
git commit -m "feat: zxb v0.0.1 - Zig SQL Query Builder 初始版本

核心特性：
- 4 字段 Bb 结构体
- 自动过滤 nil/0/empty
- build() 方法一次性返回 SQL 和参数
- like/likeLeft LIKE 模式
- 完整文档体系

Zig 0.14.1 兼容"
```

### 3. 创建标签

```bash
# 创建带注释的标签（推荐）
git tag -a v0.0.1 -m "zxb v0.0.1 - 首次发布

Zig eXtensible Builder - 简洁、安全、AI 友好的 SQL Builder

核心特性：
- 4 字段 Bb 结构体
- 自动过滤
- build() 方法
- LIKE 模式优化
- 完整文档

继承 xb (Go) 设计，专为 AI 时代优化。"

# 或创建轻量标签
# git tag v0.0.1
```

### 4. 推送到 GitHub

```bash
# 推送代码
git push origin main

# 推送标签
git push origin v0.0.1

# 或一次性推送所有
git push origin main --tags
```

### 5. 创建 GitHub Release

1. 访问 https://github.com/fndome/zxb/releases/new
2. 选择标签: `v0.0.1`
3. 标题: **zxb v0.0.1 - Zig SQL Query Builder**
4. 描述:

```markdown
# zxb v0.0.1 - 首次发布 🎉

**Zig eXtensible Builder** - 一个轻量、类型安全的 SQL 查询构建器，灵感来自 [xb (Go)](https://github.com/fndome/xb)。

## 🎯 核心特性

- ✅ **4 字段 Bb 结构体** - 简洁设计表达所有查询
- ✅ **自动过滤** - 自动过滤 nil/0/empty 值
- ✅ **build() 方法** - 一次性返回 SQL 和参数
- ✅ **LIKE 模式** - `like()` 包含匹配 + `likeLeft()` 前缀匹配
- ✅ **类型安全** - comptime 编译时检查
- ✅ **零依赖** - 纯 Zig 实现

## 📦 安装

添加到 `build.zig.zon`:

\```zig
.dependencies = .{
    .zxb = .{
        .url = "https://github.com/fndome/zxb/archive/refs/tags/v0.0.1.tar.gz",
        .hash = "1220...", // zig fetch 会自动计算
    },
},
\```

## 🚀 快速开始

\```zig
const zxb = @import("zxb");

var builder = zxb.of(allocator, "users");
defer builder.deinit();

_ = try builder.eq("status", 1);
_ = try builder.gte("age", 18);
_ = try builder.sort("id", zxb.DESC);

var result = try builder.build();
defer result.deinit(allocator);

// result.sql:  "SELECT * FROM users WHERE status = ? AND age >= ? ORDER BY id DESC"
// result.args: [1, 18]
\```

## 📚 文档

- [Quick Reference](doc/QUICK_REFERENCE.md) - API 速查
- [How It Works](doc/HOW_IT_WORKS.md) - 工作原理
- [Design Philosophy](doc/DESIGN.md) - 设计哲学
- [CONTRIBUTING.md](CONTRIBUTING.md) - 贡献指南

## 🎯 设计理念

> **"不添加多余的方法，但在未来，可以成为其他组件的参数"**

- **职责原子性 > 性能** - QueryResult 作为完整对象
- **简洁 > 复杂** - 仅 4 字段表达所有查询
- **AI 友好** - 清晰的 API，AI 容易理解和生成

## 🌟 演进历程

\```
sqli (Java) 2015-2022 → xb (Go) 2023-2025 → zxb (Zig) 2025+
\```

## 🤝 参与贡献

我们欢迎所有形式的贡献！请阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。

---

**zxb = Zig eXtensible Builder** 🚀

"总有一天，大模型能理解美和丑，丑陋的东西不永恒。"
```

5. 点击 "Publish release"

---

## 验证发布

```bash
# 验证标签
git tag -l
git show v0.0.1

# 验证远程标签
git ls-remote --tags origin
```

---

## 下一步

1. ⭐ **README Badges** - 添加版本、许可证徽章
2. 📢 **宣传** - 在 Zig 社区分享（ziggit.dev, Reddit, Twitter）
3. 🤝 **欢迎贡献者** - 创建 Good First Issue
4. 📈 **持续改进** - 收集反馈，迭代优化

