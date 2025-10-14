import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests.StringFunctions {
    @Suite("String Functions") struct StringFunctionsTests {

        // MARK: - String Concatenation Test

        @Test func concat() async {
            await assertSQL(
                of: Person.select {
                    ($0.firstName + " " + $0.lastName)
                }
            ) {
                """
                SELECT (("persons"."firstName") || (' ')) || ("persons"."lastName")
                FROM "persons"
                """
            }
        }

        // MARK: - Case Conversion Tests

        @Test func upper() async {
            await assertSQL(
                of: Person.select { $0.name.upper() }
            ) {
                """
                SELECT upper("persons"."name")
                FROM "persons"
                """
            }
        }

        @Test func lower() async {
            await assertSQL(
                of: Person.select { $0.email.lower() }
            ) {
                """
                SELECT lower("persons"."email")
                FROM "persons"
                """
            }
        }

        // MARK: - Trimming Test

        @Test func trim() async {
            await assertSQL(
                of: Person.select { $0.description.trim() }
            ) {
                """
                SELECT trim("persons"."description")
                FROM "persons"
                """
            }
        }

        // MARK: - Substring Test

        @Test func substring() async {
            await assertSQL(
                of: Person.select { $0.name.substr(1, 10) }
            ) {
                """
                SELECT substr("persons"."name", 1, 10)
                FROM "persons"
                """
            }
        }
    }
}

// MARK: - Test Model

@Table
private struct Person {
    let id: Int
    let name: String
    let email: String
    let firstName: String
    let lastName: String
    let description: String
}

// MARK: - SnapshotTests.StringFunctions Namespace

extension SnapshotTests {
    enum StringFunctions {}
}
