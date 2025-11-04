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

/// MySQLBuilder - Builder pattern for MySQL configuration
/// Provides fluent API for MySQL Custom configuration
pub const MySQLBuilder = struct {
    mysql_custom: MySQLCustom,

    const Self = @This();

    pub fn init() Self {
        return .{
            .mysql_custom = MySQLCustom.init(),
        };
    }

    pub fn useUpsert(self: *Self, use: bool) *Self {
        self.mysql_custom.use_upsert = use;
        return self;
    }

    pub fn useIgnore(self: *Self, use: bool) *Self {
        self.mysql_custom.use_ignore = use;
        return self;
    }

    pub fn build(self: *Self) MySQLCustom {
        return self.mysql_custom;
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

    // Usage (Method 1 - Direct field setting):
    //   var custom = MySQLCustom.init();
    //   custom.use_upsert = true;  // Manual configuration
    //
    // Usage (Method 2 - Builder pattern, recommended):
    //   var builder = MySQLBuilder.init();
    //   const custom = builder.useUpsert(true).build();

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

/// QdrantBuilder - Builder pattern for Qdrant configuration
/// Provides fluent API for Qdrant Custom configuration with default value handling
pub const QdrantBuilder = struct {
    qdrant_custom: QdrantCustom,

    const Self = @This();

    pub fn init() Self {
        return .{
            .qdrant_custom = QdrantCustom.init(),
        };
    }

    pub fn hnswEf(self: *Self, ef: i32) *Self {
        self.qdrant_custom.default_hnsw_ef = ef;
        return self;
    }

    pub fn scoreThreshold(self: *Self, threshold: f32) *Self {
        self.qdrant_custom.default_score_threshold = threshold;
        return self;
    }

    pub fn withVector(self: *Self, with_vec: bool) *Self {
        self.qdrant_custom.default_with_vector = with_vec;
        return self;
    }

    pub fn build(self: *Self) QdrantCustom {
        return self.qdrant_custom;
    }
};

/// Example: Qdrant Custom Implementation
/// Generates JSON for Qdrant vector database
pub const QdrantCustom = struct {
    default_hnsw_ef: i32 = 128,
    default_score_threshold: f32 = 0.0,
    default_with_vector: bool = false, // 对齐 xb v1.2.1: 默认不返回向量（节省带宽）

    const Self = @This();

    pub fn init() Self {
        return .{};
    }

    // Usage (Method 1 - Direct field setting):
    //   var custom = QdrantCustom.init();
    //   custom.default_hnsw_ef = 512;  // Manual configuration
    //   custom.default_score_threshold = 0.85;
    //
    // Usage (Method 2 - Builder pattern, recommended):
    //   var builder = QdrantBuilder.init();
    //   const custom = builder.hnswEf(512).scoreThreshold(0.85).build();

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

    var mysql = MySQLCustom.init();
    mysql.use_upsert = true;  // Manual configuration
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

    var qdrant = QdrantCustom.init();
    qdrant.default_hnsw_ef = 512;  // Manual configuration
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

test "QdrantBuilder - fluent API" {
    const testing = std.testing;
    const allocator = testing.allocator;

    // ✅ Builder pattern: fluent API with default value handling
    var qb = QdrantBuilder.init();
    const qdrant_custom = qb.hnswEf(512)
        .scoreThreshold(0.85)
        .withVector(false)
        .build();

    var custom_copy = qdrant_custom;
    const custom = custom_copy.custom();
    defer custom.deinit(allocator);

    var builder = Builder.init(allocator, "vectors");
    defer builder.deinit();

    var result = try custom.generate(allocator, &builder);
    defer result.deinit(allocator);

    switch (result) {
        .sql => unreachable,
        .json => |json| {
            try testing.expect(json.len > 0);
            try testing.expect(std.mem.indexOf(u8, json, "\"hnsw_ef\": 512") != null);
        },
    }
}

test "MySQLBuilder - fluent API" {
    const testing = std.testing;

    // ✅ Builder pattern for MySQL
    var mb = MySQLBuilder.init();
    const mysql_custom = mb.useUpsert(true).build();

    try testing.expect(mysql_custom.use_upsert == true);
    try testing.expect(mysql_custom.use_ignore == false);
}

test "Builder - config reuse" {
    const testing = std.testing;

    // ✅ Config can be reused
    var qb = QdrantBuilder.init();
    const high_precision = qb.hnswEf(512).scoreThreshold(0.9).build();

    // Use config multiple times
    try testing.expect(high_precision.default_hnsw_ef == 512);
    try testing.expect(high_precision.default_score_threshold == 0.9);
}

