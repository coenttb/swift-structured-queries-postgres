import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

/// Tests for Full-Text Search examples shown in README.md
@Suite("README Examples - Full-Text Search")
struct FullTextSearchExamplesTests {

    // MARK: - Basic Text Search on String Columns
    @Table
    struct Article: FullTextSearchable {
        let id: Int
        var title: String
        var content: String
    }
    
    @Test("README Example: Basic search on text column")
    func basicTextSearch() async {
        

        await assertSQL(
            of: Article.where { $0.content.match("postgresql") }
        ) {
            """
            SELECT "articles"."id", "articles"."title", "articles"."content"
            FROM "articles"
            WHERE to_tsvector('english'::regconfig, "articles"."content") @@ to_tsquery('english'::regconfig, 'postgresql')
            """
        }
    }

    @Test("README Example: Search with AND operator")
    func searchWithAnd() async {
        await assertSQL(
            of: Article.where { $0.content.match("postgresql & query") }
        ) {
            """
            SELECT "articles"."id", "articles"."title", "articles"."content"
            FROM "articles"
            WHERE to_tsvector('english'::regconfig, "articles"."content") @@ to_tsquery('english'::regconfig, 'postgresql & query')
            """
        }
    }

    @Test("README Example: Search with OR operator")
    func searchWithOr() async {
        await assertSQL(
            of: Article.where { $0.content.match("postgresql | mysql") }
        ) {
            """
            SELECT "articles"."id", "articles"."title", "articles"."content"
            FROM "articles"
            WHERE to_tsvector('english'::regconfig, "articles"."content") @@ to_tsquery('english'::regconfig, 'postgresql | mysql')
            """
        }
    }

    // MARK: - Search with Ranking (Using Dedicated FTS Table)

    @Test("README Example: Search with ranking")
    func searchWithRanking() async {
        let query = "swift"

        await assertSQL(
            of: Article
                .where { $0.match(query) }
                .select { ($0.title, $0.rank(by: query)) }
        ) {
            """
            SELECT "articles"."title", ts_rank("articles"."searchVector", to_tsquery('english'::regconfig, 'swift'))
            FROM "articles"
            WHERE "articles"."searchVector" @@ to_tsquery('english'::regconfig, 'swift')
            """
        }
    }

    @Test("README Example: Search with ranking and ordering")
    func searchWithRankingOrdered() async {
        let query = "swift"

        await assertSQL(
            of: Article
                .where { $0.match(query) }
                .select { ($0.title, $0.rank(by: query)) }
                .order { $0.rank(by: query).desc() }
                .limit(10)
        ) {
            """
            SELECT "articles"."title", ts_rank("articles"."searchVector", to_tsquery('english'::regconfig, 'swift'))
            FROM "articles"
            WHERE "articles"."searchVector" @@ to_tsquery('english'::regconfig, 'swift')
            ORDER BY ts_rank("articles"."searchVector", to_tsquery('english'::regconfig, 'swift')) DESC
            LIMIT 10
            """
        }
    }
}
