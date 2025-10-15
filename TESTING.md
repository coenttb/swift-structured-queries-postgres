# Testing Guide

**Package**: swift-structured-queries-postgres
**Last Updated**: 2025-10-13
**Test Count**: 280+ tests in 35+ suites across 47 test files

This is a living testing guide. Update this file when test patterns evolve.

---

## Quick Reference

### Key Concepts

**Two Testing Approaches**:
1. **`await assertSQL(of:)`** - Validates SQL against PostgreSQL + snapshots (143 tests)
2. **`assertInlineSnapshot(of:, as: .sql)`** - Pure snapshots, no validation (36 tests)

**When to Use Each**:
```swift
// Use assertSQL (preferred for most tests)
@Test func selectUser() async {
  await assertSQL(of: User.where { $0.age > 18 }) {
    """
    SELECT * FROM "users" WHERE ("users"."age") > (18)
    """
  }
}

// Use assertInlineSnapshot (only when required)
@Test func emptyQuery() {
  assertInlineSnapshot(of: Reminder.none, as: .sql) {
    """

    """
  }
}
```

**Use `assertInlineSnapshot` only for**:
- Empty SQL (EXPLAIN can't validate "")
- DDL statements (CREATE/DROP VIEW)
- Invalid syntax (edge case testing)

### Running Tests

```bash
# Development (fast, no PostgreSQL required)
swift test -c release

# CI/CD (validates SQL, requires PostgreSQL)
swift test -c release --enable-trait StructuredQueriesPostgresSQLValidation
```

**Note**: Always use `-c release` (debug builds have linker errors)

---

## Test Infrastructure

### Overview

swift-structured-queries-postgres uses **SQL snapshot testing with optional PostgreSQL validation**. Tests can either:
1. Use pure snapshot testing (fast, no dependencies)
2. Use SQL validation (validates against live PostgreSQL)

**Test Duration**:
- Without validation: ~0.5 seconds for all tests (~2ms per test)
- With validation: ~2-3 seconds (includes PostgreSQL EXPLAIN calls)

### Testing Framework

**Swift Testing**: Modern Swift testing framework (NOT XCTest)

```swift
import Testing

@Test func selectBasic() {
  // Test implementation
}
```

### README Examples Test Suite

**Location**: `Tests/READMEExamplesTests/`

**Purpose**: Every code example in README.md has a corresponding validated test ensuring documentation accuracy.

**Why This Matters**:
- ✅ Documentation never goes stale - examples are validated with every test run
- ✅ SQL syntax is verified against PostgreSQL
- ✅ Users can copy-paste examples with confidence
- ✅ Breaking changes in API immediately show up as README test failures

**Test Files**:
```
Tests/READMEExamplesTests/
├── WindowFunctionsExamplesTests.swift     # Window function examples
├── JSONBExamplesTests.swift               # JSONB operation examples
├── FullTextSearchExamplesTests.swift      # Full-text search examples
└── [other example categories]
```

**Pattern**:
```swift
@Suite("README Examples - Window Functions")
struct WindowFunctionsExamplesTests {

    @Test("README Example: RANK() window function")
    func rankWindowFunction() async {
        await assertSQL(
            of: Employee.all
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
        ) {
            """
            SELECT "employees"."name", "employees"."salary", RANK() OVER (PARTITION BY "employees"."department" ORDER BY "employees"."salary" DESC)
            FROM "employees"
            """
        }
    }

    @Test("README Example: Named window definition")
    func namedWindow() async {
        await assertSQL(
            of: Employee.all
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
        ) {
            """
            SELECT "employees"."name", RANK() OVER dept_salary, DENSE_RANK() OVER dept_salary, ROW_NUMBER() OVER dept_salary
            FROM "employees"
            WINDOW dept_salary AS (PARTITION BY "employees"."department" ORDER BY "employees"."salary" DESC)
            """
        }
    }
}
```

**Benefits of This Approach**:

1. **Living Documentation**: README examples are executable tests, not stale comments
2. **SQL Validation**: All examples validated against PostgreSQL for correctness
3. **Refactoring Safety**: API changes that break examples fail tests immediately
4. **User Confidence**: Users know examples work because they're tested
5. **Maintenance Signal**: Test failures indicate README needs updates

**Workflow**:

When adding a new README example:
1. Write the example in README.md
2. Add corresponding test in `READMEExamplesTests/`
3. Use `await assertSQL` for SQL validation
4. Test name should reference README: `@Test("README Example: ...")`
5. Commit both README and test together

**Example Categories Covered**:
- ✅ Window functions (RANK, ROW_NUMBER, named windows)
- ✅ JSONB operations (@>, ->>, ?, field access)
- ✅ Full-text search (@@, ranking, highlighting)
- ✅ Array operations
- ✅ Triggers
- ✅ CTEs

**This is a competitive advantage** - most database libraries don't validate their documentation examples.

---

### Two Testing Approaches

#### 1. SQL Validation (Preferred for most tests)

**assertSQL**: Validates SQL syntax against PostgreSQL and snapshots the output

```swift
import StructuredQueriesPostgresTestSupport

@Test func selectWithWhere() async {
  await assertSQL(
    of: User.where { $0.age > 18 }
  ) {
    """
    SELECT "users"."id", "users"."name"
    FROM "users"
    WHERE ("users"."age") > (18)
    """
  }
}
```

**Benefits**:
- ✅ Validates SQL is syntactically correct PostgreSQL
- ✅ Catches typos and invalid SQL early
- ✅ Uses PostgreSQL's own parser (via EXPLAIN)
- ✅ Still snapshots the exact SQL output
- ✅ No table creation required (EXPLAIN doesn't execute)

**How it works**:
```sql
-- assertSQL runs this internally:
EXPLAIN (FORMAT TEXT) <your_sql>

-- Accepts these errors (missing tables/columns are fine):
-- 42P01: undefined_table
-- 42703: undefined_column

-- Fails on syntax errors:
-- 42601: syntax_error
```

**Requirements**:
- Requires PostgreSQL database connection
- Enable trait: `swift test -c release --enable-trait StructuredQueriesPostgresSQLValidation`
- Or set default in Package.swift
- Connection via `POSTGRES_URL` env var or defaults to `postgres://postgres@localhost:5432/test`

#### 2. Inline Snapshot Testing (For special cases)

**assertInlineSnapshot**: Pure snapshot testing with no database dependency

```swift
import InlineSnapshotTesting

@Test func emptyQuery() {
  assertInlineSnapshot(of: Reminder.none, as: .sql) {
    """

    """
  }
}
```

**When to use**:
- ❌ SQL that generates empty strings (EXPLAIN fails)
- ❌ DDL statements (CREATE/DROP VIEW, CREATE TABLE, etc.)
- ❌ SQL with intentionally invalid syntax (test edge cases)
- ❌ SQL using query builder placeholders like `[]`

**Benefits**:
- ✅ Fast (no database I/O)
- ✅ No dependencies
- ✅ Works for any SQL including invalid syntax

### Test Models

Standard test models used across test suite:

**Reminder Schema**:
```swift
@Table
struct Reminder {
  var id: Int
  var title: String
  var notes: String
  var isCompleted: Bool
  var isFlagged: Bool
  var priority: Priority?
  var dueDate: Date?
  var remindersListID: RemindersList.ID
  var assignedUserID: User.ID?
  var updatedAt: Date
}

@Table
struct RemindersList {
  var id: Int
  var title: String
}

@Table
struct User {
  var id: Int
  var name: String
}

@Table
struct Tag {
  var id: Int
  var name: String
}
```

**Why These Models**: Matches upstream swift-structured-queries for test compatibility

---

## Choosing the Right Testing Approach

### Decision Tree

```
Is the SQL empty or generates ""?
├─ YES → Use assertInlineSnapshot (EXPLAIN can't validate empty SQL)
└─ NO → Continue

Is it a DDL statement (CREATE VIEW, DROP VIEW, CREATE TABLE, etc.)?
├─ YES → Use assertInlineSnapshot (EXPLAIN only works for DML/SELECT)
└─ NO → Continue

Does it use intentionally invalid syntax (like [] placeholder)?
├─ YES → Use assertInlineSnapshot (testing edge cases)
└─ NO → Use await assertSQL ✅ (validates + snapshots)
```

### Examples by Category

#### Use `await assertSQL` (143 tests upgraded)

**SELECT queries**:
```swift
@Test func selectWithWhere() async {
  await assertSQL(of: User.where { $0.id == 1 }) {
    """
    SELECT "users"."id", "users"."name"
    FROM "users"
    WHERE ("users"."id") = (1)
    """
  }
}
```

**INSERT statements**:
```swift
@Test func insertDraft() async {
  await assertSQL(of: User.insert { User.Draft(name: "Alice") }) {
    """
    INSERT INTO "users" ("id", "name")
    VALUES (DEFAULT, 'Alice')
    """
  }
}
```

**UPDATE statements**:
```swift
@Test func updateWhere() async {
  await assertSQL(of: User.where { $0.id == 1 }.set(\.name, to: "Bob")) {
    """
    UPDATE "users"
    SET "name" = 'Bob'
    WHERE ("users"."id") = (1)
    """
  }
}
```

**DELETE statements**:
```swift
@Test func deleteWhere() async {
  await assertSQL(of: User.where { $0.id == 1 }.delete()) {
    """
    DELETE FROM "users"
    WHERE ("users"."id") = (1)
    """
  }
}
```

#### Use `assertInlineSnapshot` (36 tests remain)

**Empty SQL** (9 tests):
```swift
@Test func emptySelect() {
  assertInlineSnapshot(of: Reminder.none, as: .sql) {
    """

    """
  }
}

@Test func emptyInsert() {
  assertInlineSnapshot(of: Reminder.insert { [] }, as: .sql) {
    """

    """
  }
}
```

**DDL statements** (6 tests):
```swift
@Test func createView() {
  let view = CompletedReminder.createTemporaryView(
    as: Reminder.where(\.isCompleted)
  )
  assertInlineSnapshot(of: view, as: .sql) {
    """
    CREATE TEMPORARY VIEW "completedReminders" AS
    SELECT * FROM "reminders" WHERE "reminders"."isCompleted"
    """
  }
}

@Test func dropView() {
  assertInlineSnapshot(of: view.drop(), as: .sql) {
    """
    DROP VIEW "completedReminders"
    """
  }
}
```

**Invalid syntax placeholders** (1 test):
```swift
@Test func queryBuilderPlaceholder() {
  // Uses [] which is not valid PostgreSQL (it's a builder placeholder)
  assertInlineSnapshot(
    of: Item.insert {
      Item.Columns(title: #sql("'Foo'"), notes: #sql("[]"))
    },
    as: .sql
  ) {
    """
    INSERT INTO "items" ("title", "notes")
    VALUES ('Foo', [])
    """
  }
}
```

**CTE with empty query** (2 tests):
```swift
@Test func emptyWithClause() {
  // Generates empty SQL when .none is used
  assertInlineSnapshot(
    of: With {
      Reminder.where { !$0.isCompleted }
    } query: {
      Reminder.none.delete()
    },
    as: .sql
  ) {
    """

    """
  }
}
```

## Snapshot Testing Patterns

### Pattern 1: SQL Validation (Preferred)

```swift
@Test func selectWithWhere() async {
  await assertSQL(
    of: User.where { $0.id == 1 }.select { $0.name }
  ) {
    """
    SELECT "users"."name"
    FROM "users"
    WHERE ("users"."id") = (1)
    """
  }
}
```

**Key differences from inline snapshots**:
- ✅ Function must be `async`
- ✅ Uses `await assertSQL(of:)` instead of `assertInlineSnapshot(of:, as:)`
- ✅ Validates SQL against PostgreSQL before snapshotting

### Pattern 2: Inline Snapshot (Special cases)

```swift
@Test func emptyQuery() {
  assertInlineSnapshot(
    of: Reminder.none,
    as: .sql
  ) {
    """

    """
  }
}
```

**When required**:
- Empty SQL strings
- DDL statements
- Invalid syntax

### What Gets Tested

**SQL Structure**:
- Clause ordering (SELECT, FROM, WHERE, ORDER BY, LIMIT)
- Identifier quoting ("table"."column")
- Value binding (parameterized queries)
- Join syntax
- Subquery nesting
- CTE structure

**NOT Tested Here**:
- Database execution (tested in swift-records)
- Query results (tested in swift-records)
- Connection handling (tested in swift-records)

### When to Update Snapshots

**Update snapshot when**:
✅ You intentionally changed SQL generation
✅ You fixed a bug in SQL generation
✅ Upstream changed SQL format

**Fix code when**:
❌ Snapshot fails after merge
❌ SQL doesn't match upstream (unless PostgreSQL-specific)
❌ PostgreSQL-specific syntax is wrong

**Golden Rule**: Never update test expectations to match broken behavior

---

## SQL Expectation Patterns

### Expected Differences (PostgreSQL vs SQLite)

These differences are **JUSTIFIED** and tests should reflect them:

#### 1. NULL PRIMARY KEY Handling

**SQLite**:
```sql
INSERT INTO "users" ("id", "name") VALUES (NULL, 'Jane')
```

**PostgreSQL**:
```sql
INSERT INTO "users" ("name") VALUES ('Jane')
-- OR (when mixing with non-NULL)
INSERT INTO "users" ("id", "name") VALUES (DEFAULT, 'Jane')
```

**Why**: PostgreSQL forbids NULL in PRIMARY KEY columns

**Test Example**:
```swift
@Test func draftInsert() {
  assertInlineSnapshot(
    of: User.insert { User.Draft(name: "Jane") },
    as: .sql
  ) {
    """
    INSERT INTO "users" ("name") VALUES ('Jane')
    """
  }
}

@Test func mixedInsert() {
  assertInlineSnapshot(
    of: User.insert {
      User(id: 1, name: "Alice")
      User.Draft(name: "Bob")
    },
    as: .sql
  ) {
    """
    INSERT INTO "users" ("id", "name")
    VALUES (1, 'Alice'), (DEFAULT, 'Bob')
    """
  }
}
```

#### 2. Conflict Resolution Syntax

**SQLite**:
```sql
INSERT OR REPLACE INTO "users" ...
UPDATE OR IGNORE ...
```

**PostgreSQL**:
```sql
INSERT INTO "users" ... ON CONFLICT ("id") DO UPDATE ...
-- No UPDATE OR syntax
```

**Why**: Different SQL syntax between databases

**Test Example**:
```swift
@Test func upsert() {
  assertInlineSnapshot(
    of: User.upsert { User.Draft(name: "Alice") },
    as: .sql
  ) {
    """
    INSERT INTO "users" ("id", "name")
    VALUES (DEFAULT, 'Alice')
    ON CONFLICT ("id") DO UPDATE SET "name" = EXCLUDED."name"
    """
  }
}
```

#### 3. Type Casting

**PostgreSQL-Specific**:
```sql
SELECT "value"::INTEGER
```

**SQLite**:
```sql
SELECT CAST("value" AS INTEGER)
```

**Why**: PostgreSQL's `::` operator is more concise

#### 4. Function Name Differences

**PostgreSQL**: `string_agg(column, separator)`
**SQLite**: `group_concat(column, separator)`

**Test Example**:
```swift
@Test func stringAggregation() {
  assertInlineSnapshot(
    of: User.select { stringAgg($0.name, separator: ", ") },
    as: .sql
  ) {
    """
    SELECT string_agg("users"."name", ', ')
    FROM "users"
    """
  }
}
```

### Should Be Identical

These should match upstream expectations EXACTLY:

#### SELECT Statements
```swift
// Column aliasing works the same
SELECT "users"."name" AS "name"

// JOINs work the same
SELECT ... FROM "users" INNER JOIN "posts" ON ...

// Subqueries work the same
SELECT ... FROM (SELECT ...) AS "subquery"
```

#### WHERE Clauses
```swift
WHERE ("users"."id" = 1)
WHERE ("users"."name" LIKE '%test%')
WHERE ("users"."age" IN (20, 30, 40))
```

#### UPDATE Statements (except OR clauses)
```sql
UPDATE "users" SET "name" = 'Alice' WHERE ("id" = 1)
```

#### DELETE Statements
```sql
DELETE FROM "users" WHERE ("id" = 1)
```

#### Common Table Expressions
```sql
WITH "active_users" AS (SELECT ...) SELECT ...
```

#### Window Functions
```sql
SELECT ..., ROW_NUMBER() OVER (PARTITION BY ...)
```

#### Standard Aggregates
```sql
SELECT COUNT(*), SUM("amount"), AVG("score")
```

---

## PostgreSQL-Specific Test Cases

### Draft Insert Tests

**Test File**: `DraftPrimaryKeyTests.swift`, `DraftSQLGenerationTests.swift`

**Coverage**:
- Single Draft with NULL primary key
- Multiple Drafts with NULL primary keys
- Mixed records (some with ID, some without)
- Draft with ON CONFLICT on non-PK column
- Draft with ON CONFLICT on PK column (upsert)
- Edge cases (empty inserts, all NULL columns)

**Example**:
```swift
@Test func draftWithAllNullPrimaryKeys() {
  assertInlineSnapshot(
    of: Reminder.insert {
      Reminder.Draft(title: "Task 1")
      Reminder.Draft(title: "Task 2")
    },
    as: .sql
  ) {
    """
    INSERT INTO "reminders" ("title", "notes", "isCompleted", "isFlagged", "priority", "dueDate", "remindersListID", "assignedUserID", "updatedAt")
    VALUES ('Task 1', ...), ('Task 2', ...)
    """
    // Note: "id" column excluded entirely
  }
}
```

### ON CONFLICT Tests

**Test Scenarios**:
- ON CONFLICT with single column
- ON CONFLICT with compound key
- ON CONFLICT with WHERE clause (partial index)
- ON CONFLICT DO NOTHING
- ON CONFLICT DO UPDATE with exclusions

**Example**:
```swift
@Test func onConflictWithCompoundKey() {
  assertInlineSnapshot(
    of: TaggedReminder.insert { ... }
      .onConflict { ($0.reminderID, $0.tagID) }
      .doUpdate { ($0.updatedAt,) },
    as: .sql
  ) {
    """
    INSERT INTO "taggedReminders" (...)
    VALUES (...)
    ON CONFLICT ("reminderID", "tagID")
    DO UPDATE SET "updatedAt" = EXCLUDED."updatedAt"
    """
  }
}
```

### JSONB Operations

**Test File**: `PostgreSQLSpecificTests.swift`

**Coverage**:
- JSONB column selection
- JSONB operators (`->`, `->>`, `@>`, `<@`)
- JSONB functions (`jsonb_agg`, `jsonb_object_agg`)
- JSONB indexing

**Example**:
```swift
@Test func jsonbContains() {
  assertInlineSnapshot(
    of: User.where { $0.metadata.contains(["role": "admin"]) },
    as: .sql
  ) {
    """
    SELECT * FROM "users"
    WHERE ("users"."metadata" @> '{"role":"admin"}')
    """
  }
}
```

### Array Operations

**Test Coverage**:
- `array_agg()` function
- Array contains operator
- Array overlap operator
- Array indexing

**Example**:
```swift
@Test func arrayAggregation() {
  assertInlineSnapshot(
    of: User.select { arrayAgg($0.id) },
    as: .sql
  ) {
    """
    SELECT array_agg("users"."id")
    FROM "users"
    """
  }
}
```

### PostgreSQL-Specific Functions

**Test File**: `PostgreSQLFunctionsTests.swift`

**Coverage**:
- `ilike()` - Case-insensitive LIKE
- `extract()` - Date/time component extraction
- `dateTrunc()` - Date truncation
- `rowNumber()` - Window function
- `encodeHex()`, `decodeHex()` - Binary encoding
- `quoteLiteral()`, `quoteIdent()` - SQL quoting

**Example**:
```swift
@Test func caseInsensitiveLike() {
  assertInlineSnapshot(
    of: User.where { $0.name.ilike("%alice%") },
    as: .sql
  ) {
    """
    SELECT * FROM "users"
    WHERE ("users"."name" ILIKE '%alice%')
    """
  }
}
```

---

## Test Organization

### Directory Structure

Tests are organized to mirror the source code structure, making it easy to find tests for specific functionality:

```
Tests/StructuredQueriesPostgresTests/
├── Commands/                    # SQL command generation tests
│   ├── Select/
│   │   ├── SelectTests.swift         # Basic SELECT
│   │   ├── JoinTests.swift           # JOINs
│   │   ├── UnionTests.swift          # UNIONs
│   │   ├── SelectionTests.swift      # Column selection
│   │   └── NestedTests.swift         # Subqueries
│   ├── Insert/
│   │   ├── InsertTests.swift         # INSERT statements
│   │   └── MissingDraftTests.swift   # Draft handling
│   ├── Update/
│   │   └── UpdateTests.swift         # UPDATE statements
│   ├── Delete/
│   │   └── DeleteTests.swift         # DELETE statements
│   ├── CommonTableExpressions/
│   │   └── CommonTableExpressionTests.swift
│   └── Views/
│       └── ViewsTests.swift          # VIEW operations
│
├── Functions/                   # PostgreSQL function tests
│   ├── Aggregate/
│   │   └── ScalarFunctionsTests.swift
│   ├── Window/
│   │   └── WindowFunctionsTests.swift
│   ├── TextSearch/              # Full-text search (split into 4 files)
│   │   ├── FullTextSearchMatchingTests.swift
│   │   ├── FullTextSearchRankingTests.swift
│   │   ├── FullTextSearchFunctionsTests.swift
│   │   ├── FullTextSearchVectorsTests.swift
│   │   └── FullTextSearchTestSupport.swift
│   ├── JSONB/                   # JSONB operations (5 files)
│   │   ├── JSONBConversionTests.swift
│   │   ├── JSONBFunctionTests.swift
│   │   ├── JSONBIndexingTests.swift
│   │   ├── JSONBOperatorTests.swift
│   │   └── JSONBQueryBuildingTests.swift
│   ├── Conditional/
│   │   └── CaseTests.swift      # CASE expressions
│   └── JSON/
│       └── JSONFunctionsTests.swift
│
├── Core/                        # Core query building tests
│   ├── Table/
│   │   ├── TableTests.swift          # Table definitions
│   │   ├── EnumTableTests.swift      # Enum-based tables
│   │   └── PrimaryKeyedTableTests.swift
│   ├── Draft/
│   │   ├── DraftPrimaryKeyTests.swift    # NULL PK handling
│   │   └── DraftSQLGenerationTests.swift # Draft SQL
│   ├── QueryFragment/
│   │   ├── QueryFragmentTests.swift
│   │   └── BindingTests.swift        # Parameter binding
│   └── Decoding/
│       └── DecodingTests.swift       # Row decoding
│
├── Operators/
│   └── OperatorsTests.swift     # SQL operators
│
├── Syntax/
│   ├── PostgreSQLSyntaxTests.swift  # PostgreSQL-specific syntax
│   └── SQLSyntaxTests.swift         # General SQL syntax
│
├── Schema/
│   └── SchemaTests.swift        # Schema operations
│
├── Advanced/
│   ├── TriggersTests.swift      # Trigger generation
│   └── TriggerDefaultNameTests.swift
│
├── Integration/
│   ├── KitchenSinkTests.swift   # Complex scenarios
│   └── LiveTests.swift          # Real-world patterns
│
├── Edge Cases/
│   ├── EmptyInClauseTests.swift
│   ├── CompileTimeTests.swift
│   ├── EphemeralTests.swift
│   ├── InflectionTests.swift
│   ├── OverloadFavorabilityTests.swift
│   ├── PostgresJSONBCompileTest.swift
│   ├── SQLMacroTests.swift
│   ├── TaggedTests.swift
│   └── ValuesTests.swift
│
└── Support/
    ├── SnapshotTests.swift      # Base snapshot test suite
    └── TestUtils.swift          # Shared utilities
```

### Organization Principles

1. **Mirror Source Structure**: Test directories mirror `Sources/` for easy navigation
2. **Logical Grouping**: Related tests grouped by SQL command or feature area
3. **Split Large Files**: Files over 500 lines split into focused test files
4. **Shared Test Support**: Common test models and utilities in dedicated support files
5. **SnapshotTests Extension Pattern**: All test suites extend `SnapshotTests` base suite

### Finding Tests

**By Feature**:
- Window functions → `Functions/Window/WindowFunctionsTests.swift`
- Full-text search → `Functions/TextSearch/FullTextSearch*.swift`
- JSONB operations → `Functions/JSONB/JSONB*.swift`
- SELECT queries → `Commands/Select/SelectTests.swift`
- Draft inserts → `Core/Draft/DraftPrimaryKeyTests.swift`

**By SQL Command**:
- `Commands/Select/` - All SELECT-related tests
- `Commands/Insert/` - All INSERT-related tests
- `Commands/Update/` - All UPDATE-related tests
- `Commands/Delete/` - All DELETE-related tests

**Test File Sizes**:
- Most files: 200-400 lines (easy to navigate)
- Largest remaining: NestedTests (712 lines), TableTests (665 lines), SelectTests (553 lines)
- Split files: FullTextSearch (858 → 4 files of ~200 lines each)

### Test Support

**Shared Utilities**:

```
Tests/StructuredQueriesPostgresTests/Support/
├── SnapshotTests.swift         # Base suite for all tests
├── TestModels.swift            # @Table test models
└── TestUtils.swift             # Shared testing utilities
```

---

## Upstream Alignment

### Maintaining Compatibility

**Goal**: Test expectations should match upstream swift-structured-queries except for genuine PostgreSQL syntax differences

**Process**:
1. Port upstream tests to PostgreSQL
2. Run tests and compare failures
3. Determine if failures are:
   - ✅ Expected PostgreSQL differences → Update snapshot
   - ❌ Bugs in our implementation → Fix code
   - ⚠️ Unclear → Investigate further

### Porting Tests from Upstream

**Steps**:

1. **Copy test file** from upstream:
   ```bash
   cp /path/to/upstream/Tests/SelectTests.swift \
      Tests/StructuredQueriesPostgresTests/SelectTests.swift
   ```

2. **Update imports**:
   ```swift
   // Before (upstream)
   import StructuredQueriesCore

   // After (our fork)
   import StructuredQueriesCore
   ```

3. **Run tests** and identify failures

4. **For each failure**:
   - Check if it's a PostgreSQL-specific difference
   - If yes: Update snapshot with PostgreSQL syntax
   - If no: Fix implementation to match upstream

### When to Deviate from Upstream Expectations

**Only deviate when**:
- ✅ NULL PRIMARY KEY handling (use DEFAULT)
- ✅ Conflict resolution syntax (use ON CONFLICT)
- ✅ PostgreSQL-specific functions (different names/syntax)
- ✅ Type casting (:: operator)

**Never deviate for**:
- ❌ Column aliases
- ❌ JOIN syntax
- ❌ WHERE clauses
- ❌ Standard SQL functions
- ❌ CTEs, subqueries, window functions

### Quarterly Upstream Sync

**Process**:

```bash
# 1. Fetch upstream changes
cd /path/to/swift-structured-queries-postgres
git fetch upstream

# 2. Check for new tests
git diff upstream/main Tests/

# 3. Port new tests
# Copy new test files and adapt for PostgreSQL

# 4. Verify test expectations
# Run tests and ensure failures are justified
```

**What to Port**:
- New test files
- New test cases in existing files
- Bug fixes in test infrastructure
- Improvements to test patterns

---

## Testing Best Practices

### 1. Prefer SQL Validation

**Preferred** (for most tests):
```swift
@Test func selectUser() async {
  await assertSQL(of: User.all) {
    """
    SELECT "users"."id", "users"."name"
    FROM "users"
    """
  }
}
```

**Why**:
- Validates SQL is syntactically correct
- Catches errors early
- Still provides living documentation (SQL visible in test)

**Use inline snapshots only when**:
- SQL is empty
- DDL statements (CREATE/DROP VIEW)
- Intentionally invalid syntax

### 2. Make Tests Async When Using assertSQL

**Correct**:
```swift
@Test func myTest() async {
  await assertSQL(of: query) { ... }
}
```

**Incorrect**:
```swift
@Test func myTest() {  // Missing async
  await assertSQL(of: query) { ... }  // Won't compile
}
```

### 3. Keep Expected SQL Unchanged

When upgrading from `assertInlineSnapshot` to `await assertSQL`:
- ✅ Change function signature to add `async`
- ✅ Change `assertInlineSnapshot(of: X, as: .sql)` to `await assertSQL(of: X)`
- ❌ DON'T change the expected SQL string
- ❌ DON'T reformat the SQL unless it's actually wrong

### 4. Test One Thing Per Test

**Good**:
```swift
@Test func selectWithWhere() { ... }
@Test func selectWithOrderBy() { ... }
@Test func selectWithLimit() { ... }
```

**Bad**:
```swift
@Test func selectWithEverything() {
  // Tests WHERE, ORDER BY, LIMIT, JOIN all at once
}
```

### 5. Name Tests Descriptively

**Good**:
```swift
@Test func draftInsertExcludesPrimaryKeyColumn() { ... }
@Test func mixedInsertUsesDefaultForDrafts() { ... }
```

**Bad**:
```swift
@Test func test1() { ... }
@Test func insertTest() { ... }
```

### 6. Group Related Tests

```swift
@Suite("Draft Insert Tests")
struct DraftInsertTests {
  @Test func singleDraft() { ... }
  @Test func multipleDrafts() { ... }
  @Test func mixedRecordsAndDrafts() { ... }
}
```

### 7. Test Edge Cases

**Don't forget**:
- Empty collections
- NULL values
- Boundary conditions
- Error cases (compilation errors)

### 8. Keep Tests Fast

**Tests are fast** because:
- Snapshot tests: No database I/O (~2ms per test)
- SQL validation: Only EXPLAIN calls (~10ms per test)
- No actual query execution

**Maintain speed**:
- Use SQL validation by default (still fast)
- Only use inline snapshots when required
- Keep test data small
- Don't perform actual queries (use EXPLAIN only)

### 9. Document PostgreSQL-Specific Tests

```swift
@Test func draftInsertExcludesPrimaryKey() async {
  // PostgreSQL forbids NULL in PRIMARY KEY columns
  // We must exclude the PK column when all values are NULL
  await assertSQL(of: ...) { ... }
}
```

---

## Common Testing Patterns

### Pattern 1: Basic Query

```swift
@Test func basicSelect() {
  let query = User.all

  assertInlineSnapshot(of: query, as: .sql) {
    """
    SELECT "users"."id", "users"."name", "users"."email"
    FROM "users"
    """
  }
}
```

### Pattern 2: Query with Builder Methods

```swift
@Test func selectWithWhereAndOrder() {
  let query = User
    .where { $0.isActive }
    .order(by: \.name)
    .limit(10)

  assertInlineSnapshot(of: query, as: .sql) {
    """
    SELECT "users"."id", "users"."name", "users"."email"
    FROM "users"
    WHERE ("users"."isActive" = true)
    ORDER BY "users"."name"
    LIMIT 10
    """
  }
}
```

### Pattern 3: INSERT with Values

```swift
@Test func insertSingleValue() {
  let query = User.insert {
    User(id: 1, name: "Alice", email: "alice@example.com")
  }

  assertInlineSnapshot(of: query, as: .sql) {
    """
    INSERT INTO "users" ("id", "name", "email")
    VALUES (1, 'Alice', 'alice@example.com')
    """
  }
}
```

### Pattern 4: JOIN Queries

```swift
@Test func innerJoin() {
  let query = User
    .join(Post.self) { $0.id == $1.userID }
    .select { ($0.name, $1.title) }

  assertInlineSnapshot(of: query, as: .sql) {
    """
    SELECT "users"."name", "posts"."title"
    FROM "users"
    INNER JOIN "posts" ON ("users"."id" = "posts"."userID")
    """
  }
}
```

### Pattern 5: Subqueries

```swift
@Test func subqueryInWhere() {
  let subquery = Post.where { $0.status == "published" }.select { $0.userID }
  let query = User.where { $0.id.in(subquery) }

  assertInlineSnapshot(of: query, as: .sql) {
    """
    SELECT "users".*
    FROM "users"
    WHERE ("users"."id" IN (
      SELECT "posts"."userID"
      FROM "posts"
      WHERE ("posts"."status" = 'published')
    ))
    """
  }
}
```

### Pattern 6: CTEs (Common Table Expressions)

```swift
@Test func commonTableExpression() {
  let activeUsers = CTE("active_users") {
    User.where { $0.isActive }
  }

  let query = activeUsers
    .join(Post.self) { $0.id == $1.userID }

  assertInlineSnapshot(of: query, as: .sql) {
    """
    WITH "active_users" AS (
      SELECT * FROM "users" WHERE ("users"."isActive" = true)
    )
    SELECT * FROM "active_users"
    INNER JOIN "posts" ON ("active_users"."id" = "posts"."userID")
    """
  }
}
```

---

## Test Debugging

### When Tests Fail

**1. Check the diff**:
```
Expected:
  SELECT "users"."name" AS "name"
Actual:
  SELECT "users"."name"
```

**2. Determine why**:
- Is this a PostgreSQL-specific difference? → Update snapshot
- Is this a bug in our implementation? → Fix code
- Did upstream change? → Port upstream fix

**3. Take action**:
- Fix code (preferred)
- Update snapshot (only if justified)
- Document reason (always)

### Running Tests

**IMPORTANT**: Always use release mode for this package (debug builds have linker errors):

```bash
# Run all tests WITHOUT SQL validation (fast, ~0.5s)
swift test -c release

# Run all tests WITH SQL validation (slower, ~2-3s, requires PostgreSQL)
swift test -c release --enable-trait StructuredQueriesPostgresSQLValidation

# Run specific test suite
swift test -c release --filter WindowClauseTests

# Run with custom PostgreSQL connection
POSTGRES_URL=postgres://user:pass@localhost:5432/mydb swift test -c release --enable-trait StructuredQueriesPostgresSQLValidation
```

**SQL Validation Setup**:

1. **Install PostgreSQL** (if not already installed):
   ```bash
   # macOS
   brew install postgresql@16
   brew services start postgresql@16

   # Linux
   sudo apt-get install postgresql-16
   sudo systemctl start postgresql
   ```

2. **Create test database**:
   ```bash
   createdb test
   ```

3. **Enable SQL validation trait** (optional - add to Package.swift):
   ```swift
   .testTarget(
     name: "StructuredQueriesPostgresTests",
     // ...
     swiftSettings: [
       .enableExperimentalFeature("Testing"),
       .define("StructuredQueriesPostgresSQLValidation", .when(configuration: .release))
     ]
   )
   ```

**Performance Comparison**:

| Mode | Duration | Tests/sec | Use Case |
|------|----------|-----------|----------|
| No validation | ~0.5s | ~560 tests/sec | Development (fast feedback) |
| With validation | ~2-3s | ~140 tests/sec | CI/CD (catch SQL errors) |

### Snapshot Update Workflow

**When you need to update snapshots**:

1. Review the failure carefully
2. Confirm the new SQL is correct
3. Update the snapshot inline
4. Document why in commit message

**Example commit**:
```
Update snapshot for ILIKE operator

PostgreSQL uses ILIKE for case-insensitive LIKE, while SQLite uses
LIKE with COLLATE NOCASE. Updated snapshot to reflect PostgreSQL syntax.
```

---

## Test Coverage Goals

**Current Coverage**: 280+ tests across 35+ suites

**Test Distribution**:
- 143 tests using `await assertSQL` (SQL validation)
- 36 tests using `assertInlineSnapshot` (special cases)
- Remaining tests use other patterns (macro tests, etc.)

**Coverage by Area**:
- ✅ SELECT statements: Comprehensive (with SQL validation)
- ✅ INSERT statements: Comprehensive (with SQL validation, Draft handling)
- ✅ UPDATE statements: Comprehensive (with SQL validation)
- ✅ DELETE statements: Comprehensive (with SQL validation)
- ✅ JOINs: Comprehensive (with SQL validation)
- ✅ Window functions: Comprehensive (with SQL validation)
- ✅ CTEs: Comprehensive (with SQL validation)
- ✅ Aggregate functions: Comprehensive (with SQL validation)
- ✅ Scalar functions: Comprehensive (with SQL validation)
- ✅ PostgreSQL-specific: Comprehensive (JSONB, arrays, full-text search)
- ✅ Views: Good (DDL uses inline snapshots, SELECT uses validation)

**SQL Validation Coverage**:
- All DML statements (SELECT, INSERT, UPDATE, DELETE): ✅ Validated
- All JOINs and subqueries: ✅ Validated
- All window functions: ✅ Validated
- All CTEs: ✅ Validated (except empty ones)
- DDL statements (CREATE/DROP VIEW): ❌ Not validated (EXPLAIN limitation)
- Empty SQL: ❌ Not validated (EXPLAIN limitation)

**Target**: Maintain >80% SQL validation coverage for all new tests

---

## Future Testing Improvements

1. **Performance benchmarking**: Track SQL generation performance
2. **Fuzzing**: Generate random queries to find edge cases
3. **Upstream test sync automation**: Automatically port new upstream tests
4. **Snapshot diffing tools**: Better visualization of snapshot failures
5. **Test categorization**: Tag tests by PostgreSQL-specificity

---

**For architectural context on why tests are structured this way, see ARCHITECTURE.md**
**For historical context on testing decisions, see HISTORY.md**
