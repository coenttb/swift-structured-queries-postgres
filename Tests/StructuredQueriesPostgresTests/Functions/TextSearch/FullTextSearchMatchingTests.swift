import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests.FullTextSearch {
    @Suite("Matching") struct MatchingTests {

        // MARK: - Match Operations

        @Test("Basic match with tsquery")
        func basicMatch() async {
            await assertSQL(
                of: Article.where { $0.match("swift & postgresql") }
            ) {
                """
                SELECT "articles"."id", "articles"."title", "articles"."body", "articles"."searchVector"
                FROM "articles"
                WHERE "articles"."searchVector" @@ to_tsquery('english'::regconfig, 'swift & postgresql')
                """
            }
        }

        @Test("Match with custom language")
        func matchCustomLanguage() async {
            await assertSQL(
                of: Article.where { $0.match("rapide & base", language: "french") }
            ) {
                """
                SELECT "articles"."id", "articles"."title", "articles"."body", "articles"."searchVector"
                FROM "articles"
                WHERE "articles"."searchVector" @@ to_tsquery('french'::regconfig, 'rapide & base')
                """
            }
        }

        @Test("Match with OR operator")
        func matchOr() async {
            await assertSQL(
                of: Article.where { $0.match("swift | rust | go") }
            ) {
                """
                SELECT "articles"."id", "articles"."title", "articles"."body", "articles"."searchVector"
                FROM "articles"
                WHERE "articles"."searchVector" @@ to_tsquery('english'::regconfig, 'swift | rust | go')
                """
            }
        }

        @Test("Match with NOT operator")
        func matchNot() async {
            await assertSQL(
                of: Article.where { $0.match("swift & !objective") }
            ) {
                """
                SELECT "articles"."id", "articles"."title", "articles"."body", "articles"."searchVector"
                FROM "articles"
                WHERE "articles"."searchVector" @@ to_tsquery('english'::regconfig, 'swift & !objective')
                """
            }
        }

        @Test("Match with phrase operator")
        func matchPhrase() async {
            await assertSQL(
                of: Article.where { $0.match("quick <-> brown <-> fox") }
            ) {
                """
                SELECT "articles"."id", "articles"."title", "articles"."body", "articles"."searchVector"
                FROM "articles"
                WHERE "articles"."searchVector" @@ to_tsquery('english'::regconfig, 'quick <-> brown <-> fox')
                """
            }
        }

        @Test("Plain text match")
        func plainMatch() async {
            await assertSQL(
                of: Article.where { $0.plainMatch("swift postgresql database") }
            ) {
                """
                SELECT "articles"."id", "articles"."title", "articles"."body", "articles"."searchVector"
                FROM "articles"
                WHERE "articles"."searchVector" @@ plainto_tsquery('english'::regconfig, 'swift postgresql database')
                """
            }
        }

        @Test("Web search match")
        func webMatch() async {
            await assertSQL(
                of: Article.where { $0.webMatch(#""swift postgresql" -objective"#) }
            ) {
                """
                SELECT "articles"."id", "articles"."title", "articles"."body", "articles"."searchVector"
                FROM "articles"
                WHERE "articles"."searchVector" @@ websearch_to_tsquery('english'::regconfig, '"swift postgresql" -objective')
                """
            }
        }

        @Test("Default search vector column name")
        func defaultColumnName() async {
            await assertSQL(
                of: FTSBlogPost.where { $0.match("content") }
            ) {
                """
                SELECT "blogPosts"."id", "blogPosts"."content", "blogPosts"."searchVector"
                FROM "blogPosts"
                WHERE "blogPosts"."searchVector" @@ to_tsquery('english'::regconfig, 'content')
                """
            }
        }

        @Test("Match text column directly")
        func matchTextColumn() async {
            await assertSQL(
                of: Article.where { $0.title.match("swift") }
            ) {
                """
                SELECT "articles"."id", "articles"."title", "articles"."body", "articles"."searchVector"
                FROM "articles"
                WHERE to_tsvector('english'::regconfig, "articles"."title") @@ to_tsquery('english'::regconfig, 'swift')
                """
            }
        }

        @Test("Match text column with language")
        func matchTextColumnLanguage() async {
            await assertSQL(
                of: Article.where { $0.body.match("database", language: "simple") }
            ) {
                """
                SELECT "articles"."id", "articles"."title", "articles"."body", "articles"."searchVector"
                FROM "articles"
                WHERE to_tsvector('simple'::regconfig, "articles"."body") @@ to_tsquery('simple'::regconfig, 'database')
                """
            }
        }
    }
}
