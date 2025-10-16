# Aggregate Functions Coverage Matrix

This file tracks which aggregate functions have complete "lifted" support across all query contexts.

## Coverage Legend

- ✅ **Complete** - Primitive + all lifted variants implemented
- 🟡 **Primitive Only** - Only column-level usage (`$0.column.aggregate()`)
- ❌ **Missing** - Not yet implemented

## File Organization

Each aggregate has its own folder with primitives. Example structure:
```
Count/
  CountPrimitive.swift   # $0.id.count()
  Table+Count.swift      # User.count()
  Where+Count.swift      # User.where{...}.count()
  Select+Count.swift     # User.select{...}.count()
```

## Standard SQL Aggregates

| Aggregate    | Primitive | Table.X | Where.X | Select.X | Folder | Status | Notes |
|--------------|-----------|---------|---------|----------|--------|--------|-------|
| `count`      | ✅        | ✅      | ✅      | ✅ (5)   | `Count/` | ✅ | Complete coverage |
| `sum`        | ✅        | ❌      | ❌      | ❌       | _(in Count/)_ | 🟡 | Primitive only |
| `avg`        | ✅        | ❌      | ❌      | ❌       | `Avg/` | 🟡 | Column-level sufficient? |
| `max`        | ✅        | ❌      | ❌      | ❌       | `Max/` | 🟡 | Column-level sufficient? |
| `min`        | ✅        | ❌      | ❌      | ❌       | `Min/` | 🟡 | Column-level sufficient? |
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
| `SimpleAggregateFunction` | `_Infrastructure/` | Helper for single/two-arg aggregates |

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
