import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests.FullTextSearch {
  @Suite("Vectors & Edge Cases") struct VectorsTests {

    // MARK: - Phrase Match Tests

    @Test("Phrase match basic")
    func phraseMatchBasic() async {
      await assertSQL(of: Article.where { $0.phraseMatch("quick brown fox") }) {
        """
        SELECT "articles"."id", "articles"."title", "articles"."body", "articles"."searchVector"
        FROM "articles"
        WHERE "articles"."searchVector" @@ phraseto_tsquery('english'::regconfig, 'quick brown fox')
        """
      }
    }

    @Test("Phrase match with custom language")
    func phraseMatchLanguage() async {
      await assertSQL(
        of: Article.where { $0.phraseMatch("le chat noir", language: "french") }
      ) {
        """
        SELECT "articles"."id", "articles"."title", "articles"."body", "articles"."searchVector"
        FROM "articles"
        WHERE "articles"."searchVector" @@ phraseto_tsquery('french'::regconfig, 'le chat noir')
        """
      }
    }

    @Test("Phrase match with ranking")
    func phraseMatchWithRank() async {
      await assertSQL(
        of:
          Article
          .where { $0.phraseMatch("swift programming") }
          .select { ($0.id, $0.title, $0.rank(by: "swift & programming")) }
      ) {
        """
        SELECT "articles"."id", "articles"."title", ts_rank("articles"."searchVector", to_tsquery('english'::regconfig, 'swift & programming'))
        FROM "articles"
        WHERE "articles"."searchVector" @@ phraseto_tsquery('english'::regconfig, 'swift programming')
        """
      }
    }

    @Test("Phrase match combined with filters")
    func phraseMatchWithFilters() async {
      await assertSQL(
        of:
          Article
          .where { $0.phraseMatch("server side swift") && $0.id < 1000 }
          .select { ($0.id, $0.title) }
      ) {
        """
        SELECT "articles"."id", "articles"."title"
        FROM "articles"
        WHERE ("articles"."searchVector" @@ phraseto_tsquery('english'::regconfig, 'server side swift')) AND ("articles"."id") < (1000)
        """
      }
    }

    // MARK: - Vector Manipulation Tests

    @Test("Setweight on tsvector column")
    func setweightColumn() async {
      await assertSQL(of: Article.select { $0.title.searchVector().weighted(.A) }) {
        """
        SELECT setweight(to_tsvector('english'::regconfig, "articles"."title"), 'A')
        FROM "articles"
        """
      }
    }

    @Test("Setweight with different weights")
    func setweightVariousWeights() async {
      await assertSQL(
        of: Article.select {
          (
            $0.title.searchVector().weighted(.A),
            $0.body.searchVector().weighted(.B),
            $0.title.searchVector().weighted(.C),
            $0.body.searchVector().weighted(.D)
          )
        }
      ) {
        """
        SELECT setweight(to_tsvector('english'::regconfig, "articles"."title"), 'A'), setweight(to_tsvector('english'::regconfig, "articles"."body"), 'B'), setweight(to_tsvector('english'::regconfig, "articles"."title"), 'C'), setweight(to_tsvector('english'::regconfig, "articles"."body"), 'D')
        FROM "articles"
        """
      }
    }

    @Test("Concatenate weighted vectors")
    func concatWeightedVectors() async {
      await assertSQL(
        of: Article.select {
          $0.title.searchVector().weighted(.A)
            .concat($0.body.searchVector().weighted(.B))
        }
      ) {
        """
        SELECT (setweight(to_tsvector('english'::regconfig, "articles"."title"), 'A') || setweight(to_tsvector('english'::regconfig, "articles"."body"), 'B'))
        FROM "articles"
        """
      }
    }

    @Test("Length of tsvector")
    func tsvectorLength() async {
      await assertSQL(of: Article.select { $0.title.searchVector().length() }) {
        """
        SELECT length(to_tsvector('english'::regconfig, "articles"."title"))
        FROM "articles"
        """
      }
    }

    @Test("Strip weights from tsvector")
    func stripWeights() async {
      await assertSQL(
        of: Article.select { $0.title.searchVector().weighted(.A).stripped() }
      ) {
        """
        SELECT strip(setweight(to_tsvector('english'::regconfig, "articles"."title"), 'A'))
        FROM "articles"
        """
      }
    }

    @Test("Complex vector manipulation chain")
    func complexVectorManipulation() async {
      await assertSQL(
        of: Article.select {
          (
            $0.title.searchVector().weighted(.A)
              .concat($0.body.searchVector().weighted(.B)),
            $0.title.searchVector().length()
          )
        }
      ) {
        """
        SELECT (setweight(to_tsvector('english'::regconfig, "articles"."title"), 'A') || setweight(to_tsvector('english'::regconfig, "articles"."body"), 'B')), length(to_tsvector('english'::regconfig, "articles"."title"))
        FROM "articles"
        """
      }
    }

    @Test("Filter by vector length")
    func filterByVectorLength() async {
      await assertSQL(of: Article.where { $0.title.searchVector().length() > 5 }) {
        """
        SELECT "articles"."id", "articles"."title", "articles"."body", "articles"."searchVector"
        FROM "articles"
        WHERE (length(to_tsvector('english'::regconfig, "articles"."title"))) > (5)
        """
      }
    }

    @Test("Multi-language weighted vectors")
    func multiLanguageWeightedVectors() async {
      await assertSQL(
        of: Article.select {
          $0.title.searchVector("french").weighted(.A)
            .concat($0.body.searchVector("french").weighted(.B))
        }
      ) {
        """
        SELECT (setweight(to_tsvector('french'::regconfig, "articles"."title"), 'A') || setweight(to_tsvector('french'::regconfig, "articles"."body"), 'B'))
        FROM "articles"
        """
      }
    }

    // MARK: - Edge Case Tests

    @Test("Empty search query")
    func emptyQuery() async {
      await assertSQL(of: Article.where { $0.match("") }) {
        """
        SELECT "articles"."id", "articles"."title", "articles"."body", "articles"."searchVector"
        FROM "articles"
        WHERE "articles"."searchVector" @@ to_tsquery('english'::regconfig, '')
        """
      }
    }

    @Test("Special characters in search")
    func specialCharactersSearch() async {
      await assertSQL(of: Article.where { $0.match("swift & (postgresql | mysql)") }) {
        """
        SELECT "articles"."id", "articles"."title", "articles"."body", "articles"."searchVector"
        FROM "articles"
        WHERE "articles"."searchVector" @@ to_tsquery('english'::regconfig, 'swift & (postgresql | mysql)')
        """
      }
    }

    @Test("Phrase match with quotes")
    func phraseMatchQuotes() async {
      await assertSQL(of: Article.where { $0.phraseMatch(#"swift "server" development"#) }) {
        """
        SELECT "articles"."id", "articles"."title", "articles"."body", "articles"."searchVector"
        FROM "articles"
        WHERE "articles"."searchVector" @@ phraseto_tsquery('english'::regconfig, 'swift "server" development')
        """
      }
    }

    @Test("Web match with complex query")
    func webMatchComplex() async {
      await assertSQL(
        of: Article.where { $0.webMatch(#""exact phrase" OR keyword -excluded"#) }
      ) {
        """
        SELECT "articles"."id", "articles"."title", "articles"."body", "articles"."searchVector"
        FROM "articles"
        WHERE "articles"."searchVector" @@ websearch_to_tsquery('english'::regconfig, '"exact phrase" OR keyword -excluded')
        """
      }
    }

    @Test("Multiple setweight operations")
    func multipleSetweightOps() async {
      await assertSQL(
        of: Article.select {
          $0.title.searchVector().weighted(.A).stripped().weighted(.B)
        }
      ) {
        """
        SELECT setweight(strip(setweight(to_tsvector('english'::regconfig, "articles"."title"), 'A')), 'B')
        FROM "articles"
        """
      }
    }
  }
}
