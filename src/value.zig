const std = @import("std");

/// Value types that can be used in queries
pub const Value = union(enum) {
    string: []const u8,
    int: i64,
    float: f64,
    bool: bool,
    null_value: void,

    /// Convert anytype to Value at compile time
    pub fn from(comptime T: type, value: T) Value {
        const info = @typeInfo(T);
        return switch (info) {
            .pointer => |ptr| {
                // Check if it's a string ([]u8, []const u8, or *const [N:0]u8)
                const child_info = @typeInfo(ptr.child);
                if (ptr.child == u8) {
                    return .{ .string = value };
                } else if (child_info == .array) {
                    const array = child_info.array;
                    if (array.child == u8) {
                        return .{ .string = value };
                    }
                }
                @compileError("Unsupported pointer type: " ++ @typeName(T));
            },
            .int => .{ .int = @intCast(value) },
            .float => .{ .float = @floatCast(value) },
            .bool => .{ .bool = value },
            .null => .{ .null_value = {} },
            .comptime_int => .{ .int = value },      // 支持整数字面量：1, 2, 3...
            .comptime_float => .{ .float = value },  // 支持浮点数字面量：1.0, 99.99...
            else => @compileError("Unsupported type: " ++ @typeName(T)),
        };
    }

    /// Check if value should be filtered (nil or zero)
    pub fn shouldFilter(self: Value) bool {
        return switch (self) {
            .null_value => true,
            .string => |s| s.len == 0,
            .int => |i| i == 0,
            .float => |f| f == 0.0,
            .bool => false, // bool 不过滤
        };
    }

    /// Format value for SQL
    pub fn format(self: Value, writer: anytype) !void {
        switch (self) {
            .string => |s| try writer.print("'{s}'", .{s}),
            .int => |i| try writer.print("{d}", .{i}),
            .float => |f| try writer.print("{d}", .{f}),
            .bool => |b| try writer.print("{}", .{b}),
            .null_value => try writer.writeAll("NULL"),
        }
    }
};
