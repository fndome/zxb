# Contributing to zxb

欢迎参与 **zxb (Zig eXtensible Builder)** 的开发！🎉

---

## 🌟 为什么参与 zxb？

- ✅ **简洁优雅** - 仅 4 字段表达所有 SQL 查询
- ✅ **AI 友好** - 为 AI 时代设计的清晰 API
- ✅ **实战验证** - 继承 sqli (Java) 7 年经验 + xb (Go) 生产实践
- ✅ **技术前沿** - Zig + comptime + 性能优化
- ✅ **成长机会** - 学习 Zig、ORM 设计、AI 时代架构

---

## 🎯 我们需要什么帮助？

### 1. 核心功能

- [ ] **INSERT 支持** - 插入语句构建
- [ ] **UPDATE 支持** - 更新语句构建
- [ ] **DELETE 支持** - 删除语句构建
- [ ] **IN 子句** - `WHERE id IN (1, 2, 3)`
- [ ] **OR 条件** - 复杂条件组合
- [ ] **JOIN 支持** - 多表关联查询
- [ ] **子查询** - 嵌套查询支持

### 2. 数据库适配

- [ ] **PostgreSQL 驱动集成** - 实际项目验证
- [ ] **MySQL 驱动集成** - 实际项目验证
- [ ] **SQLite 驱动集成** - 轻量级场景
- [ ] **占位符适配** - `?` vs `$1` 自动转换

### 3. 向量数据库支持

- [ ] **Qdrant 支持** - 向量查询 JSON 生成
- [ ] **pgvector 支持** - PostgreSQL 向量扩展
- [ ] **Milvus 支持** - 大规模向量检索

### 4. 文档 & 示例

- [ ] **英文文档** - 翻译所有中文文档
- [ ] **更多示例** - 实际应用场景（RAG、搜索、监控...）
- [ ] **视频教程** - 快速上手指南
- [ ] **博客文章** - 设计理念、性能对比

### 5. 工具 & 测试

- [ ] **性能基准测试** - vs 手写 SQL、vs 其他 ORM
- [ ] **模糊测试** - 发现边界问题
- [ ] **CI/CD** - GitHub Actions 自动化
- [ ] **代码覆盖率** - 提升到 95%+

---

## 🚀 如何开始？

### 第一步：Fork & Clone

```bash
# 1. Fork 项目到你的 GitHub
# https://github.com/fndome/zxb -> 点击 Fork

# 2. Clone 你的 Fork
git clone https://github.com/YOUR_USERNAME/zxb.git
cd zxb

# 3. 添加上游仓库
git remote add upstream https://github.com/fndome/zxb.git
```

### 第二步：安装 Zig

```bash
# Windows (Scoop)
scoop install zig

# macOS
brew install zig

# Linux
# 从 https://ziglang.org/download/ 下载

# 验证
zig version  # 需要 0.14.0+
```

### 第三步：运行测试

```bash
# 编译库
zig build

# 运行测试
zig build test

# 运行示例
zig build example
```

---

## 💻 开发流程

### 1. 创建分支

```bash
# 同步上游最新代码
git fetch upstream
git checkout main
git merge upstream/main

# 创建功能分支
git checkout -b feature/insert-support
# 或
git checkout -b fix/memory-leak
```

### 2. 编写代码

#### 代码风格

```zig
// ✅ 好的代码
pub fn eq(self: *Builder, key: []const u8, value: anytype) !*Builder {
    const val = Value.from(@TypeOf(value), value);
    if (val.shouldFilter()) {
        return self; // Auto-filter
    }
    try self.conditions.append(Bb.condition("=", key, val));
    return self;
}

// ❌ 不好的代码
pub fn eq(self:*Builder,key:[]const u8,value:anytype)!*Builder{
    // 缺少空格，难以阅读
}
```

#### 命名规范

