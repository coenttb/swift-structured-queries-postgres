# Development History

**Purpose**: This is an append-only chronicle. Never edit past entries, only add new ones at the end.

**For current architecture**: See ARCHITECTURE.md
**For testing patterns**: See TESTING.md

---

## 2025-10-08: Fork Creation & Initial Audit

### Context

Created PostgreSQL fork of `pointfreeco/swift-structured-queries` (SQLite-focused) to support type-safe PostgreSQL query generation. Needed to adapt SQLite-specific code to PostgreSQL's stricter requirements while maintaining upstream compatibility.

### Audit Findings Summary

**Comparison Scope**:
- Upstream commit: `dcf489fcac7fee26d7d33df25479e6b6c5584212`
- Fork commit: `f3c15b696046e549fbfbbb18da8cf61dab1453cc`
- Total files compared: 48 upstream, 55 fork

**Results**:
- Justified differences: 12 items (PostgreSQL-specific requirements)
- Unjustified differences: 6 items (ALL RESOLVED)
- Suspicious differences: 0 items (all investigated)
- Code divergence: ~3.7% PostgreSQL-specific (under 5% target)

### Critical Unjustified Divergences (Now Resolved)

#### 1. Missing ScalarFunctions.swift (✅ RESOLVED)

**Problem**: Fork was missing 368 lines of database-agnostic SQL functions

**Functions Missing**:
- String: `length()`, `lower()`, `upper()`, `trim()`, `substr()`, `replace()`, `hex()`
- Numeric: `round()`, `abs()`, `sign()`
- Optional: `ifnull()`, `??` (coalesce operator)

**Why Missing**: Unknown - these functions work identically in PostgreSQL and SQLite

**Resolution**: Copied entire file from upstream, no modifications needed

**Impact**: HIGH - Users could not use common SQL functions

#### 2. Removed Sequence-Based find() Methods (✅ RESOLVED)

**Problem**: Fork only supported single primary key lookup, upstream supported collections

**Upstream Pattern**:
```swift
User.find([1, 2, 3]) // Generates: WHERE "id" IN (1, 2, 3)
```

**Fork Pattern (Broken)**:
```swift
User.find(1) // Only single value supported
// Had to manually write: User.where { $0.id.in([1, 2, 3]) }
```

**Why Removed**: Unknown - PostgreSQL fully supports IN clauses

**Resolution**: Restored all sequence-based find() methods across 10 extensions:
- Main `PrimaryKeyed` extension
- `Where<Table>` extensions
- `Select<_, Table, _>` extensions
- `Update<Table, _>` extensions
- `Delete<Table, _>` extensions

**Impact**: MAJOR - Significant functionality loss affecting users

#### 3. Modified PrimaryKey Constraints (✅ RESOLVED)

**Problem**: Fork narrowed type constraints without justification

**Upstream**:
```swift
associatedtype PrimaryKey: QueryRepresentable & QueryExpression
```

**Fork (Wrong)**:
```swift
associatedtype PrimaryKey: QueryBindable
where PrimaryKey.QueryValue == PrimaryKey,
      PrimaryKey.QueryValue.QueryOutput: Sendable
```

**Why Changed**: Attempt to "fix" type resolution issues

**Resolution**: Reverted to upstream constraints

**Lesson**: Upstream's constraints are proven - don't try to "improve" them

#### 4. TableColumn KeyPath Backing Storage Pattern (✅ RESOLVED)

**Problem**: Fork added unnecessary complexity

**Upstream (Direct)**:
```swift
public let keyPath: KeyPath<Root, Value.QueryOutput>
```

**Fork (Overcomplicated)**:
```swift
let _keyPath: KeyPath<Root, Value.QueryOutput>
public var keyPath: KeyPath<Root, Value.QueryOutput> { _keyPath }
```

**Why Changed**: Unknown

**Resolution**: Reverted to direct property pattern

