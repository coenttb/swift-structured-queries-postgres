# swift-structured-queries-postgres

[![CI](https://github.com/coenttb/swift-structured-queries-postgres/actions/workflows/ci.yml/badge.svg)](https://github.com/coenttb/swift-structured-queries-postgres/actions/workflows/ci.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fcoenttb%2Fswift-structured-queries-postgres%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/coenttb/swift-structured-queries-postgres)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fcoenttb%2Fswift-structured-queries-postgres%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/coenttb/swift-structured-queries-postgres)

Type-safe PostgreSQL query builder for Swift. Build complex SQL queries with compile-time validation and zero runtime overhead.

**PostgreSQL fork** of [Point-Free's swift-structured-queries](https://github.com/pointfreeco/swift-structured-queries) with comprehensive PostgreSQL feature support.

## Key Features

- 🔒 **Type-safe query building** with compile-time validation
- 🎯 **85% PostgreSQL Chapter 9 coverage** (Functions & Operators)
- 🚀 **PostgreSQL-native features**: JSONB, triggers, window functions, CTEs, full-text search
- ⚡ **Production-ready**: Swift 6.0+ with strict concurrency
- 🧪 **280+ tests** with SQL snapshot testing
- 🔌 **Seamless integration** with [swift-records](https://github.com/coenttb/swift-records)

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

### Critical: Build Requirement

**Always use release mode** for building and testing:

```bash
swift build -c release
swift test -c release
```

Debug builds have Swift 6.x compiler linker issues. This is a known Swift compiler bug, not a package issue. Xcode debug builds work fine.

### Optional Features

Enable optional traits in your `Package.swift`:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "StructuredQueriesPostgres", package: "swift-structured-queries-postgres")
    ],
    swiftSettings: [
        .enableExperimentalFeature("Trait"),
        .enableTrait("StructuredQueriesPostgresCasePaths"),  // Enum table support
        .enableTrait("StructuredQueriesPostgresSQLValidation")  // SQL validation (heavy dependency)
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

    @Column(as: Data.self)
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

Employee
    .select {
        let department = $0.department
        let salary = $0.salary
        return (
            $0.name,
            salary,
            rank().over {
                $0.partition(by: department)
                    .order(by: salary.desc())
            }
        )
    }
// SQL: SELECT "employees"."name", "employees"."salary", RANK() OVER (PARTITION BY "employees"."department" ORDER BY "employees"."salary" DESC)
//      FROM "employees"
```

**Named windows (WINDOW clause):**

```swift
Employee
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

**BEFORE UPDATE trigger with automatic timestamps:**

```swift
@Table
struct Product {
    let id: Int
    var name: String
    var price: Double
    var stock: Int
    var updatedAt: Date?
}

Product.createTrigger(
    name: "update_timestamp",
    timing: .before,
    event: .update,
    function: .plpgsql(
        "set_updated_at",
        """
        NEW."updatedAt" = CURRENT_TIMESTAMP;
        RETURN NEW;
        """
    )
)
// SQL: CREATE TRIGGER "update_timestamp" BEFORE UPDATE ON "products"
//      FOR EACH ROW EXECUTE FUNCTION "set_updated_at"()
```

**Conditional trigger with WHEN clause:**

```swift
Product.createTrigger(
    name: "low_stock_alert",
    timing: .after,
    event: .update(of: { $0.stock }, when: { new in new.stock < 10 }),
    function: .plpgsql(
        "notify_low_stock",
        """
        PERFORM pg_notify('low_stock', json_build_object('product_id', NEW.id, 'stock', NEW.stock)::text);
        RETURN NEW;
        """
    )
)
// SQL: CREATE TRIGGER "low_stock_alert" AFTER UPDATE OF "stock" ON "products"
//      FOR EACH ROW WHEN (NEW."stock" < 10) EXECUTE FUNCTION "notify_low_stock"()
```

**Access NEW and OLD records:**

```swift
Product.createTrigger(
    timing: .after,
    event: .update,
    function: .plpgsql(
        "log_price_change",
        """
        IF NEW.price != OLD.price THEN
            INSERT INTO price_history (product_id, old_price, new_price, changed_at)
            VALUES (NEW.id, OLD.price, NEW.price, CURRENT_TIMESTAMP);
        END IF;
        RETURN NEW;
        """
    )
)
```

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

    static var searchVectorColumn: String { "searchVector" }
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

### Comprehensive Support (85% of Chapter 9)

**Window Functions:**
- ✅ ROW_NUMBER, RANK, DENSE_RANK, NTILE
- ✅ FIRST_VALUE, LAST_VALUE, NTH_VALUE
- ✅ LAG, LEAD
- ✅ PERCENT_RANK, CUME_DIST
- ✅ Named windows (WINDOW clause)

**Triggers:**
- ✅ BEFORE / AFTER / INSTEAD OF timing
- ✅ INSERT / UPDATE / DELETE / TRUNCATE events
- ✅ FOR EACH ROW / FOR EACH STATEMENT levels
- ✅ WHEN conditions with NEW/OLD pseudo-records
- ✅ UPDATE OF specific columns
- ✅ PL/pgSQL function generation

**JSONB:**
- ✅ 23 operators (@>, <@, ?, ?|, ?&, ->, ->>, #>, #>>, etc.)
- ✅ 6 core functions (jsonb_agg, jsonb_object_agg, etc.)
- ✅ GIN indexing with jsonb_path_ops

**Full-Text Search (Chapter 12):**
- ✅ to_tsvector, to_tsquery, plainto_tsquery, phraseto_tsquery
- ✅ @@ match operator
- ✅ ts_rank, ts_rank_cd ranking
- ✅ ts_headline highlighting
- ✅ Weighted multi-column search

**Aggregate Functions:**
- ✅ Standard: COUNT, SUM, AVG, MIN, MAX
- ✅ PostgreSQL-specific: STRING_AGG, ARRAY_AGG, JSONB_AGG
- ✅ Statistical: STDDEV, VARIANCE, CORR, PERCENTILE_CONT

**Array Operations:**
- ✅ Array construction and operators
- ✅ Array functions (array_length, array_agg, unnest)
- ✅ Containment operators (@>, <@, &&)

**String Functions:**
- ✅ CONCAT, SUBSTRING, POSITION, UPPER, LOWER
- ✅ LIKE, ILIKE pattern matching
- ✅ String aggregation

**Date/Time Functions:**
- ✅ EXTRACT, DATE_TRUNC
- ✅ CURRENT_TIMESTAMP, NOW()
- ✅ Interval arithmetic

**Advanced Features:**
- ✅ Common Table Expressions (CTEs)
- ✅ Subqueries and EXISTS
- ✅ CASE expressions
- ✅ Type casting (::type syntax)
- ✅ COALESCE, NULLIF
- ✅ DISTINCT ON (PostgreSQL-specific)

## Documentation

### Quick Reference
📘 [**CLAUDE.md**](CLAUDE.md) - LLM-optimized quick reference (build commands, troubleshooting, key differences)

### Detailed Guides
- 📖 [**ARCHITECTURE.md**](ARCHITECTURE.md) - Design decisions, PostgreSQL features, module architecture
- 🧪 [**TESTING.md**](TESTING.md) - Test patterns, snapshot testing, SQL validation
- 📜 [**HISTORY.md**](HISTORY.md) - Evolution timeline, decisions, learnings

## Requirements

- **Swift**: 6.0 or later
- **Platforms**: macOS 13+, iOS 13+, Linux
- **Build**: Use `swift build -c release` (debug mode has linker issues)
- **PostgreSQL**: Designed for PostgreSQL 12+

### CI Status

Tested on:
- ✅ Swift 6.0, 6.1, 6.2
- ✅ macOS (latest)
- ✅ Linux (Ubuntu)

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

This package provides **query building only**. For database operations (connection pooling, execution, migrations), use [swift-records](https://github.com/coenttb/swift-records):

```swift
// Query building (this package)
let statement = User.where { $0.isActive }

// Execution (swift-records)
let users = try await statement.fetchAll(db)
let user = try await statement.fetchOne(db)
try await statement.execute(db)
```

## Learn More

This library is a PostgreSQL adaptation of [swift-structured-queries](https://github.com/pointfreeco/swift-structured-queries) by [Point-Free](https://www.pointfree.co). The original library was designed and explored in depth over many episodes of their video series on advanced programming topics in Swift, hosted by [Brandon Williams](https://twitter.com/mbrandonw) and [Stephen Celis](https://twitter.com/stephencelis).

To learn about the core concepts behind structured query building in Swift, check out Point-Free's [SQL Building](https://www.pointfree.co/collections/sqlite/sql-building) collection.

## License

Dual-licensed:

- **Apache License 2.0**: Core query building infrastructure (inherited from Point-Free's swift-structured-queries)
- **AGPL 3.0**: PostgreSQL-specific additions and features

See [LICENSE-APACHE](LICENSE-APACHE) and [LICENSE-AGPL](LICENSE-AGPL) for details.

## Related Projects

- [**swift-records**](https://github.com/coenttb/swift-records) - High-level database operations layer (connection pooling, transactions, migrations)
- [**swift-structured-queries**](https://github.com/pointfreeco/swift-structured-queries) - Upstream SQLite-focused query builder by Point-Free

## Support

- 🐛 [Report issues](https://github.com/coenttb/swift-structured-queries-postgres/issues)
- 💬 [Discussions](https://github.com/coenttb/swift-structured-queries-postgres/discussions)
- 📧 Contact: dev@coenttb.com
