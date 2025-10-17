import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests.PostgresArrayOps {
    @Suite("Array Operators") struct ArrayOperatorsTests {

        // MARK: - Containment Operators Tests

        @Test func containsArray() async {
            await assertSQL(
                of: Post.where { $0.tags.contains(["swift", "postgres"]) }
            ) {
                """
                SELECT "posts"."id", "posts"."title", "posts"."tags"
                FROM "posts"
                WHERE ("posts"."tags" @> ARRAY['swift', 'postgres'])
                """
            }
        }

        @Test func containsArrayExpression() async {
            await assertSQL(
                of: Post.where { $0.tags.contains($0.tags) }
            ) {
                """
                SELECT "posts"."id", "posts"."title", "posts"."tags"
                FROM "posts"
                WHERE ("posts"."tags" @> "posts"."tags")
                """
            }
        }

        @Test func isContainedBy() async {
            await assertSQL(
                of: Post.where { $0.tags.isContainedBy(["swift", "postgres", "server", "web"]) }
            ) {
                """
                SELECT "posts"."id", "posts"."title", "posts"."tags"
                FROM "posts"
                WHERE ("posts"."tags" <@ ARRAY['swift', 'postgres', 'server', 'web'])
                """
            }
        }

        @Test func isContainedByExpression() async {
            await assertSQL(
                of: Post.where { $0.tags.isContainedBy($0.tags) }
            ) {
                """
                SELECT "posts"."id", "posts"."title", "posts"."tags"
                FROM "posts"
                WHERE ("posts"."tags" <@ "posts"."tags")
                """
            }
        }

        @Test func overlaps() async {
            await assertSQL(
                of: Post.where { $0.tags.overlaps(["swift", "rust"]) }
            ) {
                """
                SELECT "posts"."id", "posts"."title", "posts"."tags"
                FROM "posts"
                WHERE ("posts"."tags" && ARRAY['swift', 'rust'])
                """
            }
        }

        @Test func overlapsExpression() async {
            await assertSQL(
                of: Post.where { $0.tags.overlaps($0.tags) }
            ) {
                """
                SELECT "posts"."id", "posts"."title", "posts"."tags"
                FROM "posts"
                WHERE ("posts"."tags" && "posts"."tags")
                """
            }
        }

        // MARK: - Array Concatenation Tests

        @Test func concatArrays() async {
            await assertSQL(
                of: Post.select { $0.tags.arrayConcat(["new-tag"]) }
            ) {
                """
                SELECT ("posts"."tags" || ARRAY['new-tag'])
                FROM "posts"
                """
            }
        }

        @Test func concatArrayExpressions() async {
            await assertSQL(
                of: Post.select { $0.tags.arrayConcat($0.tags) }
            ) {
                """
                SELECT ("posts"."tags" || "posts"."tags")
                FROM "posts"
                """
            }
        }

        @Test func concatElement() async {
            await assertSQL(
                of: Post.select { $0.tags.arrayConcat("new-tag") }
            ) {
                """
                SELECT ("posts"."tags" || 'new-tag')
                FROM "posts"
                """
            }
        }

        // MARK: - Array Equality & Comparison Tests

        @Test func arrayEquals() async {
            await assertSQL(
                of: Post.where { $0.tags.arrayEquals(["swift", "postgres"]) }
            ) {
                """
                SELECT "posts"."id", "posts"."title", "posts"."tags"
                FROM "posts"
                WHERE ("posts"."tags" = ARRAY['swift', 'postgres'])
                """
            }
        }

        @Test func arrayEqualsExpression() async {
            await assertSQL(
                of: Post.where { $0.tags.arrayEquals($0.tags) }
            ) {
                """
                SELECT "posts"."id", "posts"."title", "posts"."tags"
                FROM "posts"
                WHERE ("posts"."tags" = "posts"."tags")
                """
            }
        }

        @Test func arrayNotEquals() async {
            await assertSQL(
                of: Post.where { $0.tags.arrayNotEquals(["default"]) }
            ) {
                """
                SELECT "posts"."id", "posts"."title", "posts"."tags"
                FROM "posts"
                WHERE ("posts"."tags" <> ARRAY['default'])
                """
            }
        }

        @Test func arrayLessThan() async {
            await assertSQL(
                of: Post.where { $0.tags.arrayLessThan(["zzz"]) }
            ) {
                """
                SELECT "posts"."id", "posts"."title", "posts"."tags"
                FROM "posts"
                WHERE ("posts"."tags" < ARRAY['zzz'])
                """
            }
        }

        @Test func arrayGreaterThan() async {
            await assertSQL(
                of: Post.where { $0.tags.arrayGreaterThan(["aaa"]) }
            ) {
                """
                SELECT "posts"."id", "posts"."title", "posts"."tags"
                FROM "posts"
                WHERE ("posts"."tags" > ARRAY['aaa'])
                """
            }
        }

        // MARK: - Special Characters & SQL Injection Prevention Tests

        @Test("Array operators properly escape special characters")
        func specialCharactersEscaped() async {
            // Test that single quotes, backslashes, and other special characters are properly escaped
            await assertSQL(
                of: Post.where { $0.tags.contains(["it's", "\"quoted\"", "back\\slash"]) }
            ) {
                """
                SELECT "posts"."id", "posts"."title", "posts"."tags"
                FROM "posts"
                WHERE ("posts"."tags" @> ARRAY['it''s', '"quoted"', 'back\\slash'])
                """
            }
        }

        @Test("Array operators handle unicode correctly")
        func unicodeHandling() async {
            await assertSQL(
                of: Post.where { $0.tags.contains(["🚀", "日本語", "émoji"]) }
            ) {
                """
                SELECT "posts"."id", "posts"."title", "posts"."tags"
                FROM "posts"
                WHERE ("posts"."tags" @> ARRAY['🚀', '日本語', 'émoji'])
                """
            }
        }

        @Test("Unicode normalization: Combining characters")
        func unicodeCombiningCharacters() async {
            // é can be represented as:
            // - U+00E9 (single codepoint: LATIN SMALL LETTER E WITH ACUTE)
            // - U+0065 + U+0301 (combining: LATIN SMALL LETTER E + COMBINING ACUTE ACCENT)
            let precomposed = "café"  // Uses U+00E9
            let decomposed = "cafe\u{0301}"  // Uses U+0065 + U+0301

            await assertSQL(
                of: Post.where { $0.tags.contains([precomposed, decomposed]) }
            ) {
                """
                SELECT "posts"."id", "posts"."title", "posts"."tags"
                FROM "posts"
                WHERE ("posts"."tags" @> ARRAY['café', 'café'])
                """
            }
        }

        @Test("Unicode: Right-to-left text (Arabic)")
        func rightToLeftText() async {
            await assertSQL(
                of: Post.where { $0.tags.contains(["مرحبا", "العربية"]) }
            ) {
                """
                SELECT "posts"."id", "posts"."title", "posts"."tags"
                FROM "posts"
                WHERE ("posts"."tags" @> ARRAY['مرحبا', 'العربية'])
                """
            }
        }

        @Test("Unicode: Mixed scripts and emoji with skin tones")
        func mixedScriptsAndComplexEmoji() async {
            await assertSQL(
                of: Post.where { $0.tags.contains(["Hello世界", "👨‍👩‍👧‍👦", "🏳️‍🌈"]) }
            ) {
                """
                SELECT "posts"."id", "posts"."title", "posts"."tags"
                FROM "posts"
                WHERE ("posts"."tags" @> ARRAY['Hello世界', '👨‍👩‍👧‍👦', '🏳️‍🌈'])
                """
            }
        }

        @Test("Empty arrays are handled correctly")
        func emptyArrays() async {
            await assertSQL(
                of: Post.where { $0.tags.contains([]) }
            ) {
                """
                SELECT "posts"."id", "posts"."title", "posts"."tags"
                FROM "posts"
                WHERE ("posts"."tags" @> ARRAY[])
                """
            }
        }

        // MARK: - Real-World Use Cases

        @Test("Find posts with required tags (AND logic)")
        func findPostsWithAllRequiredTags() async {
            // Real-world: Find posts that have ALL of these tags
            await assertSQL(
                of: Post.where { $0.tags.contains(["swift", "tutorial", "beginner"]) }
            ) {
                """
                SELECT "posts"."id", "posts"."title", "posts"."tags"
                FROM "posts"
                WHERE ("posts"."tags" @> ARRAY['swift', 'tutorial', 'beginner'])
                """
            }
        }

        @Test("Find posts with any matching tag (OR logic)")
        func findPostsWithAnyMatchingTag() async {
            // Real-world: Find posts that have ANY of these tags
            await assertSQL(
                of: Post.where { $0.tags.overlaps(["swift", "rust", "go"]) }
            ) {
                """
                SELECT "posts"."id", "posts"."title", "posts"."tags"
                FROM "posts"
                WHERE ("posts"."tags" && ARRAY['swift', 'rust', 'go'])
                """
            }
        }

        @Test("Find posts tagged as subset of allowed tags")
        func findPostsOnlyWithAllowedTags() async {
            // Real-world: Ensure post tags are only from approved list
            await assertSQL(
                of: Post.where {
                    $0.tags.isContainedBy(["swift", "postgres", "vapor", "server"])
                }
            ) {
                """
                SELECT "posts"."id", "posts"."title", "posts"."tags"
                FROM "posts"
                WHERE ("posts"."tags" <@ ARRAY['swift', 'postgres', 'vapor', 'server'])
                """
            }
        }

        @Test("Add tag to existing tags")
        func addTagToPost() async {
            // Real-world: Add a new tag to a post's existing tags
            await assertSQL(
                of: Post.select { $0.tags.arrayConcat("featured") }
            ) {
                """
                SELECT ("posts"."tags" || 'featured')
                FROM "posts"
                """
            }
        }

        @Test("Merge two tag arrays")
        func mergeTags() async {
            // Real-world: Combine tags from two different sources
            await assertSQL(
                of: Post.select { $0.tags.arrayConcat(["archived", "reviewed"]) }
            ) {
                """
                SELECT ("posts"."tags" || ARRAY['archived', 'reviewed'])
                FROM "posts"
                """
            }
        }

        @Test("Filter posts not tagged with default tags")
        func filterNonDefaultPosts() async {
            // Real-world: Find posts that have custom tags (not the defaults)
            await assertSQL(
                of: Post.where { $0.tags.arrayNotEquals(["uncategorized"]) }
            ) {
                """
                SELECT "posts"."id", "posts"."title", "posts"."tags"
                FROM "posts"
                WHERE ("posts"."tags" <> ARRAY['uncategorized'])
                """
            }
        }

        @Test("Compare tags alphabetically")
        func compareTagsAlphabetically() async {
            // Real-world: Lexicographic comparison (useful for sorting or filtering)
            await assertSQL(
                of: Post.where { $0.tags.arrayLessThan(["zzz"]) }
            ) {
                """
                SELECT "posts"."id", "posts"."title", "posts"."tags"
                FROM "posts"
                WHERE ("posts"."tags" < ARRAY['zzz'])
                """
            }
        }

        // MARK: - Array Query Functions Tests

        @Test func arrayLength() async {
            await assertSQL(
                of: Post.where { ($0.tags.arrayLength() ?? 0) > 3 }
            ) {
                """
                SELECT "posts"."id", "posts"."title", "posts"."tags"
                FROM "posts"
                WHERE (coalesce(array_length("posts"."tags", 1), 0)) > (3)
                """
            }
        }

        @Test func cardinality() async {
            await assertSQL(
                of: Post.where { ($0.tags.cardinality() ?? 0) > 0 }
            ) {
                """
                SELECT "posts"."id", "posts"."title", "posts"."tags"
                FROM "posts"
                WHERE (coalesce(cardinality("posts"."tags"), 0)) > (0)
                """
            }
        }

        @Test func arrayPosition() async {
            await assertSQL(
                of: Post.select { $0.tags.arrayPosition("swift") }
            ) {
                """
                SELECT array_position("posts"."tags", 'swift')
                FROM "posts"
                """
            }
        }

        @Test func arrayPositionWithStart() async {
            await assertSQL(
                of: Post.select { $0.tags.arrayPosition("swift", startingFrom: 2) }
            ) {
                """
                SELECT array_position("posts"."tags", 'swift', 2)
                FROM "posts"
                """
            }
        }

        @Test func arrayPositions() async {
            await assertSQL(
                of: Post.select { $0.tags.arrayPositions("swift") }
            ) {
                """
                SELECT array_positions("posts"."tags", 'swift')
                FROM "posts"
                """
            }
        }

        @Test func arrayLower() async {
            await assertSQL(
                of: Post.select { $0.tags.arrayLower() }
            ) {
                """
                SELECT array_lower("posts"."tags", 1)
                FROM "posts"
                """
            }
        }

        @Test func arrayUpper() async {
            await assertSQL(
                of: Post.select { $0.tags.arrayUpper() }
            ) {
                """
                SELECT array_upper("posts"."tags", 1)
                FROM "posts"
                """
            }
        }

        @Test func arrayNdims() async {
            await assertSQL(
                of: Post.select { $0.tags.arrayNdims() }
            ) {
                """
                SELECT array_ndims("posts"."tags")
                FROM "posts"
                """
            }
        }

        // MARK: - Complex Real-World Queries

        @Test("Posts with at least 3 tags including 'swift'")
        func complexTagFiltering() async {
            // Real-world: Find well-tagged Swift posts
            await assertSQL(
                of: Post.where {
                    ($0.tags.cardinality() ?? 0) >= 3 && $0.tags.contains(["swift"])
                }
            ) {
                """
                SELECT "posts"."id", "posts"."title", "posts"."tags"
                FROM "posts"
                WHERE ((coalesce(cardinality("posts"."tags"), 0)) >= (3)) AND ("posts"."tags" @> ARRAY['swift'])
                """
            }
        }

        @Test("Posts with overlapping interests but not exactly matching")
        func similarButNotIdentical() async {
            // Real-world: Recommendation system - similar tags but not identical posts
            await assertSQL(
                of: Post.where {
                    $0.tags.overlaps(["swift", "vapor"]) && !$0.tags.arrayEquals(["swift", "vapor"])
                }
            ) {
                """
                SELECT "posts"."id", "posts"."title", "posts"."tags"
                FROM "posts"
                WHERE (("posts"."tags" && ARRAY['swift', 'vapor'])) AND (NOT (("posts"."tags" = ARRAY['swift', 'vapor'])))
                """
            }
        }
    }
}

// MARK: - Test Model

@Table
private struct Post {
    let id: Int
    let title: String
    @Column(as: [String].self)
    let tags: [String]
}

// MARK: - SnapshotTests.PostgresArrayOps Namespace

extension SnapshotTests {
    enum PostgresArrayOps {}
}