**Files Updated**:
- `TableColumn.swift` (lines 59-72, 160-164)
- `TableAlias.swift` (lines 149, 159) - changed `._keyPath` back to `.keyPath`

#### 5. Table.swift Constraint Addition (✅ RESOLVED)

**Problem**: Fork added unnecessary protocol constraint

**Upstream**:
```swift
public protocol Table: QueryRepresentable, PartialSelectStatement
```

**Fork (Wrong)**:
```swift
public protocol Table: QueryRepresentable, PartialSelectStatement
where TableColumns.QueryValue == Self  // ← Unnecessary
```

**Resolution**: Removed the `where` clause

**Also Fixed**: Restored `@_disfavoredOverload` attribute (line 100) that fork had removed

#### 6. TableAlias.swift Missing Features (✅ RESOLVED)

**Problem**: Fork removed several upstream features without justification

**Missing Feature 1**: ColumnGroup subscript support
**Missing Feature 2**: Internal query APIs (`_columnWidth`, `_allColumns`)
**Missing Feature 3**: Conditional aliasing extensions for `PrimaryColumn`

**Resolution**: Restored all features from upstream

**Why These Matter**: Used by macro-generated code and upstream patterns

### Resolution Summary

**Total Changes**: ~800 lines across 6 files
**Time to Complete**: 6 hours (including testing and documentation)
**Outcome**: All tests passing, build successful, aligned with upstream patterns

### Confirmed Justified Differences

These differences **must remain** - they are PostgreSQL-specific requirements:

#### 1. NULL PRIMARY KEY Handling (Insert.swift)

**Lines**: 1-20 (helper), 649-1161 (extensions)

**Why Necessary**: PostgreSQL forbids NULL in PRIMARY KEY columns (SQLite allows it)

**Implementation Quality**: Excellent - comprehensive handling of all edge cases

**Test Coverage**:
- `DraftPrimaryKeyTests.swift`
- `DraftSQLGenerationTests.swift`
- `DraftWritableColumnsTests.swift`
- `DraftWritableColumnsTypesTests.swift`

#### 2. Conflict Resolution Syntax Differences

**SQLite Removed**:
- `conflictResolution` property (INSERT OR REPLACE, UPDATE OR IGNORE)
- `ConflictResolution.swift` file

**PostgreSQL Uses**: ON CONFLICT DO UPDATE syntax instead

**Files Modified**:
- `Insert.swift` - Removed conflict resolution property
- `Update.swift` - Removed conflict resolution property

#### 3. PostgreSQL-Specific Functions

**New Files Added**:
- `PostgreSQL/JSONAggregation.swift` - `json_agg()`, `json_object_agg()`
- `PostgreSQL/PostgreSQLFunctions.swift` - ILIKE, EXTRACT, DATE_TRUNC, etc.
- `PostgreSQL/PostgreSQLAggregates.swift` - Statistical functions
- `PostgreSQL/PostgresJSONB.swift` - JSONB type support
- `Cast.swift` - PostgreSQL type casting (`::type` syntax)

**Why Necessary**: PostgreSQL-exclusive features not available in SQLite

#### 4. Swift 6.2 Compiler Bug Workaround (Select.swift)

**Lines**: 393-415

**Issue**: CSSimplify.cpp:16157 assertion failure with dynamic member lookup

**Workaround**: Scoped to `compiler(>=6.1) && compiler(<6.2)`

**Action Required**: Remove when Swift compiler bug is fixed

### Health Metrics

**Final Status** (2025-10-08):
- ✅ Build Status: Successful (xcodebuild)
- ✅ Test Status: All 148 tests passing
- ✅ Code Divergence: ~3.7% PostgreSQL-specific (under 5% target)
- ✅ Unjustified Divergences: 0 (all resolved)
- ✅ Documentation: Complete
- ✅ Overall Health: HEALTHY

---

## 2025-10-08: Upstream Alignment Learnings

