import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests.PostgresArrayOps {
    @Suite("Array Manipulation") struct ArrayManipulationTests {

        // MARK: - .joined() Disambiguation Test

        @Test("Swift stdlib .joined() vs SQL .joined() - disambiguation")
        func joinedDisambiguation() async {
            // This test demonstrates that both .joined() methods coexist peacefully:
            // 1. Swift's stdlib .joined() for regular Swift arrays (preferred via @_disfavoredOverload)
            // 2. SQL's .joined() for QueryExpression types (PostgreSQL's array_to_string)

            // Swift stdlib .joined() - used for building SQL strings
            let tagNames = ["swift", "postgres", "server"]
            let swiftJoined = tagNames.joined(separator: ", ")  // Calls Swift.Sequence.joined()
            #expect(swiftJoined == "swift, postgres, server")

            // SQL .joined() - generates PostgreSQL's array_to_string() in query
            await assertSQL(
                of: Post.select { $0.tags.joined(separator: ", ") }  // Calls QueryExpression.joined()
            ) {
                """
                SELECT array_to_string("posts"."tags", ', ')
                FROM "posts"
                """
            }
        }

        // MARK: - Array Manipulation Functions

        @Test func removing() async {
            await assertSQL(
                of: Post.select { $0.tags.removing("deprecated") }
            ) {
                """
                SELECT array_remove("posts"."tags", 'deprecated')
                FROM "posts"
                """
            }
        }

        @Test func replacing() async {
            await assertSQL(
                of: Post.select { $0.tags.replacing("old-tag", with: "new-tag") }
            ) {
                """
                SELECT array_replace("posts"."tags", 'old-tag', 'new-tag')
                FROM "posts"
                """
            }
        }

        @Test func joinedWithNullReplacement() async {
            await assertSQL(
                of: Post.select { $0.tags.joined(separator: ", ", nullReplacement: "[none]") }
            ) {
                """
                SELECT array_to_string("posts"."tags", ', ', '[none]')
                FROM "posts"
                """
            }
        }

        @Test func dimensions() async {
            await assertSQL(
                of: Post.select { $0.tags.dimensions }
            ) {
                """
                SELECT array_dims("posts"."tags")
                FROM "posts"
                """
            }
        }

        @Test func toJSON() async {
            await assertSQL(
                of: Post.select { $0.tags.toJSON() }
            ) {
                """
                SELECT array_to_json("posts"."tags")
                FROM "posts"
                """
            }
        }

        @Test func toJSONPrettyPrint() async {
            await assertSQL(
                of: Post.select { $0.tags.toJSON(prettyPrint: true) }
            ) {
                """
                SELECT array_to_json("posts"."tags", true)
                FROM "posts"
                """
            }
        }

        // MARK: - String to Array Conversion

        @Test func split() async {
            await assertSQL(
                of: Account.select { $0.commaSeparatedTags.split(separator: ",") }
            ) {
                """
                SELECT string_to_array("accounts"."commaSeparatedTags", ',')
                FROM "accounts"
                """
            }
        }

        @Test func splitWithNullString() async {
            await assertSQL(
                of: Account.select { $0.commaSeparatedTags.split(separator: ",", nullString: "NULL") }
            ) {
                """
                SELECT string_to_array("accounts"."commaSeparatedTags", ',', 'NULL')
                FROM "accounts"
                """
            }
        }

        // MARK: - Array Construction

        @Test func appending() async {
            await assertSQL(
                of: Post.select { $0.tags.appending("swift") }
            ) {
                """
                SELECT array_append("posts"."tags", 'swift')
                FROM "posts"
                """
            }
        }

        @Test func prepending() async {
            await assertSQL(
                of: Post.select { $0.tags.prepending("featured") }
            ) {
                """
                SELECT array_prepend('featured', "posts"."tags")
                FROM "posts"
                """
            }
        }

        @Test func concatenatingArray() async {
            await assertSQL(
                of: Post.select { $0.tags.concatenating(["archived", "reviewed"]) }
            ) {
                """
                SELECT array_cat("posts"."tags", ARRAY['archived', 'reviewed'])
                FROM "posts"
                """
            }
        }

        // MARK: - Special Characters & SQL Injection Prevention

        @Test("Properly escapes special characters in array manipulation")
        func specialCharactersEscaped() async {
            await assertSQL(
                of: Post.select { $0.tags.appending("it's \"quoted\"") }
            ) {
                """
                SELECT array_append("posts"."tags", 'it''s "quoted"')
                FROM "posts"
                """
            }
        }

        // MARK: - Real-World Use Cases

        @Test("Display tags as comma-separated string")
        func displayTagsAsString() async {
            // Real-world: Convert array column to user-friendly display string
            await assertSQL(
                of: Post.select { ($0.title, $0.tags.joined(separator: ", ")) }
            ) {
                """
                SELECT "posts"."title", array_to_string("posts"."tags", ', ')
                FROM "posts"
                """
            }
        }

        @Test("Remove deprecated tag from all posts")
        func removeDeprecatedTag() async {
            // Real-world: Cleanup operation - remove a specific tag
            await assertSQL(
                of: Post.update { $0.tags = $0.tags.removing("deprecated") }
            ) {
                """
                UPDATE "posts"
                SET "tags" = array_remove("posts"."tags", 'deprecated')
                """
            }
        }

        @Test("Rename tag across all posts")
        func renameTag() async {
            // Real-world: Tag migration - rename old tag to new tag
            await assertSQL(
                of: Post.update { $0.tags = $0.tags.replacing("old-name", with: "new-name") }
            ) {
                """
                UPDATE "posts"
                SET "tags" = array_replace("posts"."tags", 'old-name', 'new-name')
                """
            }
        }

        @Test("Parse CSV string into array column")
        func parseCSV() async {
            // Real-world: Import CSV data into array column
            await assertSQL(
                of: Account.update { $0.tags = $0.commaSeparatedTags.split(separator: ",") }
            ) {
                """
                UPDATE "accounts"
                SET "tags" = string_to_array("accounts"."commaSeparatedTags", ',')
                """
            }
        }

        @Test("Export array as JSON for API response")
        func exportAsJSON() async {
            // Real-world: API endpoint returning tags as JSON array
            await assertSQL(
                of: Post.select { ($0.id, $0.tags.toJSON()) }
            ) {
                """
                SELECT "posts"."id", array_to_json("posts"."tags")
                FROM "posts"
                """
            }
        }
    }
}

// MARK: - Test Models

@Table
private struct Post {
    let id: Int
    let title: String
    @Column(as: [String].self)
    let tags: [String]
}

@Table("accounts")
private struct Account {
    let id: Int
    let commaSeparatedTags: String
    @Column(as: [String].self)
    let tags: [String]
}
