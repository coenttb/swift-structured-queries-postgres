# swift-structured-queries-postgres

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fcoenttb%2Fswift-structured-queries-postgres%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/coenttb/swift-structured-queries-postgres)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fcoenttb%2Fswift-structured-queries-postgres%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/coenttb/swift-structured-queries-postgres)

Type-safe PostgreSQL query builder for Swift. Generates SQL queries without executing them.

**PostgreSQL fork** of [Point-Free's swift-structured-queries](https://github.com/pointfreeco/swift-structured-queries) with comprehensive PostgreSQL feature support.

## Overview

**swift-structured-queries-postgres**: Query generation only (returns `Statement<T>` types)
**[swift-records](https://github.com/coenttb/swift-records)**: Database operations (connection pooling, execution, migrations)

### Key Features

- 🔒 Type-safe query building with compile-time validation
- 🎯 85% PostgreSQL Chapter 9 coverage (Functions & Operators)
- 📦 Modular architecture (Core + Postgres separation)
- 🧪 280+ tests with SQL snapshot testing
- 🔌 Seamless swift-records integration

### PostgreSQL Highlights

- ✅ Complete JSONB (23 operators, GIN indexing)
- ✅ Full-text search (Chapter 12)
- ✅ Window functions (11 functions)
- ✅ PostgreSQL aggregates (STRING_AGG, ARRAY_AGG, JSONB_AGG)
- ✅ All standard SQL (SELECT, INSERT, UPDATE, DELETE, CTEs)

## Installation

```swift
dependencies: [
  .package(url: "https://github.com/coenttb/swift-structured-queries-postgres", from: "0.0.1")
]
```

## Quick Start

```swift
import StructuredQueriesPostgres

@Table
struct User {
  var id: Int
  var name: String
  var email: String
}

// Build query
let statement = User
  .where { $0.email.hasSuffix("@example.com") }
  .order(by: \.name)
  .limit(10)

// Execute with swift-records
let users = try await statement.fetchAll(db)
```

## NULL PRIMARY KEY Handling

**PostgreSQL forbids NULL in PRIMARY KEYs** (SQLite allows it). Use Draft types:

```swift
// ✅ Draft excludes PK column
User.insert { User.Draft(name: "Alice") }
// SQL: INSERT INTO "users" ("name") VALUES ('Alice')

// ✅ Mixed records use DEFAULT
User.insert {
  User(id: 1, name: "Alice")
  User.Draft(name: "Bob")
}
// SQL: INSERT INTO "users" ("id", "name") VALUES (1, 'Alice'), (DEFAULT, 'Bob')
```

See [ARCHITECTURE.md](ARCHITECTURE.md#null-primary-key-handling) for details.

## Documentation

### Quick Reference
📘 [**CLAUDE.md**](CLAUDE.md) - LLM-optimized quick reference (build commands, troubleshooting)

### Detailed Guides
- 📖 [**ARCHITECTURE.md**](ARCHITECTURE.md) - Design decisions, PostgreSQL features, module architecture
- 🧪 [**TESTING.md**](TESTING.md) - Test patterns, snapshot testing, SQL expectations
- 📜 [**HISTORY.md**](HISTORY.md) - Evolution timeline, decisions, learnings

## Build & Test

```bash
swift build              # Build package
swift test               # Run tests
open Package.swift       # Use Xcode
```

## Examples

### Column Groups

```swift
@Selection
struct Timestamps {
  var createdAt: Date
  var updatedAt: Date
}

@Table
struct Document {
  let id: Int
  var title: String
  var timestamps: Timestamps
}

// Full group operations
Document.update { $0.timestamps.updatedAt = Date() }
Document.where { $0.timestamps.eq(Timestamps(...)) }
```

### JSONB Operations

```swift
// Containment
User.where { $0.settings.contains(["theme": "dark"]) }

// GIN indexing
User.createGINIndex(on: \.settings, operatorClass: .jsonb_path_ops)
```

### Full-Text Search

```swift
Post.where { $0.content.match("postgresql & (query | search)") }
  .select { tsHeadline($0.content, query) }
```

### Window Functions

```swift
Sale.select {
  ($0.amount, sum($0.amount).over {
    $0.order { $1.date }
  })
}
```

## License

Dual-licensed:
- **Apache 2.0**: swift-structured-queries components (inherited from Point-Free)
- **AGPL 3.0**: PostgreSQL-specific additions

## Related

- [swift-records](https://github.com/coenttb/swift-records) - Database operations
- [Point-Free's swift-structured-queries](https://github.com/pointfreeco/swift-structured-queries) - Upstream package

## Support

- 🐛 [Report issues](https://github.com/coenttb/swift-structured-queries-postgres/issues)
- 📧 Contact: dev@coenttb.com