### Key Principle Discovered

**"Most differences from upstream are bugs, not features"**

When maintaining a fork of an existing library:
1. **Always check upstream first** before attempting custom solutions
2. **Copy upstream patterns exactly** - they've already solved the type system challenges
3. **Only diverge when necessary** for platform-specific differences
4. **Use the same test expectations** unless there's a genuine platform difference

### Critical Technical Issues Encountered

#### 1. Swift 6.2 Compiler Bug: Dynamic Member Lookup

**Issue**: CSSimplify.cpp:16157 assertion failure when using `Type.self[keyPath: keyPath]` with `@dynamicMemberLookup`

**Triggering Code**:
```swift
public static subscript(
    dynamicMember keyPath: KeyPath<PrimaryTable.Type, some Statement<PrimaryTable>>
) -> some Statement<Self> {
    SQLQueryExpression("\(PrimaryTable.self[keyPath: keyPath])")  // ← CRASH
}
```

**Initial Approach**: Disabled @dynamicMemberLookup with `#if compiler(<6.2)`

**Correct Solution**: Re-enable all dynamic member lookup - upstream has it working

**Lesson**: Don't work around compiler bugs by disabling features. Copy upstream's working implementation exactly. The bugs may be environmental or already fixed.

**Workaround for Development**: Use `xcodebuild` instead of `swift test` when Swift 6.2 compiler crashes occur

#### 2. Missing Column Aliases in SELECT Statements

**Issue**: Tests failing with missing `AS "columnName"` aliases

**Expected SQL**:
```sql
SELECT "reminders"."title" AS "reminderTitle"
```

**Got (Broken)**:
```sql
SELECT "reminders"."title"
```

**Root Cause**: Missing `$_isSelecting.withValue(true)` when evaluating selection closures

**Key Insight**: Column aliases are NOT a SQLite vs PostgreSQL difference. They're required for:
- **@Selection types**: Mapping Swift property names (`reminderTitle: $0.title`)
- **CTEs (Common Table Expressions)**: Defining column names for WITH clauses
- **Type-safe decoding**: QueryDecoder matching column names to Swift properties

**Solution**: Add TaskLocal wrapper in Select.swift:
```swift
columns: columns
    + $_isSelecting.withValue(true) {
        Array(repeat each selection((From.columns, repeat (each J).columns)))
    },
```

**Critical Detail**: Must be inline, not extracted to a variable (causes "ambiguous use of init" error)

**Test Assessment**: ✅ Tests were CORRECT - we did not update test expectations to match broken behavior

#### 3. Missing ON CONFLICT Target Columns

**Issue**: PostgreSQL `ON CONFLICT` clause missing column specification

**Expected SQL**:
```sql
ON CONFLICT ("id") DO UPDATE SET ...
```

**Got (Broken)**:
```sql
ON CONFLICT DO UPDATE SET ...
```

**Root Causes**:
1. Missing `_TableColumnExpression` constraint on parameter pack
2. Using `.name` instead of `._names` (compound keys)

**Solution**: Fix Insert.swift parameter pack and column extraction:

**Before (Broken)**:
```swift
fileprivate static func _insert<each ConflictTarget>(
    onConflict conflictTargets: (TableColumns) -> (repeat TableColumn<Self, each ConflictTarget>)?,
) {
    for column in repeat each conflictTargets {
        conflictTargetColumnNames.append(column.name)  // Wrong!
    }
}
```

**After (Correct)**:
```swift
fileprivate static func _insert<each ConflictTarget: _TableColumnExpression>(
    onConflict conflictTargets: (TableColumns) -> (repeat each ConflictTarget)?,
) {
    for column in repeat each conflictTargets {
        conflictTargetColumnNames.append(contentsOf: column._names)  // Correct!
    }
}
```

**Why `._names` not `.name`**: Supports compound primary keys `PRIMARY KEY (col1, col2)`

