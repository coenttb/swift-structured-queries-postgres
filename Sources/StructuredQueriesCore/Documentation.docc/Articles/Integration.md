# Integrating with database libraries

Learn how to integrate this library with PostgreSQL database libraries so that you can execute
type-safe queries.

## Overview

This library focuses solely on building type-safe SQL queries for PostgreSQL. It does not include
database drivers or connection management. To execute queries, you'll need to integrate with a
PostgreSQL database library.

The primary integration is through the [swift-records] library, which provides a high-level
database abstraction layer built on top of [postgres-nio]. The swift-records library handles:

- Connection pooling and lifecycle management
- Transaction support with isolation levels
- Migration management
- Query execution with type-safe decoding

If you're building your own PostgreSQL integration, you can use this library's query building
capabilities with any PostgreSQL driver. See the integration example below for guidance.

[swift-records]: https://github.com/coenttb/swift-records
[postgres-nio]: https://github.com/vapor/postgres-nio

### Integration with swift-records

The [swift-records] library provides the recommended integration between StructuredQueriesPostgres
and PostgreSQL databases. It offers:

**Database Operations:**
```swift
import StructuredQueriesPostgres
import Records

// Define your schema
@Table
struct Reminder {
  let id: Int
  var title: String
  var isCompleted: Bool
}

// Execute queries
@Dependency(\.database) var db

// Select
let reminders = try await Reminder
  .where { !$0.isCompleted }
  .order(by: \.title)
  .execute(db)

// Insert
try await Reminder.insert {
  Reminder.Draft(title: "Buy groceries", isCompleted: false)
}
.execute(db)

// Update
try await Reminder
  .where { $0.id == 1 }
  .set(\.isCompleted, to: true)
  .execute(db)
```

**Features:**
- Automatic connection pooling
- Transaction support with `db.withTransaction { ... }`
- Migration tracking and execution
- Test isolation via PostgreSQL schemas

For complete documentation, see the [swift-records repository][swift-records].

### Building a Custom Integration

If you need to integrate StructuredQueriesPostgres with a different PostgreSQL library or build
your own integration layer, you'll need to:

1. **Define a QueryDecoder** - Implement the ``QueryDecoder`` protocol to decode PostgreSQL column
   values into Swift types
2. **Execute statements** - Create methods to execute ``SelectStatement``s and ``Statement``s
3. **Handle binding** - Convert Swift values to PostgreSQL wire format

#### Example: postgres-nio Integration

Here's a minimal example of integrating with postgres-nio directly:

```swift
import PostgresNIO
import StructuredQueriesPostgres

extension PostgresConnection {
  // Execute a SELECT statement
  func execute<T: Decodable>(
    _ statement: some SelectStatement<T>
  ) async throws -> [T] {
    let (sql, bindings) = statement.queryFragment.encoded()

    let rows = try await query(
      PostgresQuery(unsafeSQL: sql),
      bindings.map { PostgresData($0) }
    )

    return try rows.map { row in
      try T(from: PostgresQueryDecoder(row: row))
    }
  }

  // Execute an INSERT/UPDATE/DELETE statement
  func execute(_ statement: some Statement) async throws {
    let (sql, bindings) = statement.queryFragment.encoded()

    try await query(
      PostgresQuery(unsafeSQL: sql),
      bindings.map { PostgresData($0) }
    )
  }
}

// Implement QueryDecoder for PostgresRow
struct PostgresQueryDecoder: QueryDecoder {
  let row: PostgresRow

  func decode<T: Decodable>(_ type: T.Type, from column: String) throws -> T {
    try row.decode(T.self, column: column)
  }
}
```

For a complete implementation with proper error handling, connection pooling, and transaction
support, see the [swift-records source code][swift-records-source].

[swift-records-source]: https://github.com/coenttb/swift-records/tree/main/Sources/Records

### PostgreSQL-Specific Considerations

When integrating with PostgreSQL, be aware of these PostgreSQL-specific features:

**Native Types:**
- PostgreSQL has native `UUID`, `JSONB`, `ARRAY`, and `TIMESTAMP` types
- Use `@Column` annotations to specify column representations when needed

**Transactions:**
- PostgreSQL supports full ACID transactions with various isolation levels
- Use savepoints for nested transaction-like behavior

**Generated Columns:**
- PostgreSQL supports computed columns (see <doc:DefiningYourSchema#Generated-columns>)
- Mark these with `@Column(generated: true)` to exclude from INSERT/UPDATE

**Full-Text Search:**
- PostgreSQL has built-in full-text search with tsvector/tsquery types (see ``TextSearch`` functions)
- Uses dedicated columns with GIN indexes rather than virtual tables

## Discussions

If you're building an integration with another PostgreSQL library, or encounter challenges,
please [start a discussion][sq-discussions] in the upstream swift-structured-queries repository.

[sq-discussions]: https://github.com/pointfreeco/swift-structured-queries/discussions/new/choose
