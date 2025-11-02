const std = @import("std");
const Builder = @import("builder.zig").Builder;
const Allocator = std.mem.Allocator;

/// Custom Interface - Database-specific query generation
/// 
/// Inspired by xb (Go) v1.1.0 Custom interface design.
/// One interface to handle all database-specific features.
///
/// Usage:
///   const custom = MySQLCustom.init();
///   const result = try custom.generate(allocator, &builder);
///
pub const Custom = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        generate: *const fn (ptr: *anyopaque, allocator: Allocator, builder: *Builder) anyerror!Result,
        deinit: *const fn (ptr: *anyopaque, allocator: Allocator) void,
    };

    /// Result of Custom.generate()
    /// Can be either SQL or JSON depending on database type
    pub const Result = union(enum) {
        sql: SQLResult,
        json: []const u8, // For vector databases like Qdrant

        pub fn deinit(self: *Result, allocator: Allocator) void {
            switch (self.*) {
                .sql => |*sql_result| sql_result.deinit(allocator),
                .json => |json| allocator.free(json),
            }
        }
    };

    /// SQL Result for SQL databases
    pub const SQLResult = struct {
        sql: []const u8,
        args: std.ArrayList(Value),
        count_sql: ?[]const u8 = null, // For pagination

        const Value = @import("value.zig").Value;

        pub fn deinit(self: *SQLResult, allocator: Allocator) void {
            allocator.free(self.sql);
            self.args.deinit();
            if (self.count_sql) |count| {
                allocator.free(count);
            }
        }
    };

    /// Generate database-specific query
    pub fn generate(self: Custom, allocator: Allocator, builder: *Builder) !Result {
        return self.vtable.generate(self.ptr, allocator, builder);
    }

    /// Free custom implementation resources
    pub fn deinit(self: Custom, allocator: Allocator) void {
        self.vtable.deinit(self.ptr, allocator);
    }
};

/// Example: MySQL Custom Implementation
/// Supports MySQL-specific features like INSERT ... ON DUPLICATE KEY UPDATE
pub const MySQLCustom = struct {
    use_upsert: bool = false,
    use_ignore: bool = false,

    const Self = @This();

    pub fn init() Self {
        return .{};
    }

    pub fn withUpsert() Self {
        return .{ .use_upsert = true };
    }

    pub fn withIgnore() Self {
        return .{ .use_ignore = true };
    }

    pub fn custom(self: *Self) Custom {
        return .{
            .ptr = self,
            .vtable = &.{
                .generate = generateImpl,
                .deinit = deinitImpl,
            },
        };
    }

    fn generateImpl(ptr: *anyopaque, allocator: Allocator, builder: *Builder) !Custom.Result {
        _ = allocator;
        _ = ptr;
        
        // For now, just delegate to default SQL generation
        // In a full implementation, this would handle UPSERT/IGNORE
        const sql = try builder.sqlOfSelect();
        const query_args = try builder.args();
        
        return Custom.Result{
            .sql = .{
                .sql = sql,
                .args = query_args,
                .count_sql = null,
            },
        };
    }

    fn deinitImpl(_: *anyopaque, _: Allocator) void {
        // Nothing to clean up for MySQLCustom (stateless)
    }
};

/// Example: Qdrant Custom Implementation
/// Generates JSON for Qdrant vector database
pub const QdrantCustom = struct {
    default_hnsw_ef: i32 = 128,
    default_score_threshold: f32 = 0.0,
    default_with_vector: bool = true,

    const Self = @This();

    pub fn init() Self {
        return .{};
    }

    pub fn highPrecision() Self {
        return .{
            .default_hnsw_ef = 512,
            .default_score_threshold = 0.85,
            .default_with_vector = true,
        };
    }

    pub fn highSpeed() Self {
        return .{
            .default_hnsw_ef = 32,
            .default_score_threshold = 0.5,
            .default_with_vector = false,
        };
    }

    pub fn custom(self: *Self) Custom {
        return .{
            .ptr = self,
            .vtable = &.{
                .generate = generateImpl,
                .deinit = deinitImpl,
            },
        };
    }

    fn generateImpl(ptr: *anyopaque, allocator: Allocator, builder: *Builder) !Custom.Result {
        const self: *Self = @ptrCast(@alignCast(ptr));
        _ = builder;
        
        // For now, placeholder JSON
        // In full implementation, this would generate Qdrant search JSON
        const json = try std.fmt.allocPrint(allocator, 
            \\{{"vector": [], "limit": {d}, "params": {{"hnsw_ef": {d}}}}}
        , .{ 10, self.default_hnsw_ef });
        
        return Custom.Result{
            .json = json,
        };
    }

    fn deinitImpl(_: *anyopaque, _: Allocator) void {
        // Nothing to clean up for QdrantCustom (stateless)
    }
};

test "Custom interface - MySQL" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var mysql = MySQLCustom.withUpsert();
    const custom = mysql.custom();
    defer custom.deinit(allocator);

    var builder = Builder.init(allocator, "users");
    defer builder.deinit();

    _ = try builder.eq("id", @as(i32, 1));

    var result = try custom.generate(allocator, &builder);
    defer result.deinit(allocator);

    switch (result) {
        .sql => |sql_result| {
            try testing.expect(sql_result.sql.len > 0);
        },
        .json => unreachable,
    }
}

test "Custom interface - Qdrant" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var qdrant = QdrantCustom.highPrecision();
    const custom = qdrant.custom();
    defer custom.deinit(allocator);

    var builder = Builder.init(allocator, "vectors");
    defer builder.deinit();

    var result = try custom.generate(allocator, &builder);
    defer result.deinit(allocator);

    switch (result) {
        .sql => unreachable,
        .json => |json| {
            try testing.expect(json.len > 0);
            try testing.expect(std.mem.indexOf(u8, json, "hnsw_ef") != null);
        },
    }
}