#### 4. Missing _TableColumn Enum

**Issue**: Macro-generated code referenced `_TableColumn.for()` but enum didn't exist

**Error**:
```swift
// Macro generates:
let id = _TableColumn.for("id", keyPath: \.id)
// Error: Module has no member named '_TableColumn'
```

**Solution**: Copy complete `_TableColumn` enum from upstream (TableColumn.swift:103-130)

**Lesson**: When compiler says "missing member", search upstream for that exact identifier

### PostgreSQL vs SQLite: Actual Differences

**The ONLY genuine difference requiring custom logic**:

**NULL in PRIMARY KEY Columns**:
- **SQLite**: Allows NULL (treats as unique value)
- **PostgreSQL**: NEVER allows NULL (constraint violation)

**Our Solution** (Insert.swift):
- Detect NULL primary key values with `isNullBinding()`
- Replace with `DEFAULT` keyword for auto-generation
- Exclude PK column entirely when all values are NULL

**Example**:
```sql
-- Draft with NULL id (PostgreSQL)
INSERT INTO "users" ("id", "name") VALUES (DEFAULT, 'Jane')

-- Would fail in PostgreSQL
INSERT INTO "users" ("id", "name") VALUES (NULL, 'Jane')
```

**Everything Else: Same!**

Column aliases, CTEs, joins, window functions, etc. - all work identically in both databases.

### Testing Strategy Learned

#### Use Both Build Systems

- **xcodebuild**: Stable, works with Swift 6.2 compiler
- **swift test**: Faster, but triggers Swift 6.2 bugs

#### Test Expectations Philosophy

**Never update test snapshots to match broken behavior**

When tests fail:
1. Check upstream test expectations FIRST
2. If upstream expects the same output, YOUR CODE is wrong
3. Only update tests when:
   - Genuine PostgreSQL vs SQLite difference
   - Upstream test is also updated
   - You've verified the SQL is correct in actual PostgreSQL

### Critical Files Modified

| File | Change | Why |
|------|--------|-----|
| `TableColumn.swift` | Added `_TableColumn` enum | Macro-generated code support |
| `TableColumn.swift` | Added `_allColumns`, `_writableColumns` | Fragment generation |
| `TableAlias.swift` | Fixed Selection struct pattern | Proper TableExpression conformance |
| `_Selection.swift` | Simplified to marker protocol | Match upstream exactly |
| `Insert.swift` | Added `_TableColumnExpression` constraint | Proper parameter pack typing |
| `Insert.swift` | Use `._names` not `.name` | Compound key support |
| `Select.swift` | Added `$_isSelecting.withValue(true)` | Column alias generation |
| `Optional.swift` | Complete Table conformance | Support Draft pattern |

### Files That Did NOT Need Changes

- **Test files**: All test expectations were correct
- **PostgreSQL NULL handling**: Already correct from previous work
- **Database query execution**: Works with updated SQL generation

### Key Takeaways

1. **Trust upstream**: They've already solved the Swift type system puzzles
2. **Copy exactly**: Small differences in type constraints matter enormously
3. **Test expectations are documentation**: Don't change them to match bugs
4. **Platform differences are rare**: Most "differences" are actually bugs in your fork
5. **Use both build systems**: xcodebuild for stability, swift test for speed
6. **Cross-reference continuously**: Keep upstream repo open during work
7. **Parameter packs are finicky**: Constraints like `<each T: Protocol>` are critical
8. **TaskLocal for context**: `$_isSelecting` pattern for contextual behavior
9. **Protocol conformance is all-or-nothing**: Missing one requirement breaks everything
10. **Compiler bugs exist**: But don't work around them - copy working upstream code

### Metrics

- **Test suite**: 148 tests in 24 suites
- **Initial failures**: 13 snapshot mismatches
- **Categories**: 2 (column aliases, ON CONFLICT)
- **Platform-specific code**: <5% (only NULL PRIMARY KEY handling)
- **Time to resolution**: ~3 hours of careful upstream comparison
- **Final result**: 100% test passage ✅

