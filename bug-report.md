# Bug Report: SIGABRT Crash in `selectStar()` with Variadic Generic Joins

## Description
The `selectStar()` method causes a SIGABRT crash when used with joined tables due to an unsafe bit cast that's incompatible with Swift 6's variadic generics.

## Environment
- **swift-structured-queries version**: 0.7.0
- **Swift version**: 6.0
- **Platform**: macOS (Darwin 24.6.0)
- **Xcode version**: Latest with Swift 6 support

## Steps to Reproduce

1. Create a join query between two tables:
```swift
let query = TableA
    .join(TableB.all) { $0.foreignKey.eq($1.id) }
```

2. Execute the query using a database adapter that calls `selectStar()`:
```swift
public func execute<S: SelectStatement, each J: Table>(
    _ query: S
) async throws -> [(S.From.QueryOutput, repeat (each J).QueryOutput)]
where S.QueryValue == (), S.Joins == (repeat each J) {
    try await execute(query.selectStar()) // CRASHES HERE
}
```

## Expected Behavior
The join query should execute successfully and return the joined results.

## Actual Behavior
The application crashes with `Thread 3: signal SIGABRT` at the line calling `selectStar()`.

## Root Cause Analysis

The issue is in `Sources/StructuredQueriesCore/Statements/SelectStatement.swift:38-42`:

```swift
public func selectStar<each J: Table>() -> Select<
  (From, repeat each J), From, (repeat each J)
> where Joins == (repeat each J) {
  unsafeBitCast(asSelect(), to: Select<(From, repeat each J), From, (repeat each J)>.self)
}
```

The `unsafeBitCast` is attempting to reinterpret the memory layout of a `Select<QueryValue, From, Joins>` as a `Select<(From, repeat each J), From, (repeat each J)>`. This is unsafe because:

1. The memory layouts may differ between the source and destination types
2. Variadic generics in Swift 6 have specific memory representations that aren't compatible with unsafe bit casting
3. The cast violates Swift's type safety guarantees

## Crash Details
- **Error Type**: SIGABRT (signal 6)
- **Message**: Likely "freed pointer was not the last allocation" or similar memory corruption error
- **Location**: The crash occurs during the execution of the unsafeBitCast

## Suggested Fix

Replace the unsafe bit cast with a type-safe implementation:

```swift
public func selectStar<each J: Table>() -> Select<
  (From, repeat each J), From, (repeat each J)
> where Joins == (repeat each J) {
  var newSelect = Select<(From, repeat each J), From, (repeat each J)>()
  newSelect.clauses = self._selectClauses
  return newSelect
}
```

Or provide a specialized implementation that constructs the proper Select instance without relying on unsafe operations.

## Workaround

Database adapters can work around this by avoiding `selectStar()` and manually constructing the SQL query:

```swift
public func execute<S: SelectStatement, each J: Table>(
    _ query: S
) async throws -> [(S.From.QueryOutput, repeat (each J).QueryOutput)]
where S.QueryValue == (), S.Joins == (repeat each J) {
    // Manually construct SELECT * query instead of using selectStar()
    let queryFragment = query.query // Get the base query
    // Process and execute the query directly
    // Decode results appropriately
}
```

## Impact
This bug prevents the use of JOIN operations in any database adapter that relies on the `selectStar()` method, making it a critical issue for SQL database integrations.

## Additional Context
The issue appears to be related to Swift 6's stricter handling of variadic generics and memory safety. The `unsafeBitCast` pattern that may have worked in earlier Swift versions is no longer safe with the current type system implementation.

## Minimal Reproducible Example

Here's a complete example that reproduces the crash:

```swift
import StructuredQueries
import PostgresNIO

@Table
struct TableA {
    @Column var id: Int
    @Column var name: String
    @Column var tableBId: Int
}

@Table 
struct TableB {
    @Column var id: Int
    @Column var title: String
}

// This will crash when executed:
let joinQuery = TableA
    .join(TableB.all) { $0.tableBId.eq($1.id) }

// When a database adapter tries to execute with:
try await db.execute(joinQuery) // Calls selectStar() internally and crashes
```