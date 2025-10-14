import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

// MARK: - Compiler Bug Canary Tests
//
// These tests detect when Swift compiler bugs related to `any` vs `some` are fixed.
//
// **HOW TO TEST FOR BUG FIXES:**
//
// Periodically (e.g., with new Swift releases), perform these steps:
//
// 1. **Make the code changes documented in each test below**
// 2. **Enable the test suite** by changing `.disabled()` to `.enabled()`
// 3. **Run tests** - if they PASS, the bug is fixed! Keep the changes.
// 4. **If tests fail**, revert changes - bug still exists
//
// **BUGS TRACKED:**
// - Swift compiler bug: Updates[dynamicMember:] with opaque types causes incorrect overload resolution
//   When accessing columns via Updates subscript (in UPDATE closures), using `some` instead of `any`
//   causes compilation failures or generates incorrect SQL.
//
// **WORKAROUND LOCATIONS:**
// - Operators+Logical.swift:71 - `prefix func !` accepting `any QueryExpression<Bool>`
// - Operators+Comparison.swift:164-251 - Comparison operators accepting `any` on left side
// - Updates.swift:28 - Subscript returning `any QueryExpression<Value>`

extension SnapshotTests {
    @Suite(
        .disabled(
            "Compiler bug: Updates[dynamicMember:] with opaque types"
        )
    )
    struct CompilerBugCanaryTests {

        // MARK: - Test 1: Logical NOT operator with Updates

        /// Tests if `prefix func !` can use `some` instead of `any`
        ///
        /// **BEFORE TESTING:**
        /// Change Operators+Logical.swift:71 from:
        /// ```swift
        /// public prefix func ! (expression: any QueryExpression<Bool>)
        /// ```
        /// to:
        /// ```swift
        /// public prefix func ! (expression: some QueryExpression<Bool>)
        /// ```
        /// And simplify the function body to just: `SQLQueryExpression(expression.not())`
        ///
        /// **Current behavior:** Compilation fails with "Getter for 'subscript(dynamicMember:)' is unavailable"
        /// **Expected when fixed:** Test compiles and passes
        @Test func logicalNotWithUpdates() {
            assertInlineSnapshot(
                of: Reminder.update {
                    $0.isCompleted = !$0.isCompleted
                },
                as: .sql
            ) {
                """
                UPDATE "reminders"
                SET "isCompleted" = NOT ("reminders"."isCompleted")
                """
            }
        }

        // MARK: - Test 2: Comparison operators with Updates

        /// Tests if comparison operators can use `some` instead of `any` on left side
        ///
        /// **BEFORE TESTING:**
        /// Change Operators+Comparison.swift:164, 174, 184, 194, 203, 212, 221, 230, 240, 248 from:
        /// ```swift
        /// lhs: any QueryExpression<...>
        /// ```
        /// to:
        /// ```swift
        /// lhs: some QueryExpression<...>
        /// ```
        /// (All comparison operator overloads that accept `any` on left side)
        ///
        /// **Current behavior:** Generates incorrect SQL: `CASE WHEN false THEN ...`
        /// **Expected when fixed:** Generates correct SQL with proper NULL comparison
        @Test func comparisonWithUpdatesAndNil() {
            assertInlineSnapshot(
                of:
                    Reminder
                    .find(1)
                    .update {
                        $0.dueDate = Case()
                            .when($0.dueDate == nil, then: #sql("'2018-01-29 00:08:00.000'"))
                    }
                    .returning(\.dueDate),
                as: .sql
            ) {
                """
                UPDATE "reminders"
                SET "dueDate" = CASE WHEN ("reminders"."dueDate") IS NOT DISTINCT FROM (NULL) THEN '2018-01-29 00:08:00.000' END
                WHERE ("reminders"."id") IN ((1))
                RETURNING "dueDate"
                """
            }
        }

        // MARK: - Test 3: Updates subscript returning some

        /// Tests if Updates subscript can return `some` instead of `any`
        ///
        /// **BEFORE TESTING:**
        /// Change Updates.swift:28 from:
        /// ```swift
        /// ) -> any QueryExpression<Value> {
        /// ```
        /// to:
        /// ```swift
        /// ) -> some QueryExpression<Value> {
        /// ```
        ///
        /// **Current behavior:** Assignment fails with type mismatch errors in tests
        /// **Expected when fixed:** Test compiles and passes
        @Test func updatesSubscriptWithSome() {
            assertInlineSnapshot(
                of: Reminder.update {
                    $0.title = "Test"
                    $0.isCompleted = true
                },
                as: .sql
            ) {
                """
                UPDATE "reminders"
                SET "title" = 'Test', "isCompleted" = true
                """
            }
        }

        // MARK: - Instructions for Future Maintainers

        /// **WHEN TESTS PASS:**
        /// 1. Remove workarounds in the files mentioned above
        /// 2. Change `any` to `some` in those locations
        /// 3. Move these tests to regular test suite (remove `#if false`)
        /// 4. Update documentation to reflect the fix
        ///
        /// **FILES TO UPDATE:**
        /// - Sources/StructuredQueriesCore/Operators/Operators+Logical.swift
        /// - Sources/StructuredQueriesCore/Operators/Operators+Comparison.swift
        /// - Sources/StructuredQueriesCore/Core/Updates.swift
    }
}