---

## 2025-10-08: Package Boundary Clarification & Deduplication

### Problem Discovered

swift-records previously contained ~500 lines of duplicate query language code that conflicted with upstream functionality and belonged in swift-structured-queries-postgres.

**Issue**: Ambiguity errors when using both packages together

### Code Removed from swift-records

The following were moved to swift-structured-queries-postgres where they belong:

**Aggregate Functions**:
- `count()`
- `sum()`
- `avg()`
- `max()`
- `min()`

**Scalar Functions**:
- `length()`, `lower()`, `upper()`, `trim()`
- `round()`, `abs()`, `sign()`
- String functions
- Coalesce operators

**PostgreSQL-Specific Query Operators**:
- `ilike()` (case-insensitive LIKE)

**PostgreSQL Aggregate Functions**:
- `arrayAgg()`
- `jsonAgg()`
- `stringAgg()`
- Statistical functions

### Package Boundary Rules Established

**swift-structured-queries-postgres** (Query Language):
- ✅ ALL query language (SQL building)
- ✅ Returns `Statement<QueryValue>` types
- ❌ NO database operations

**swift-records** (Database Operations):
- ✅ ONLY database operations (execution, connection management, migrations)
- ✅ Executes statements via `.execute(db)`, `.fetchAll(db)`, `.fetchOne(db)`
- ❌ NO query language code

**Clear Separation Achieved**:
```swift
// Query building (swift-structured-queries-postgres)
let statement = User.where { $0.isActive }

// Execution (swift-records)
let users = try await statement.fetchAll(db)
```

### Benefits

- ✅ Eliminated ambiguity errors
- ✅ Clean package separation
- ✅ Upstream alignment
- ✅ Better maintainability
- ✅ No duplicate code

---

## 2025-10-09: Documentation Consolidation into 3-File Architecture

### Motivation

Scattered documentation files (CLAUDE.md, FORK_AUDIT.md, MERGE_LEARNINGS.md, TEST_AUDIT.md, IMPLEMENTATION_PLAN.md, AUDIT_PROMPT.md, TEST_AUDIT_PROMPT.md) made it difficult to:
- Find current architectural decisions
- Understand testing patterns
- Preserve institutional knowledge
- Maintain documentation

### Decision

Consolidated into 3-file architecture:
1. **ARCHITECTURE.md** - Living reference for current architecture (update when architecture changes)
2. **TESTING.md** - Living guide for testing patterns (update when test patterns evolve)
3. **HISTORY.md** - Append-only chronicle of decisions and evolution (never edit, only append)

### Why 3 Files Instead of 2?

**Key Insight**: Separate living documentation from historical narrative

- ✅ ARCHITECTURE.md stays clean and current (no "we tried X" narratives)
- ✅ HISTORY.md preserves institutional knowledge forever
- ✅ No mental overhead deciding what history to keep/remove when refactoring
- ✅ Future maintainers understand "why" without cluttering active references

### Files Created

1. **ARCHITECTURE.md**: Package overview, design principles, PostgreSQL differences, query building architecture, integration points, maintenance guidelines
2. **TESTING.md**: Test infrastructure, snapshot patterns, SQL expectations, PostgreSQL-specific tests, test organization, upstream alignment
3. **HISTORY.md**: This file - complete chronicle of decisions

### Files Archived

Moved to `.archive/` directory:
- `FORK_AUDIT.md` (content consolidated into HISTORY.md)
- `TEST_AUDIT.md` (content consolidated into TESTING.md and HISTORY.md)
- `AUDIT_PROMPT.md` (historical artifact)
- `TEST_AUDIT_PROMPT.md` (historical artifact)
- `IMPLEMENTATION_PLAN.md` (content consolidated into HISTORY.md)

### Files Deleted

