# swift-structured-queries-postgres

[![CI](https://github.com/coenttb/swift-structured-queries-postgres/workflows/CI/badge.svg)](https://github.com/coenttb/swift-structured-queries-postgres/actions/workflows/ci.yml)
![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Type-safe PostgreSQL query builder for Swift. Build complex SQL queries with compile-time validation and zero runtime overhead.

**PostgreSQL fork** of [Point-Free's swift-structured-queries](https://github.com/pointfreeco/swift-structured-queries) with comprehensive PostgreSQL feature support.

## Key Features

- Type-safe query building with compile-time validation
- PostgreSQL-native features: JSONB, triggers, window functions, CTEs, full-text search, UUID generation
- Built for swift-records: High-level PostgreSQL database operations
- Swift 6.1+ with strict concurrency
- 880 tests with SQL snapshot testing

## Quick Start

```swift
import StructuredQueriesPostgres

@Table
struct User {
    let id: Int
    var name: String
    var email: String
    var isActive: Bool = true
}

// Build query (this package)
let statement = User
    .where { $0.isActive && $0.email.hasSuffix("@example.com") }
    .order(by: \.name)
    .limit(10)

// Execute with swift-records
let users = try await statement.fetchAll(db)
```

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/coenttb/swift-structured-queries-postgres", from: "0.23.0")
]
```

### Optional Features

The following traits are enabled by default:
- **StructuredQueriesPostgresCasePaths**: Enum table support via swift-case-paths
- **StructuredQueriesPostgresTagged**: Type-safe IDs with swift-tagged

The **StructuredQueriesPostgresSQLValidation** trait (SQL validation using PostgresNIO) is available but disabled by default due to its heavy dependencies.

Add the package to your target dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "StructuredQueriesPostgres", package: "swift-structured-queries-postgres")
    ]
)
```

## Usage Examples

### Basic CRUD Operations

**SELECT with WHERE, ORDER BY, LIMIT:**

```swift
User
    .where { $0.isActive }
    .order(by: \.name)
    .limit(10)
// SQL: SELECT "users"."id", "users"."name", "users"."email", "users"."isActive"
//      FROM "users"
//      WHERE "users"."isActive"
//      ORDER BY "users"."name"
//      LIMIT 10
```

**INSERT with Draft types** (PostgreSQL NULL PRIMARY KEY handling):

```swift
// Single insert - PK column excluded
User.insert {
    User.Draft(name: "Alice", email: "alice@example.com")
}
// SQL: INSERT INTO "users" ("id", "name", "email", "isActive") VALUES (DEFAULT, 'Alice', 'alice@example.com', true)

// Mixed records - uses DEFAULT for NULL PKs
User.insert {
    User(id: 1, name: "Alice", email: "alice@example.com")
    User.Draft(name: "Bob", email: "bob@example.com")
}
// SQL: INSERT INTO "users" ("id", "name", "email", "isActive") VALUES (1, 'Alice', 'alice@example.com', true), (DEFAULT, 'Bob', 'bob@example.com', true)
```

**UPDATE with RETURNING:**

```swift
User
    .where { $0.id == 1 }
    .update { $0.isActive = false }
    .returning { ($0.id, $0.name) }
// SQL: UPDATE "users" SET "isActive" = false WHERE "users"."id" = 1 RETURNING "users"."id", "users"."name"
```

**DELETE with RETURNING:**

```swift
User
    .where { $0.isActive == false }
    .delete()
    .returning(\.email)
// SQL: DELETE FROM "users" WHERE "users"."isActive" = false RETURNING "users"."email"
```

### PostgreSQL JSONB

**Containment operator (@>):**

```swift
@Table
struct User {
    let id: Int
    var name: String
    var settings: Data
}

// Find users with dark theme
User.where { $0.settings.contains(["theme": "dark"]) }
// SQL: WHERE "users"."settings" @> '{"theme":"dark"}'::jsonb
```

**JSON path operator (->>):**

```swift
User.where { $0.settings.fieldAsText("theme") == "dark" }
// SQL: WHERE ("users"."settings" ->> 'theme') = 'dark'
```

**Key existence operator (?):**

```swift
User.where { $0.settings.hasKey("notifications") }
// SQL: WHERE "users"."settings" ? 'notifications'
```

### Window Functions

**ROW_NUMBER(), RANK(), DENSE_RANK():**

```swift
@Table
struct Employee {
    let id: Int
    var name: String
    var department: String
    var salary: Double
}

Employee.all
    .select { employee in
        (
            employee.name,
            employee.salary,
            rank().over {
                $0.partition(by: employee.department)
                    .order(by: employee.salary.desc())
            }
        )
    }
// SQL: SELECT "employees"."name", "employees"."salary", RANK() OVER (PARTITION BY "employees"."department" ORDER BY "employees"."salary" DESC)
//      FROM "employees"
```

**Named windows (WINDOW clause):**

```swift
Employee.all
    .window("dept_salary") {
        $0.partition(by: $1.department)
            .order(by: $1.salary.desc())
    }
    .select {
        (
            $0.name,
            rank().over("dept_salary"),
            denseRank().over("dept_salary"),
            rowNumber().over("dept_salary")
        )
    }
// SQL: SELECT "employees"."name", RANK() OVER dept_salary, DENSE_RANK() OVER dept_salary, ROW_NUMBER() OVER dept_salary
//      FROM "employees"
//      WINDOW dept_salary AS (PARTITION BY "employees"."department" ORDER BY "employees"."salary" DESC)
```

### Triggers

**Auto-update timestamp on changes:**

```swift
@Table
struct Product {
    let id: Int
    var name: String
    var price: Double
    var stock: Int
    var updatedAt: Date?
}

// Elegant DSL - auto-generates trigger name and function
Product.createTrigger(
    timing: .before,
    event: .update,
    function: .updateTimestamp(column: \.updatedAt)
)
// SQL: CREATE TRIGGER "products_before_update_update_updatedAt"
//      BEFORE UPDATE ON "products"
//      FOR EACH ROW EXECUTE FUNCTION "update_updatedAt_products"()
```

**Set creation timestamp:**

```swift
Product.createTrigger(
    timing: .before,
    event: .insert,
    function: .createdAt(column: \.createdAt)
)
// Automatically generates descriptive names: "products_before_insert_set_createdAt"
```

**Conditional trigger with UPDATE OF and WHEN:**

```swift
Product.createTrigger(
    name: "low_stock_alert",
    timing: .after,
    event: .update(
        of: { $0.stock },
        when: { new in new.stock < 10 }
    ),
    function: .plpgsql(
        "notify_low_stock",
        """
        PERFORM pg_notify('low_stock', json_build_object('product_id', NEW.id, 'stock', NEW.stock)::text);
        RETURN NEW;
        """
    )
)
// SQL: CREATE TRIGGER "low_stock_alert"
//      AFTER UPDATE OF "stock" ON "products"
//      FOR EACH ROW WHEN (NEW."stock" < 10)
//      EXECUTE FUNCTION "notify_low_stock"()
```

**Audit logging with type-safe DSL:**

```swift
@Table
struct ProductAudit: AuditTable {
    let id: Int
    var tableName: String
    var operation: String
    var oldData: String?
    var newData: String?
    var changedAt: Date
    var changedBy: String
}

// Elegant audit function - tracks all changes automatically
Product.createTrigger(
    timing: .after,
    event: .insert, .update(), .delete(),
    function: .audit(to: ProductAudit.self)
)
// Captures OLD and NEW data, operation type, and timestamp
```

**Soft delete implementation:**

```swift
Product.createTrigger(
    timing: .before,
    event: .delete,
    function: .softDelete(
        deletedAtColumn: \.deletedAt,
        identifiedBy: \.id
    )
)
// Intercepts DELETE and converts to UPDATE with timestamp
```

### UUID Functions

**Server-side UUID generation:**

```swift
@Table
struct Event {
    let id: UUID
    var title: String
    var timestamp: Date
}

// Random UUID (v4) - traditional approach
Event.insert {
    Event.Columns(id: UUID.random, title: #sql("'Login'"))
}
// SQL: INSERT INTO "events" ("id", "title") VALUES (gen_random_uuid(), 'Login')

// Time-ordered UUID (v7) - better for indexes
Event.insert {
    Event.Columns(id: UUID.timeOrdered, title: #sql("'Purchase'"))
}
// SQL: INSERT INTO "events" ("id", "title") VALUES (uuidv7(), 'Purchase')
```

**Time-shifted UUIDs for backdating:**

```swift
// Backdate events by shifting timestamp
Event.insert {
    ($0.id, $0.title)
} values: {
    (UUID.timeOrdered(shift: "-1 day"), "Historical Event")
    (UUID.timeOrdered(shift: "-2 days"), "Earlier Event")
}
// SQL: INSERT INTO "events" ("id", "title")
//      VALUES (uuidv7('-1 day'::interval), 'Historical Event'),
//             (uuidv7('-2 days'::interval), 'Earlier Event')
```

**Extract version and timestamp:**

```swift
// Filter by UUID version
Event.where { $0.id.extractVersion() == 7 }
// SQL: WHERE uuid_extract_version("events"."id") = 7

// Extract embedded timestamp from UUIDv7
Event.select { $0.id.extractTimestamp() }
// SQL: SELECT uuid_extract_timestamp("events"."id") FROM "events"

// Order by UUID creation time
Event.order(by: { $0.id.extractTimestamp() })
// SQL: ORDER BY uuid_extract_timestamp("events"."id")
```

**Why UUIDv7 over UUIDv4?**
- Better B-tree index performance (sequential inserts)
- Natural chronological ordering
- Embedded timestamp - no separate `createdAt` column needed
- Reduces index fragmentation

### Full-Text Search

**Basic search on text columns with `.match()`:**

```swift
@Table
struct Article {
    let id: Int
    var title: String
    var content: String
}

// Simple search
Article.where { $0.content.match("postgresql") }

// AND operator
Article.where { $0.content.match("postgresql & query") }

// OR operator
Article.where { $0.content.match("postgresql | mysql") }
```

**Search with ranking (requires tsvector column):**

```swift
@Table
struct Article: FullTextSearchable {
    let id: Int
    var title: String
    var searchVector: String  // Pre-computed tsvector column
}

// Search with ranking
Article
    .where { $0.match("swift") }
    .select { ($0.title, $0.rank(by: "swift")) }
    .order { $0.rank(by: "swift").desc() }
    .limit(10)
```

## NULL PRIMARY KEY Handling

**Critical Difference from SQLite:**

PostgreSQL **forbids NULL** in PRIMARY KEY columns, while SQLite allows it. This affects INSERT operations with auto-generated IDs.

**Solution: Use Draft types**

The `@Table` macro generates a `Draft` nested type that excludes the primary key:

```swift
@Table
struct User {
    let id: Int  // Primary key
    var name: String
}

// ✅ Draft excludes PK column
User.insert { User.Draft(name: "Alice") }
// SQL: INSERT INTO "users" ("name") VALUES ('Alice')

// ✅ Mixed records use DEFAULT
User.insert {
    User(id: 1, name: "Alice")
    User.Draft(name: "Bob")
}
// SQL: INSERT INTO "users" ("id", "name") VALUES (1, 'Alice'), (DEFAULT, 'Bob')

// ❌ This would fail in PostgreSQL
User.insert { User(id: nil, name: "Alice") }
// Error: null value in column "id" violates not-null constraint
```

## PostgreSQL Feature Coverage

**Window Functions:**
- ROW_NUMBER, RANK, DENSE_RANK, NTILE
- FIRST_VALUE, LAST_VALUE, NTH_VALUE
- LAG, LEAD
- PERCENT_RANK, CUME_DIST
- Named windows (WINDOW clause)

**Triggers:**
- BEFORE / AFTER / INSTEAD OF timing
- INSERT / UPDATE / DELETE / TRUNCATE events
- FOR EACH ROW / FOR EACH STATEMENT levels
- WHEN conditions with NEW/OLD pseudo-records
- UPDATE OF specific columns
- PL/pgSQL function generation

**JSONB:**
- 23 operators (@>, <@, ?, ?|, ?&, ->, ->>, #>, #>>, etc.)
- 6 core functions (jsonb_agg, jsonb_object_agg, etc.)
- GIN indexing with jsonb_path_ops

**Full-Text Search (Chapter 12):**
- to_tsvector, to_tsquery, plainto_tsquery, phraseto_tsquery
- @@ match operator
- ts_rank, ts_rank_cd ranking
- ts_headline highlighting
- Weighted multi-column search

**Aggregate Functions:**
- Standard: COUNT, SUM, AVG, MIN, MAX
- PostgreSQL-specific: STRING_AGG, ARRAY_AGG, JSONB_AGG
- Statistical: STDDEV, VARIANCE, CORR, PERCENTILE_CONT

**Array Operations:**
- Array construction and operators
- Array functions (array_length, array_agg, unnest)
- Containment operators (@>, <@, &&)

**String Functions:**
- CONCAT, SUBSTRING, POSITION, UPPER, LOWER
- LIKE, ILIKE pattern matching
- String aggregation

**Date/Time Functions:**
- EXTRACT, DATE_TRUNC
- CURRENT_TIMESTAMP, NOW()
- Interval arithmetic

**UUID Functions (Chapter 9.14):**
- gen_random_uuid(), uuidv4() - Random UUIDs
- uuidv7() - Time-ordered UUIDs for better index performance
- uuidv7(interval) - Time-shifted UUIDs for backdating/scheduling
- uuid_extract_version() - Extract version number (1-7)
- uuid_extract_timestamp() - Extract creation timestamp from v1/v7

**Advanced Features:**
- Common Table Expressions (CTEs)
- Subqueries and EXISTS
- CASE expressions
- Type casting (::type syntax)
- COALESCE, NULLIF
- DISTINCT ON (PostgreSQL-specific)

## Documentation

- [**ARCHITECTURE.md**](ARCHITECTURE.md) - Design decisions, PostgreSQL features, module architecture
- [**TESTING.md**](TESTING.md) - Test patterns, snapshot testing, SQL validation
- [**HISTORY.md**](HISTORY.md) - Evolution timeline, decisions, learnings

## Requirements

- **Swift**: 6.1 or later
- **Platforms**: macOS 13+, iOS 13+, Linux
- **PostgreSQL**: Designed for PostgreSQL 12+

### CI Status

Tested on:
- Swift 6.1, 6.2
- macOS (latest)
- Linux (Ubuntu)

## Migration from SQLite

Key differences from Point-Free's swift-structured-queries (SQLite):

| Aspect | SQLite | PostgreSQL |
|--------|--------|------------|
| **NULL in PK** | Allowed | **Forbidden** (use Draft types) |
| **Conflict syntax** | `INSERT OR REPLACE` | `ON CONFLICT DO UPDATE` |
| **JSON type** | `JSON` | `JSONB` (binary, indexed) |
| **String aggregation** | `group_concat()` | `string_agg()` |
| **Case sensitivity** | `LIKE` (case-insensitive) | `ILIKE` (case-insensitive) |
| **Array support** | Limited | Native array types |
| **Full-text search** | FTS5 extension | Built-in (Chapter 12) |

**See [ARCHITECTURE.md](ARCHITECTURE.md#postgresql-vs-sqlite-differences) for complete migration guide.**

## Integration with swift-records

This package provides **query building only**. For complete database functionality, use it with [**swift-records**](https://github.com/coenttb/swift-records):

### What swift-records Provides

- Connection pooling with automatic lifecycle management
- Transaction support with isolation levels and savepoints
- Migration management with version tracking
- Test utilities with schema isolation for parallel testing

### Usage

```swift
// 1. Build queries (this package)
let statement = User
    .where { $0.isActive }
    .order(by: \.name)
    .limit(10)

// 2. Execute with swift-records
let users = try await statement.fetchAll(db)
let user = try await statement.fetchOne(db)
try await statement.execute(db)
```

## Learn More

This library is a PostgreSQL adaptation of [swift-structured-queries](https://github.com/pointfreeco/swift-structured-queries) by [Point-Free](https://www.pointfree.co). The original library was designed and explored in depth over many episodes of their video series on advanced programming topics in Swift, hosted by [Brandon Williams](https://twitter.com/mbrandonw) and [Stephen Celis](https://twitter.com/stephencelis).

To learn about the core concepts behind structured query building in Swift, check out Point-Free's [SQL Building](https://www.pointfree.co/collections/sqlite/sql-building) collection.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Related Projects

- [**swift-records**](https://github.com/coenttb/swift-records) - High-level database operations layer (connection pooling, transactions, migrations)
- [**swift-structured-queries**](https://github.com/pointfreeco/swift-structured-queries) - Upstream SQLite-focused query builder by Point-Free

## Support

- [Report issues](https://github.com/coenttb/swift-structured-queries-postgres/issues)
- [Discussions](https://github.com/coenttb/swift-structured-queries-postgres/discussions)
- Contact: dev@coenttb.com
