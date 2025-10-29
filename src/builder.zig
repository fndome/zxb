const std = @import("std");
const Bb = @import("bb.zig").Bb;
const Value = @import("value.zig").Value;
const Allocator = std.mem.Allocator;

/// SQL Query Builder
pub const Builder = struct {
    allocator: Allocator,
    table: []const u8,
    conditions: std.ArrayList(Bb),
    sorts: std.ArrayList(Sort),
    limit_value: ?i32,
    offset_value: ?i32,
    allocated_strings: std.ArrayList([]const u8), // Track allocated LIKE patterns

    const Sort = struct {
        field: []const u8,
        direction: []const u8, // "ASC" or "DESC"
    };

    /// Initialize a new Builder
    pub fn init(allocator: Allocator, table: []const u8) Builder {
        return Builder{
            .allocator = allocator,
            .table = table,
            .conditions = std.ArrayList(Bb).init(allocator),
            .sorts = std.ArrayList(Sort).init(allocator),
            .limit_value = null,
            .offset_value = null,
            .allocated_strings = std.ArrayList([]const u8).init(allocator),
        };
    }

    /// Free all allocated memory
    pub fn deinit(self: *Builder) void {
        for (self.conditions.items) |*cond| {
            cond.deinit(self.allocator);
        }
        self.conditions.deinit();
        self.sorts.deinit();

        // Free allocated LIKE pattern strings
        for (self.allocated_strings.items) |str| {
            self.allocator.free(str);
        }
        self.allocated_strings.deinit();
    }

    /// Add an equality condition (auto-filter nil/0/empty)
    pub fn eq(self: *Builder, key: []const u8, value: anytype) !*Builder {
        const val = Value.from(@TypeOf(value), value);
        if (val.shouldFilter()) {
            return self; // Auto-filter
        }
        try self.conditions.append(Bb.condition("=", key, val));
        return self;
    }

    /// Add a not-equal condition
    pub fn ne(self: *Builder, key: []const u8, value: anytype) !*Builder {
        const val = Value.from(@TypeOf(value), value);
        if (val.shouldFilter()) {
            return self;
        }
        try self.conditions.append(Bb.condition("!=", key, val));
        return self;
    }

    /// Add a greater-than condition
    pub fn gt(self: *Builder, key: []const u8, value: anytype) !*Builder {
        const val = Value.from(@TypeOf(value), value);
        if (val.shouldFilter()) {
            return self;
        }
        try self.conditions.append(Bb.condition(">", key, val));
        return self;
    }

    /// Add a greater-than-or-equal condition
    pub fn gte(self: *Builder, key: []const u8, value: anytype) !*Builder {
        const val = Value.from(@TypeOf(value), value);
        if (val.shouldFilter()) {
            return self;
        }
        try self.conditions.append(Bb.condition(">=", key, val));
        return self;
    }

    /// Add a less-than condition
    pub fn lt(self: *Builder, key: []const u8, value: anytype) !*Builder {
        const val = Value.from(@TypeOf(value), value);
        if (val.shouldFilter()) {
            return self;
        }
        try self.conditions.append(Bb.condition("<", key, val));
        return self;
    }

    /// Add a less-than-or-equal condition
    pub fn lte(self: *Builder, key: []const u8, value: anytype) !*Builder {
        const val = Value.from(@TypeOf(value), value);
        if (val.shouldFilter()) {
            return self;
        }
        try self.conditions.append(Bb.condition("<=", key, val));
        return self;
    }

    /// Add a LIKE condition (contains: %value%)
    /// Note: The allocated pattern string will be freed when Builder is deinitialized
    pub fn like(self: *Builder, key: []const u8, value: []const u8) !*Builder {
        if (value.len == 0) {
            return self; // Auto-filter
        }
        const pattern = try std.fmt.allocPrint(self.allocator, "%{s}%", .{value});
        try self.allocated_strings.append(pattern); // Track for cleanup
        try self.conditions.append(Bb.condition("LIKE", key, Value{ .string = pattern }));
        return self;
    }

    /// Add a LIKE condition for prefix matching (starts with: value%)
    /// Note: The allocated pattern string will be freed when Builder is deinitialized
    pub fn likeLeft(self: *Builder, key: []const u8, value: []const u8) !*Builder {
        if (value.len == 0) {
            return self; // Auto-filter
        }
        const pattern = try std.fmt.allocPrint(self.allocator, "{s}%", .{value});
        try self.allocated_strings.append(pattern); // Track for cleanup
        try self.conditions.append(Bb.condition("LIKE", key, Value{ .string = pattern }));
        return self;
    }

    /// Add sort (ASC/DESC)
    pub fn sort(self: *Builder, field: []const u8, direction: []const u8) !*Builder {
        try self.sorts.append(Sort{
            .field = field,
            .direction = direction,
        });
        return self;
    }

    /// Set LIMIT
    pub fn limit(self: *Builder, value: i32) *Builder {
        if (value > 0) {
            self.limit_value = value;
        }
        return self;
    }

    /// Set OFFSET
    pub fn offset(self: *Builder, value: i32) *Builder {
        if (value > 0) {
            self.offset_value = value;
        }
        return self;
    }

    /// Query result containing SQL and arguments
    pub const QueryResult = struct {
        sql: []const u8,
        args: std.ArrayList(Value),

        pub fn deinit(self: *QueryResult, allocator: Allocator) void {
            allocator.free(self.sql);
            self.args.deinit();
        }
    };

    /// Build SELECT query (returns both SQL and args)
    pub fn build(self: *Builder) !QueryResult {
        const sql = try self.sqlOfSelect();
        const query_args = try self.args();
        return QueryResult{
            .sql = sql,
            .args = query_args,
        };
    }

    /// Build SELECT SQL (only returns SQL string)
    /// Note: Use build() if you need both SQL and args
    pub fn sqlOfSelect(self: *Builder) ![]const u8 {
        var sql = std.ArrayList(u8).init(self.allocator);
        defer sql.deinit();

        // SELECT * FROM table
        try sql.appendSlice("SELECT * FROM ");
        try sql.appendSlice(self.table);

        // WHERE conditions
        if (self.conditions.items.len > 0) {
            try sql.appendSlice(" WHERE ");
            for (self.conditions.items, 0..) |cond, i| {
                if (i > 0) {
                    try sql.appendSlice(" AND ");
                }
                try sql.appendSlice(cond.key);
                try sql.appendSlice(" ");
                try sql.appendSlice(cond.op);
                try sql.appendSlice(" ");

                switch (cond.value) {
                    .string => try sql.appendSlice("?"),
                    .int => try sql.appendSlice("?"),
                    .float => try sql.appendSlice("?"),
                    .bool => try sql.appendSlice("?"),
                    .null_value => try sql.appendSlice("NULL"),
                }
            }
        }

        // ORDER BY
        if (self.sorts.items.len > 0) {
            try sql.appendSlice(" ORDER BY ");
            for (self.sorts.items, 0..) |s, i| {
                if (i > 0) {
                    try sql.appendSlice(", ");
                }
                try sql.appendSlice(s.field);
                try sql.appendSlice(" ");
                try sql.appendSlice(s.direction);
            }
        }

        // LIMIT
        if (self.limit_value) |lim| {
            try sql.writer().print(" LIMIT {d}", .{lim});
        }

        // OFFSET
        if (self.offset_value) |off| {
            try sql.writer().print(" OFFSET {d}", .{off});
        }

        return sql.toOwnedSlice();
    }

    /// Get query arguments (for prepared statements)
    pub fn args(self: *Builder) !std.ArrayList(Value) {
        var result = std.ArrayList(Value).init(self.allocator);
        errdefer result.deinit();

        for (self.conditions.items) |cond| {
            if (!cond.value.shouldFilter()) {
                try result.append(cond.value);
            }
        }

        return result;
    }
};

// Direction constants
pub const ASC = "ASC";
pub const DESC = "DESC";