- `MERGE_LEARNINGS.md` - Content fully consolidated into ARCHITECTURE.md and HISTORY.md

### CLAUDE.md Updated

Slimmed down to quick reference with pointers to detailed docs:
- Critical NULL PRIMARY KEY handling reference
- Package boundaries reminder
- Maintenance checklist
- Links to ARCHITECTURE.md, TESTING.md, HISTORY.md

### Benefits

- ✅ Easy to find current architecture (ARCHITECTURE.md)
- ✅ Easy to find testing patterns (TESTING.md)
- ✅ Historical context preserved (HISTORY.md)
- ✅ No redundant information
- ✅ Clear separation of concerns
- ✅ Better maintainability

---

## 2025-10-12: Swift Test/Build Resolution

### Problem

`swift test` was failing with "missing required module 'SwiftCompilerPlugin'" error, while `swift build` worked fine. Documentation incorrectly attributed this to a Swift 6.2 compiler bug and required using `xcodebuild` workaround.

### Root Causes

Three Package.swift configuration issues:

1. **Hardcoded module references**: TableMacro.swift used `StructuredQueriesCore.QueryExpression` instead of the `moduleName` variable (`StructuredQueriesCore`)
2. **Duplicate library product**: `.library` product declaration for macro target (macro targets should only be `.macro`)
3. **Missing dependency**: `SwiftCompilerPlugin` not explicitly added to macro test target dependencies

### Solution

1. Fixed TableMacro.swift (lines 1201 & 1327): `StructuredQueriesCore.QueryExpression` → `\(moduleName).QueryExpression`
2. Removed duplicate `.library` product for `StructuredQueriesPostgresMacros` from Package.swift
3. Added `SwiftCompilerPlugin` dependency to `StructuredQueriesPostgresMacrosTests` target

### Result

- ✅ Both `swift build` and `swift test` now work with standard Swift Package Manager
- ✅ No need for `xcodebuild` workaround
- ✅ CI workflows simplified (removed fallback logic)
- ✅ All documentation updated to reflect standard SPM commands

### Key Lessons

1. **Package configuration errors can masquerade as compiler bugs** - When one SPM command works but another fails, investigate Package.swift first
2. **Macro targets don't need library products** - The `.macro` target type is sufficient and automatically exposed
3. **Test targets importing macros need explicit SwiftCompilerPlugin dependency** - SPM limitation/workaround
4. **Module name variables exist for a reason** - Always use parameterized module names in generated code

### Files Updated

- `Sources/StructuredQueriesPostgresMacros/TableMacro.swift` - Fixed hardcoded module references
- `Package.swift` - Removed duplicate library product, added SwiftCompilerPlugin dependency
- `.github/workflows/ci.yml` - Simplified to use standard `swift build/test`
- Documentation files - Updated build instructions (CLAUDE.md, README.md, TESTING.md, ARCHITECTURE.md, PACKAGE_GUIDE.md)

---

## 2025-10-12: Type System Improvements - any→some Migration

### Objective

Eliminate existential types (`any`) in favor of opaque types (`some`) for better type inference and performance.

### Results

**Successfully converted**: 10 operator overloads from `any` to `some`
- Mathematical operators: `prefix -`, `prefix +`, `prefix ~` (3)
- Parameter types in Select+Limit.swift and PostgreSQLFunctions.swift (5)
- Trailing comma/whitespace cleanup via SwiftLint (cosmetic)

**Compiler bugs still present**: 3 workarounds remain necessary
- `Operators+Logical.swift:71` - `prefix !` requires `any QueryExpression<Bool>`
- `Operators+Comparison.swift:164-251` - Comparison operators require `any` on left side (8 overloads)
- `Updates.swift:28` - Subscript must return `any QueryExpression<Value>`

**Root cause**: Swift compiler bug with `Updates[dynamicMember:]` overload resolution using opaque types

### Canary Tests

