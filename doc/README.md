# zxb 文档索引

欢迎查阅 **zxb (Zig eXtensible Builder)** 的文档！

## 📚 文档导航

### 快速开始

- **[Getting Started](GETTING_STARTED.md)** - 快速开始指南
  - 安装 Zig
  - 构建和测试 zxb
  - 运行示例

- **[Install Zig](INSTALL_ZIG.md)** - Zig 安装详细说明
  - Windows/macOS/Linux 安装步骤
  - 验证安装
  - 常见问题

### API 文档

- **[Quick Reference](QUICK_REFERENCE.md)** - API 速查手册 ⭐
  - 完整 API 列表
  - 使用示例
  - 常见模式
  - 内存管理

- **[Build Method](BUILD_METHOD.md)** - `build()` 方法详解
  - 为什么需要 `build()`
  - API 对比（xb/sqli）
  - 使用示例
  - 性能分析

- **[LIKE Patterns](LIKE_PATTERNS.md)** - LIKE 模式详解
  - `like()` vs `likeLeft()`
  - 为什么不提供 `likeRight()`
  - 性能对比
  - 最佳实践

### 工作原理

- **[How It Works](HOW_IT_WORKS.md)** - SQL 占位符和参数绑定详解
  - 预编译语句（Prepared Statements）
  - `?` 占位符机制
  - 防止 SQL 注入
  - 与数据库驱动集成

### 设计与架构

- **[Design Philosophy](DESIGN.md)** - 设计哲学：sqli → xb → zxb
  - 7 年演进历程
  - 为什么选择 Zig
  - AI 时代的设计理念
  - 性能与职责原子性

- **[Project Summary](PROJECT_SUMMARY.md)** - 项目总结
  - 核心概念
  - 设计原则
  - 演进历史
  - Roadmap

---

## 🔗 相关链接

- **[主 README](../README.md)** - 项目主页
- **[CHANGELOG](../CHANGELOG.md)** - 版本更新日志
- **[示例代码](../examples/)** - 完整使用示例

---

## 📖 推荐阅读顺序

### 新手入门

1. [主 README](../README.md) - 了解项目
2. [Getting Started](GETTING_STARTED.md) - 快速开始
3. [Quick Reference](QUICK_REFERENCE.md) - API 速查

### 深入理解

4. [How It Works](HOW_IT_WORKS.md) - 工作原理
5. [Build Method](BUILD_METHOD.md) - `build()` 方法
6. [LIKE Patterns](LIKE_PATTERNS.md) - LIKE 模式

### 设计理念

7. [Design Philosophy](DESIGN.md) - 设计哲学
8. [Project Summary](PROJECT_SUMMARY.md) - 项目总结

---

**zxb = Zig eXtensible Builder** 🚀

简洁、安全、AI 友好的 SQL Builder！