- **函数**: `camelCase` - `eq()`, `sqlOfSelect()`
- **类型**: `PascalCase` - `Builder`, `QueryResult`
- **常量**: `UPPER_SNAKE_CASE` - `ASC`, `DESC`

#### 注释

```zig
/// Add an equality condition (auto-filter nil/0/empty)
/// 添加相等条件（自动过滤 nil/0/空值）
pub fn eq(self: *Builder, key: []const u8, value: anytype) !*Builder {
    // ...
}
```

### 3. 编写测试

```zig
test "insert support" {
    const allocator = std.testing.allocator;
    
    var builder = Builder.init(allocator, "users");
    defer builder.deinit();
    
    // 你的测试代码
    const sql = try builder.sqlOfInsert();
    defer allocator.free(sql);
    
    try std.testing.expectEqualStrings(
        "INSERT INTO users ...",
        sql
    );
}
```

### 4. 提交代码

```bash
# 运行测试
zig build test

# 提交
git add .
git commit -m "feat: add INSERT support

- Implement sqlOfInsert() method
- Add tests for INSERT queries
- Update documentation"

# 推送到你的 Fork
git push origin feature/insert-support
```

### 5. 创建 Pull Request

1. 访问 https://github.com/YOUR_USERNAME/zxb
2. 点击 "New Pull Request"
3. 选择 `base: main` ← `compare: feature/insert-support`
4. 填写 PR 描述：

```markdown
## 功能描述

添加 INSERT 语句支持

## 改动内容

- [x] 实现 `sqlOfInsert()` 方法
- [x] 添加测试用例
- [x] 更新文档

## 测试

\```bash
zig build test
\```

## 相关 Issue

Closes #1
```

---

## 📝 提交消息规范

使用 [Conventional Commits](https://www.conventionalcommits.org/)：

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type

- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `style`: 代码格式（不影响功能）
- `refactor`: 重构
- `test`: 测试
- `chore`: 构建/工具

### 示例

```
feat(builder): add INSERT support

Implement sqlOfInsert() method to generate INSERT statements.

- Add sqlOfInsert() to Builder struct
- Support single and batch inserts
- Add comprehensive tests

Closes #1
```

---

## 🎯 设计原则

### 1. 职责原子性 > 性能

```zig
// ✅ 清晰的职责
var result = try builder.build();
defer result.deinit(allocator);

// QueryResult 作为完整对象，可传递给其他组件
try cache.query(result, db);
```

### 2. 简洁 > 复杂

```zig
// ✅ 仅 4 字段表达所有查询
pub const Bb = struct {
    op: []const u8,
    key: []const u8,
    value: Value,
    subs: []Bb,
};
```

### 3. 显式 > 隐式

```zig
// ✅ 明确的内存管理
var builder = zxb.of(allocator, "users");
defer builder.deinit();  // 显式释放
```

### 4. AI 友好

- 清晰的 API
- 一致的命名
- 完整的文档
- 简单的概念

---

## 🤝 代码审查

我们会检查：

1. ✅ **功能正确性** - 是否符合需求
2. ✅ **测试覆盖** - 是否有充分测试
3. ✅ **代码风格** - 是否遵循规范
4. ✅ **文档完整** - 是否更新文档
5. ✅ **性能影响** - 是否引入性能问题
6. ✅ **内存安全** - 是否有内存泄漏

---

## 📢 社区

- **GitHub Issues** - 报告 Bug、提出功能请求
- **GitHub Discussions** - 技术讨论、最佳实践
- **Pull Requests** - 贡献代码

---

## 🙏 致谢

感谢所有贡献者！

每一个 PR、Issue、讨论都让 zxb 变得更好！

---

## 📜 许可证

贡献的代码将遵循 [Apache License 2.0](../LICENSE)。

---

**让我们一起构建简洁、优雅、AI 友好的 SQL Builder！** 🚀

zxb = **Z**ig e**X**tensible **B**uilder

