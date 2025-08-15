# Swift Structured Queries PostgreSQL

![Swift 6.0+](https://img.shields.io/badge/Swift-6.0+-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS-blue.svg)
![Status](https://img.shields.io/badge/Status-Experimental-yellow.svg)

A PostgreSQL adapter for [Point-Free's StructuredQueries](https://github.com/pointfreeco/swift-structured-queries) library, enabling type-safe PostgreSQL database access in Swift.

> **Note**: This package integrates with Point-Free's StructuredQueries library which is currently in beta. This PostgreSQL adapter serves as both a functional implementation and a showcase of how to integrate PostgreSQL with the StructuredQueries system.

## 📋 Current Status

### ✅ Working Features

- **Core Query Operations**
  - SELECT queries with WHERE, ORDER BY, LIMIT, OFFSET
  - INSERT with multiple values
  - UPDATE with conditions
  - DELETE operations
  - Transaction support with automatic rollback
  
- **PostgreSQL-Specific Features**
  - Custom aggregate functions: `string_agg`, `array_agg`, `json_agg`, `jsonb_agg`
  - Statistical functions: `stddev`, `stddev_pop`, `stddev_samp`, `variance`
  - JSON/JSONB column support with automatic decoding
  - Native PostgreSQL array type support
  - Parameter binding conversion (SQLite `?` → PostgreSQL `$1, $2, ...`)
  
- **Type System Integration**
  - Full `QueryDecodable` support for custom types
  - Cursor support for memory-efficient large result sets
  - Boolean handling via INTEGER columns with CHECK constraints

### ⚠️ Known Issues

- **Compiler Crash**: Swift 6.1 compiler crashes when building or testing via Terminal using `swift-build` or `swift-testing`.
- **JOIN with @Selection**: Runtime crashes occur when using JOIN queries with `@Selection` types
- **Dependency Initialization**: Currently seeking a cleaner way to instantiate `liveValue` for `PostgresQueryDatabase` in the Dependencies system. The current implementation in `Tests/StructuredQueriesPostgresTests/Support/PostgresSchema.swift` works but uses semaphores to bridge async/sync which is not ideal. Suggestions welcome!

### 🎯 Design Decisions

Following Point-Free's design philosophy from their [Boolean Handling blog post](https://www.pointfree.co/blog/posts/133-sqlite-is-great-for-structured-concurrency-and-point-free):

- **Boolean Columns**: Use `INTEGER NOT NULL DEFAULT 0 CHECK (column IN (0, 1))` instead of native PostgreSQL `BOOLEAN`
- **Automatic Transformation**: WHERE clauses automatically add `!= 0` for boolean columns
- **Consistent API**: Maintains API compatibility with the SQLite implementation

## 📦 Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/coenttb/swift-structured-queries-postgres", branch: "main")
]
```

**Requirements:**
- Swift 6.0+
- PostgreSQL 12+ (for MATERIALIZED CTE support)
- macOS 10.15+ / iOS 13+ / tvOS 13+ / watchOS 6+

## 🧪 Testing

### Database Setup

Tests require a PostgreSQL database. Set environment variables:

```bash
export DATABASE_HOST=localhost
export DATABASE_PORT=5432
export DATABASE_NAME=testdb
export DATABASE_USERNAME=testuser
export DATABASE_PASSWORD=testpass
```

or create a .env file in either JSON or standard .env format.

## 🔧 Development

This package is experimental and tracks the beta development of StructuredQueries. Key areas:

- **Boolean Handling**: Intentionally uses INTEGER columns for booleans to maintain consistency with StructuredQueries' design
- **Parameter Binding**: Automatically converts SQLite-style `?` placeholders to PostgreSQL `$1, $2, ...`
- **Type Safety**: Leverages Swift's type system for compile-time query validation

### Known Compiler Issue

Swift 6.1 has a known crash in StructuredQueries:
```
Assertion failed: ((path.size() == 1 && path[0].getKind() == ConstraintLocator::SubscriptMember) || 
(path.size() == 2 && path[1].getKind() == ConstraintLocator::KeyPathDynamicMember)), 
function addKeyPathApplicationRootConstraint, file CSSimplify.cpp, line 15827.
```

This primarily affects test compilation when all tests are built together.

## 🙏 Acknowledgments

- [Point-Free](https://www.pointfree.co) for creating StructuredQueries
- The [Vapor](https://vapor.codes) team for PostgresNIO

## 📄 License

[MIT License](LICENSE)

## 🤝 Contributing

As this package integrates with a beta library, contributions should focus on:
- PostgreSQL-specific features and optimizations
- Test coverage for PostgreSQL functionality
- Documentation improvements
- Bug fixes that don't break StructuredQueries compatibility
- **Help Wanted**: Cleaner pattern for async database initialization in Dependencies (see `PostgresSchema.swift`)
