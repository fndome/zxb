# 安装 Zig

## Windows 安装步骤

### 方式 1: Scoop（推荐）

```powershell
# 1. 安装 Scoop（如果还没有）
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression

# 2. 安装 Zig
scoop install zig

# 3. 验证
zig version
```

### 方式 2: 手动安装

1. **下载**: https://ziglang.org/download/
   - Windows x86_64: `zig-windows-x86_64-0.13.0.zip`

2. **解压**到 `C:\zig` 或其他目录

3. **添加到 PATH**:
   ```powershell
   # 临时添加（当前会话）
   $env:Path += ";C:\zig"
   
   # 永久添加（系统环境变量）
   [Environment]::SetEnvironmentVariable(
       "Path",
       [Environment]::GetEnvironmentVariable("Path", "User") + ";C:\zig",
       "User"
   )
   ```

4. **验证**:
   ```powershell
   zig version
   # 输出: 0.13.0
   ```

## 使用 zxb

### 1. 运行测试

```bash
cd D:\MyDev\server\zxb
zig build test
```

### 2. 运行示例

```bash
zig build example
```

### 3. 构建库

```bash
zig build
```

生成的文件在 `zig-out/lib/libzxb.a`

## 快速验证

创建测试文件 `test.zig`:

```zig
const std = @import("std");

pub fn main() !void {
    std.debug.print("Zig is installed!\n", .{});
    std.debug.print("Version: 0.13.0\n", .{});
}
```

运行:
```bash
zig run test.zig
```

## 常见问题

### Q: zig 命令找不到？
**A**: 确认已添加到 PATH，重启终端

### Q: 需要什么版本？
**A**: zxb 需要 Zig 0.13.0 或更高版本

### Q: 如何更新 Zig？
**A**: 
```bash
# Scoop 用户
scoop update zig

# 手动安装用户：重新下载并替换
```

---

**安装完成后，就可以使用 zxb 了！** 🚀

