# Aggregate Functions Coverage Matrix

This file tracks which aggregate functions have complete "lifted" support across all query contexts.

## Coverage Legend

- ✅ **Complete** - Primitive + all lifted variants implemented
- 🟡 **Primitive Only** - Only column-level usage (`$0.column.aggregate()`)
- ❌ **Missing** - Not yet implemented

## File Organization

Each aggregate has its own folder following Swift naming conventions. Example structure:
```
Count/
  QueryExpression+Count.swift   # $0.id.count() - extends QueryExpression
  Table+Count.swift             # User.count() - extends Table
  Where+Count.swift             # User.where{...}.count() - extends Where
  Select+Count.swift            # User.select{...}.count() - extends Select
```

File names indicate **what they extend**, making it clear where each method lives.

## Standard SQL Aggregates

| Aggregate    | Primitive | Table.X | Where.X | Select.X | Folder | Status | Notes |
|--------------|-----------|---------|---------|----------|--------|--------|-------|
| `count`      | ✅        | ✅      | ✅      | ✅ (5)   | `Count/` | ✅ | Complete coverage |
| `sum`        | ✅        | ✅      | ✅      | ✅ (5)   | `Sum/` | ✅ | Complete coverage |
| `avg`        | ✅        | ✅      | ✅      | ✅ (5)   | `Avg/` | ✅ | Complete coverage (returns Double?) |
| `max`        | ✅        | ✅      | ✅      | ✅ (5)   | `Max/` | ✅ | Complete coverage |
| `min`        | ✅        | ✅      | ✅      | ✅ (5)   | `Min/` | ✅ | Complete coverage |
| `total`      | ✅        | ❌      | ❌      | ❌       | `Total/` | 🟡 | Low priority (SQLite-specific) |
| `groupConcat`| ✅        | ❌      | ❌      | ❌       | `GroupConcat/` | 🟡 | Low priority (complex args) |

## PostgreSQL-Specific Aggregates

| Aggregate     | Primitive | Table.X | Where.X | Select.X | Folder | Status | Notes |
|---------------|-----------|---------|---------|----------|--------|--------|-------|
| `arrayAgg`    | ✅        | ❌      | ❌      | ❌       | `ArrayAgg/` | 🟡 | PostgreSQL arrays |
| `stringAgg`   | ✅        | ❌      | ❌      | ❌       | `StringAgg/` | 🟡 | PostgreSQL string concat |
| `jsonAgg`     | ✅        | ❌      | ❌      | ❌       | `JsonAgg/` | 🟡 | PostgreSQL JSON |
| `jsonbAgg`    | ✅        | ❌      | ❌      | ❌       | `JsonbAgg/` | 🟡 | PostgreSQL JSONB |
| Statistical   | ✅        | ❌      | ❌      | ❌       | `Statistical/` | 🟡 | stddev, variance, etc. |

## Infrastructure

| Component | Location | Purpose |
|-----------|----------|---------|
| `AggregateFunction` | `_Infrastructure/` | Main aggregate struct with FILTER support |

## Implementation Status

**Primitive**: Column-level usage in SELECT clause
```swift
User.select { $0.age.sum() }
// SELECT sum("users"."age") FROM "users"
```

**Lifted Variants**: Table/Where/Select static methods for whole-table aggregation
```swift
User.sum(filter: { $0.isActive })
// SELECT sum(*) FROM "users" WHERE "users"."is_active"
```

### Select.X Overload Count

Due to Swift's type system, each Select.aggregate method requires 5 overloads:
1. No joins, no columns
2. Parameter pack joins, no columns
3. Parameter pack joins, with columns
4. Single join, no columns
5. Single join, with columns

## Decision Criteria

**When to lift an aggregate:**
- ❓ Is it commonly used at the table level? (e.g., `Order.sum { $0.total }`)
  - YES → Lift it
  - NO → Column-level is sufficient

**Priority for lifting:**
1. **High**: count (✅ done)
2. **Medium**: sum, avg
3. **Low**: max, min, total, groupConcat, arrayAgg, stringAgg, jsonbAgg, statistical

## Adding a New Lifted Aggregate

1. Create folder: `Aggregate/{Name}/`
2. Copy `Count/Table+Count.swift` → `{Name}/Table+{Name}.swift`
3. Find-replace: `count` → `{name}`, update types
4. Repeat for Where and Select
5. Update this coverage matrix
6. Build & test

## PostgreSQL Chapter 9 Coverage (Functions Outside Aggregates)

### ✅ Implemented (Excellent Coverage)
- 9.2: Comparison Functions (ComparisonFunctions.swift)
- 9.3: Mathematical Functions (6 files)
- 9.4: String Functions (11 files under PostgreSQL.String namespace)
- 9.5: Binary String Functions
- 9.7: Pattern Matching (LIKE, SIMILAR TO, POSIX regex)
- 9.8: Data Type Formatting
- 9.9: Date/Time Functions (3 files: Extract, Truncate, Current)
- 9.13: Full Text Search (5 files)
- 9.16: JSON Functions (5 files)
- 9.18: Conditional Expressions (CASE, COALESCE, NULLIF)
- 9.19: Array Functions (4 files under PostgreSQL.Array namespace)
- 9.21: Aggregate Functions (this file)
- 9.22: Window Functions (4 files)
- 9.24: Subquery Expressions (ANY, ALL, EXISTS, IN)
- 9.26: Set Returning Functions

### ❌ Intentionally Skipped (With Rationale)

**9.6: Bit String Functions**
- **Reason**: PostgreSQL BIT/BIT VARYING types don't map cleanly to Swift
- **Alternative**: Use Int bitwise operators (which we have) or Data in Swift
- **Use Case**: Legacy binary manipulation - rare in modern type-safe systems

**9.10: PostgreSQL ENUM Functions** (enum_first, enum_last, enum_range)
- **Reason**: Incompatible with our superior Swift enum-as-table pattern
- **Alternative**: We have `@Table enum` with associated values (PostgreSQL ENUMs can't do this)
- **Use Case**: Our CasePaths integration provides better type safety

**9.11: Geometric Functions**
- **Reason**: Niche use case (GIS applications)
- **Strategy**: Wait for user request before implementing

**9.12: Network Address Functions**
- **Reason**: Specialized networking use case
- **Strategy**: Wait for user request before implementing

**9.14: XML Functions**
- **Reason**: XML is declining in favor of JSON (which we fully support)
- **Strategy**: User request only

**9.17: Sequence Manipulation Functions**
- **Reason**: Medium priority - useful for nextval/currval
- **Strategy**: Implement when users need manual sequence control

**9.20: Range/Multirange Functions**
- **Reason**: Specialized data type
- **Strategy**: Wait for user request

**9.23: System Information Functions**
- **Reason**: Administration/introspection, not query building
- **Strategy**: Out of scope for this package

### Coverage Summary
- **Core SQL**: ~95% of commonly-used functions implemented
- **Skipped**: Niche types, administration, and features superseded by better Swift patterns
- **Philosophy**: Maximize value per line of code, wait for real-world usage to guide additions
