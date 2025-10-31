import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests.FullTextSearch {
  @Suite("Functions") struct FunctionsTests {

    // MARK: - Column-Level Functions

    @Test("Convert text to tsvector")
    func searchVector() async {
      await assertSQL(of: Article.select { $0.title.searchVector() }) {
        """
        SELECT to_tsvector('english'::regconfig, "articles"."title")
        FROM "articles"
        """
      }
    }

    @Test("Convert text to tsvector with language")
    func toTsvectorLanguage() async {
      await assertSQL(of: Article.select { $0.body.searchVector("spanish") }) {
        """
        SELECT to_tsvector('spanish'::regconfig, "articles"."body")
        FROM "articles"
        """
      }
    }

    @Test("Headline with default delimiters")
    func headlineDefault() async {
      await assertSQL(
        of:
          Article
          .where { $0.match("swift") }
          .select { $0.title.headline(matching: "swift") }
      ) {
        """
        SELECT ts_headline('english'::regconfig, "articles"."title", to_tsquery('english'::regconfig, 'swift'), 'StartSel=<b>, StopSel=</b>')
        FROM "articles"
        WHERE "articles"."searchVector" @@ to_tsquery('english'::regconfig, 'swift')
        """
      }
    }

    @Test("Headline with custom delimiters")
    func headlineCustomDelimiters() async {
      await assertSQL(
        of:
          Article
          .where {
            $0.match("swift")
          }
          .select {
            $0.title.headline(
              matching: "swift",
              startDelimiter: "<mark>",
              stopDelimiter: "</mark>"
            )
          }
      ) {
        """
        SELECT ts_headline('english'::regconfig, "articles"."title", to_tsquery('english'::regconfig, 'swift'), 'StartSel=<mark>, StopSel=</mark>')
        FROM "articles"
        WHERE "articles"."searchVector" @@ to_tsquery('english'::regconfig, 'swift')
        """
      }
    }

    @Test("Headline with word limits")
    func headlineWordLimits() async {
      await assertSQL(
        of:
          Article
          .where {
            $0.match("swift")
          }
          .select {
            $0.body.headline(
              matching: "swift",
              wordRange: .init(
                min: 20,
                max: 50
              )
            )
          }
      ) {
        """
        SELECT ts_headline('english'::regconfig, "articles"."body", to_tsquery('english'::regconfig, 'swift'), 'StartSel=<b>, StopSel=</b>, MinWords=20, MaxWords=50')
        FROM "articles"
        WHERE "articles"."searchVector" @@ to_tsquery('english'::regconfig, 'swift')
        """
      }
    }

    @Test("Headline with all options")
    func headlineAllOptions() async {
      await assertSQL(
        of:
          Article
          .where {
            $0.match("swift postgresql")
          }
          .select {
            $0.body.headline(
              matching:
                "swift postgresql",
              startDelimiter: "**",
              stopDelimiter: "**",
              wordRange: .init(min: 30, max: 100),
              shortWord: 2,
              maxFragments: 3
            )
          }
      ) {
        """
        SELECT ts_headline('english'::regconfig, "articles"."body", to_tsquery('english'::regconfig, 'swift postgresql'), 'StartSel=**, StopSel=**, MinWords=30, MaxWords=100, ShortWord=2, MaxFragments=3')
        FROM "articles"
        WHERE "articles"."searchVector" @@ to_tsquery('english'::regconfig, 'swift postgresql')
        """
      }
    }

    // MARK: - Complex Queries

    @Test("Search with pagination and ranking")
    func complexSearchQuery() async {
      await assertSQL(
        of:
          Article
          .where { $0.match("swift & postgresql") }
          .select { ($0.id, $0.title, $0.rank(by: "swift & postgresql")) }
          .limit(10, offset: 20)
      ) {
        """
        SELECT "articles"."id", "articles"."title", ts_rank("articles"."searchVector", to_tsquery('english'::regconfig, 'swift & postgresql'))
        FROM "articles"
        WHERE "articles"."searchVector" @@ to_tsquery('english'::regconfig, 'swift & postgresql')
        LIMIT 10 OFFSET 20
        """
      }
    }

    @Test("Search with headline and ranking")
    func searchWithHeadlineAndRank() async {
      await assertSQL(
        of:
          Article
          .where {
            $0.match("swift")
          }
          .select {
            (
              $0.id,
              $0.title.headline(
                matching: "swift",
                startDelimiter: "<mark>",
                stopDelimiter: "</mark>"
              ),
              $0.body.headline(
                matching: "swift",
                wordRange: .init(min: 0, max: 50)
              ),
              $0.rank(by: "swift")
            )
          }
      ) {
        """
        SELECT "articles"."id", ts_headline('english'::regconfig, "articles"."title", to_tsquery('english'::regconfig, 'swift'), 'StartSel=<mark>, StopSel=</mark>'), ts_headline('english'::regconfig, "articles"."body", to_tsquery('english'::regconfig, 'swift'), 'StartSel=<b>, StopSel=</b>'), ts_rank("articles"."searchVector", to_tsquery('english'::regconfig, 'swift'))
        FROM "articles"
        WHERE "articles"."searchVector" @@ to_tsquery('english'::regconfig, 'swift')
        """
      }
    }

    @Test("Multi-language search")
    func multiLanguageSearch() async {
      await assertSQL(
        of:
          Article
          .where { $0.match("développement", language: "french") }
          .select { ($0.id, $0.rank(by: "développement", language: "french")) }
      ) {
        """
        SELECT "articles"."id", ts_rank("articles"."searchVector", to_tsquery('french'::regconfig, 'développement'))
        FROM "articles"
        WHERE "articles"."searchVector" @@ to_tsquery('french'::regconfig, 'développement')
        """
      }
    }

    @Test("Combine FTS with other filters")
    func ftsWithFilters() async {
      await assertSQL(
        of:
          Article
          .where { $0.match("swift") && $0.id > 100 }
          .select { ($0.id, $0.title, $0.rank(by: "swift")) }
      ) {
        """
        SELECT "articles"."id", "articles"."title", ts_rank("articles"."searchVector", to_tsquery('english'::regconfig, 'swift'))
        FROM "articles"
        WHERE ("articles"."searchVector" @@ to_tsquery('english'::regconfig, 'swift')) AND ("articles"."id") > (100)
        """
      }
    }

    @Test("Count search results")
    func searchResultsCount() async {
      await assertSQL(
        of:
          Article
          .where { $0.match("swift & postgresql") }
          .select { _ in .count() }
      ) {
        """
        SELECT count(*)
        FROM "articles"
        WHERE "articles"."searchVector" @@ to_tsquery('english'::regconfig, 'swift & postgresql')
        """
      }
    }
  }
}
