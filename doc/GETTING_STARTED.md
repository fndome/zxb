# Getting Started with zxb

## Installation

### 1. Install Zig

**Windows**:
```powershell
# Using Scoop
scoop install zig

# Or download from official site

# Extract and add to PATH
```

**macOS**:
```bash
brew install zig
```

**Linux**:
```bash
# Download from https://ziglang.org/download/
wget https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz
tar -xf zig-linux-x86_64-0.13.0.tar.xz
sudo mv zig-linux-x86_64-0.13.0 /opt/zig
export PATH=$PATH:/opt/zig
```

### 2. Verify Installation

```bash
zig version
# Should output: 0.13.0 or higher
```

### 3. Build zxb

```bash
cd D:\MyDev\server\zxb

# Run tests
zig build test

# Run example
zig build example
```

## Quick Test

Create a simple test file:

```bash
# Create test.zig
echo 'const std = @import("std");
const zxb = @import("src/main.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    
    var builder = zxb.of(allocator, "users");
    defer builder.deinit();
    
    _ = try builder.eq("id", @as(i64, 123));
    
    const sql = try builder.sqlOfSelect();
    defer allocator.free(sql);
    
    std.debug.print("SQL: {s}\n", .{sql});
}' > test.zig

# Run it
zig run test.zig
```

## Expected Output

After installation, you should see:

```bash
$ zig build test
All tests passed!

$ zig build example

=== zxb - Zig SQL Builder ===

Example 1: Basic Query
SQL: SELECT * FROM users WHERE status = ? AND role = ? ORDER BY created_at DESC LIMIT 10

Example 2: Auto-Filtering (nil/0/empty)
SQL: SELECT * FROM products WHERE category = ? AND price >= ?
Note: stock=0 and empty description are auto-filtered

Example 3: Complex Query
SQL: SELECT * FROM orders WHERE user_id = ? AND total >= ? AND total <= ? AND status != ? ORDER BY created_at DESC, id DESC LIMIT 20 OFFSET 0

Example 4: Query Arguments
SQL: SELECT * FROM users WHERE name = ? AND age >= ?
Args count: 2
  Arg[0]: string = 'Alice'
  Arg[1]: int = 18

=== All examples completed! ===
```

## Next Steps

1. Read [README.md](../README.md) for full documentation
2. Check [examples/basic.zig](../examples/basic.zig) for more examples
3. Start using zxb in your project!

---

**Happy coding with zxb!** 🚀

