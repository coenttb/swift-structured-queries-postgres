# Aggregate Functions Coverage Matrix

This file tracks which aggregate functions have complete "lifted" support across all query contexts.

## Coverage Legend

- ✅ **Complete** - Primitive + all lifted variants implemented
- 🟡 **Primitive Only** - Only column-level usage (`$0.column.aggregate()`)
- ❌ **Missing** - Not yet implemented

## Standard SQL Aggregates

| Aggregate    | Primitive | Table.X | Where.X | Select.X | Status | Notes |
|--------------|-----------|---------|---------|----------|--------|-------|
| `count`      | ✅        | ✅      | ✅      | ✅ (5)   | ✅     | Complete coverage |
| `sum`        | ✅        | ❌      | ❌      | ❌       | 🟡     | TODO: Add lifted variants |
| `avg`        | ✅        | ❌      | ❌      | ❌       | 🟡     | TODO: Add lifted variants |
| `max`        | ✅        | ❌      | ❌      | ❌       | 🟡     | Column-level sufficient? |
| `min`        | ✅        | ❌      | ❌      | ❌       | 🟡     | Column-level sufficient? |
| `total`      | ✅        | ❌      | ❌      | ❌       | 🟡     | Low priority (SQLite-specific) |
| `groupConcat`| ✅        | ❌      | ❌      | ❌       | 🟡     | Low priority (complex args) |

## PostgreSQL-Specific Aggregates

| Aggregate     | Primitive | Table.X | Where.X | Select.X | Status | Notes |
|---------------|-----------|---------|---------|----------|--------|-------|
| `arrayAgg`    | ✅        | ❌      | ❌      | ❌       | 🟡     | PostgreSQL arrays |
| `stringAgg`   | ✅        | ❌      | ❌      | ❌       | 🟡     | PostgreSQL string concat |
| `jsonbAgg`    | ✅        | ❌      | ❌      | ❌       | 🟡     | PostgreSQL JSONB |

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
1. **High**: count (✅ done), sum, avg
2. **Medium**: max, min
3. **Low**: total, groupConcat, arrayAgg, stringAgg, jsonbAgg

## File Locations

### Primitives (PostgreSQL SQL generation)
```
Sources/StructuredQueriesPostgres/Functions/Aggregate/
  Count/CountPrimitive.swift
  Sum/SumPrimitive.swift      (to be created)
  Avg/AvgPrimitive.swift      (to be created)
```

### Lifted Variants (Universal query building)
```
Sources/StructuredQueriesCore/Functions/Aggregate/
  Count/
    Table+Count.swift
    Where+Count.swift
    Select+Count.swift
  Sum/                         (to be created)
    Table+Sum.swift
    Where+Sum.swift
    Select+Sum.swift
```

## Adding a New Lifted Aggregate

1. Create folder: `Aggregate/{Name}/`
2. Extract primitive from `StandardAggregates.swift` → `{Name}Primitive.swift`
3. Copy `Count/Table+Count.swift` → `{Name}/Table+{Name}.swift`
4. Find-replace: `count` → `{name}`, update types
5. Repeat for Where and Select
6. Update this coverage matrix
7. Build & test