Created `CompilerBugCanaryTests.swift` with disabled test suite that documents:
- Exact code changes needed to test if bugs are fixed
- Expected SQL output when working correctly
- Instructions for future Swift releases

### SwiftLint Configuration

Optimized `.swiftlint.yml` for PostgreSQL query DSL:
- Disabled `redundant_type_annotation` (required by `@Table` macro)
- Disabled `large_tuple`, `force_cast` (intentional DSL patterns)
- Excluded macro files (naturally complex)
- Added custom rules: `no_sqlite_null_pk`, `prefer_some_over_any`
- Result: 441 violations → 75 warnings (0 errors)

### Impact

- ✅ Improved type inference where compiler bugs don't block
- ✅ Documented remaining limitations for future resolution
- ✅ Cleaner codebase with automated style fixes
- ✅ 280+ tests passing

---

## 2025-10-13: Column Group Feature Completion

### Status

Column groups achieved **100% parity** with standard table operations, reaching production-ready status.

### Implementation

**Key Achievement**: Custom `.eq()` method bypasses `@dynamicMemberLookup` precedence for WHERE clauses

**Location**: `ColumnGroup.swift:91-105`

```swift
extension TableColumn where Value: ColumnGroup {
    public func eq(_ value: Value) -> some QueryExpression<Bool> {
        // Custom implementation for nested comparison
        zip(expression._allColumns, value._allColumns)
            .map { ($0.queryFragment, $1) }
            .reduce(...)
    }
}
```

**Fully Supported Operations**:
- ✅ SELECT with column groups
- ✅ INSERT with full and partial column groups
- ✅ UPDATE with full groups and nested fields
- ✅ WHERE clauses with `.eq()` method
- ✅ Optional column groups
- ✅ Nested column groups (multiple levels)
- ✅ Generated columns within column groups
- ✅ Composite primary keys as column groups

### Test Coverage

**Test Files**:
- `ColumnGroupTests.swift` - Core functionality
- `EnumTableTests.swift:186` - Enum tables with @CasePathable
- Production table tests (Attachment, Metadata examples)

**Edge Cases Covered**:
- Partial INSERT operations
- Nested UPDATE operations
- Optional column group comparison
- Multi-level nesting

### Design Insight

**Problem**: `@dynamicMemberLookup` takes precedence over custom operators, preventing natural WHERE syntax

**Solution**: Explicit `.eq()` method instead of `==` operator overload

```swift
// Works ✅
Item.where { $0.status.eq(Status()) }

// Would require `.eq()` if we used == (precedence issue)
```

### Documentation

**Files Updated**:
- `ARCHITECTURE.md:897-963` - Complete feature documentation
- `COLUMN_GROUP_PARITY.md` - Comprehensive analysis (now historical)

### Impact

- ✅ Production-ready column group support
- ✅ Complete parity with standard columns
- ✅ Clean API with minimal workarounds
- ✅ 280+ tests passing including column group tests

---

## 2025-10-13: Build System Investigations & Resolutions

### Historical Context

Between 2025-10-08 and 2025-10-13, the package experienced various build system challenges that were investigated and ultimately resolved through Package.swift configuration fixes.

### Investigation Timeline

#### Phase 1: Debug Build Failures (SWIFT_BUILD_ISSUE.md)

**Problem**: `swift build` in debug mode failed with SwiftSyntax linker errors

**Error**:
```
Undefined symbols: SwiftSyntax.SyntaxRewriter
```

**Initial Theory**: Swift compiler batch mode bug in debug builds

**Workaround Documented**: Use `swift build -c release` for all builds

**Root Cause**: Later discovered to be Package.swift configuration issue (Phase 3)

#### Phase 2: Xcode/SPM Conflicts (XCODE_SPM_CONFLICT.md)

**Problem**: SPM commands hung with "Another instance of SwiftPM is already running" when Xcode was open

