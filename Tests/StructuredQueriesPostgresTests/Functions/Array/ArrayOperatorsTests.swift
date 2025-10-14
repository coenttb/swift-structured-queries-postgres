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

        // Note: prependToArray needs type-specific overload for _PostgresArrayRepresentation
        // Skipping for now as it requires additional implementation
        // @Test func prependElement() async {
        //     await assertSQL(
        //         of: Post.select { prependToArray("featured", $0.tags) }
        //     ) {
        //             """
        //             SELECT ('featured' || "posts"."tags")
        //             FROM "posts"
        //             """
        //     }
        // }

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

        // Note: unnest functions need type-specific overloads for _PostgresArrayRepresentation
        // Skipping for now as they require additional implementation
        // @Test func unnest() async {
        //     // Note: unnest is a set-returning function, testing the syntax
        //     assertInlineSnapshot(
        //         of: Post.select { unnest($0.tags) },
        //         as: .sql
        //     ) {
        //         """
        //         SELECT unnest("posts"."tags")
        //         FROM "posts"
        //         """
        //     }
        // }

        // @Test func unnestMultiple() async {
        //     // Note: unnest with multiple arrays, testing the syntax
        //     assertInlineSnapshot(
        //         of: Post.select { unnestArrays($0.tags, $0.tags) },
        //         as: .sql
        //     ) {
        //         """
        //         SELECT unnest("posts"."tags", "posts"."tags")
        //         FROM "posts"
        //         """
        //     }
        // }
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