**Investigation Findings**:
- Xcode's background indexing interferes with SPM
- SourceKitService and swift-frontend processes block SPM
- Different build systems (Xcode vs SPM) compete for resources

**Workarounds**:
1. Close Xcode before running `swift build`
2. Kill interfering processes: `killall -9 swift-frontend`
3. Use Xcode exclusively (works fine)

**Status**: Legitimate issue when mixing Xcode and SPM (not a bug)

#### Phase 3: Toolchain Switch Attempt (SWIFT_TOOLCHAIN_SWITCH.md)

**Hypothesis**: Switching to Swift 6.0.3 toolchain would fix debug builds

**Actions Taken**:
1. Installed Swift 6.0.3 toolchain
2. Set `TOOLCHAINS` environment variable
3. Verified with `swift --version`

**Result**: Debug builds still failed (same error)

**Conclusion**: Not a toolchain issue

#### Phase 4: Swift 6.2.0 Bug Investigation (SWIFT_6.2.0_BUG.md)

**Discovery**: Compiler bug in Swift 6.2 with dynamic member lookup

**Location**: `Select.swift:393-415`

**Workaround**: Conditional compilation guard

```swift
#if compiler(>=6.1) && compiler(<6.2)
// Workaround code
#endif
```

**Status**: Temporary workaround until Swift compiler fixed

**Note**: Later determined this was unrelated to main build issues

### Final Resolution (2025-10-12)

**Root Causes Identified**:
1. Hardcoded module references in TableMacro.swift
2. Duplicate library product for macro target
3. Missing SwiftCompilerPlugin dependency in test target

**Fixes Applied**:
- Fixed module references: `StructuredQueriesCore.QueryExpression` → `\(moduleName).QueryExpression`
- Removed duplicate `.library` product
- Added explicit SwiftCompilerPlugin dependency

**Result**: ✅ Both `swift build` and `swift test` now work with standard SPM

### Key Lessons Learned

1. **Package.swift configuration errors can masquerade as compiler bugs** - Always investigate configuration first
2. **Xcode/SPM interference is real but manageable** - Close Xcode or use exclusively
3. **Toolchain switches rarely fix configuration issues** - Focus on package structure
4. **Debug vs release build differences often indicate configuration problems** - Not compiler bugs
5. **Always verify with clean builds** - `rm -rf .build` before testing fixes

### Build System Documentation Trail

**Files Involved** (now consolidated into HISTORY.md):
- `SWIFT_BUILD_ISSUE.md` (744 lines) - Debug build investigation
- `XCODE_SPM_CONFLICT.md` (95 lines) - Xcode interference analysis
- `SWIFT_TOOLCHAIN_SWITCH.md` (109 lines) - Toolchain attempt
- `SWIFT_6.2.0_BUG.md` (85 lines) - Compiler bug documentation
- `TOOLCHAIN_SWITCH_STATUS.md` (199 lines) - Toolchain results
- `BUILD.md` (127 lines) - Build commands

**Total**: 1,359 lines consolidated into this historical entry

### Current Build Status

**Working Commands** (as of 2025-10-13):
```bash
swift build              # ✅ Works (all configurations)
swift test               # ✅ Works (all configurations)
swift build -c release   # ✅ Works (still recommended for performance)
swift test -c release    # ✅ Works (faster test execution)
```

**Xcode**: ✅ Works perfectly with debug builds (uses different build system)

**Documentation**: All build instructions updated across CLAUDE.md, README.md, TESTING.md, ARCHITECTURE.md

### Impact

- ✅ Standard SPM workflow restored
- ✅ Debug builds work (no release mode requirement)
- ✅ CI workflows simplified
- ✅ Documentation consolidated
- ✅ Clear understanding of Xcode/SPM interaction model

---

## Future Entries

When making significant changes, append new dated sections here following the same format.

**Do not edit previous sections** - the history is append-only.

---

**Last Updated**: 2025-10-13
