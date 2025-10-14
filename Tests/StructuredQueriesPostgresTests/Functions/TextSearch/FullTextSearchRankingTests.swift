import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests.FullTextSearch {
    @Suite("Ranking") struct RankingTests {

        // MARK: - Basic Ranking

        @Test("Basic rank")
        func basicRank() async {
            await assertSQL(
                of:
                    FTSArticle
                    .where { $0.match("swift") }
                    .select { ($0, $0.rank(by: "swift")) }
            ) {
                """
                SELECT "articles"."id", "articles"."title", "articles"."body", "articles"."searchVector", ts_rank("articles"."searchVector", to_tsquery('english'::regconfig, 'swift'))
                FROM "articles"
                WHERE "articles"."searchVector" @@ to_tsquery('english'::regconfig, 'swift')
                """
            }
        }

        @Test("Rank with normalization")
        func rankWithNormalization() async {
            await assertSQL(
                of:
                    FTSArticle
                    .where { $0.match("swift") }
                    .select { ($0, $0.rank(by: "swift", normalization: .divideByLogLength)) }
            ) {
                """
                SELECT "articles"."id", "articles"."title", "articles"."body", "articles"."searchVector", ts_rank("articles"."searchVector", to_tsquery('english'::regconfig, 'swift'), 1)
                FROM "articles"
                WHERE "articles"."searchVector" @@ to_tsquery('english'::regconfig, 'swift')
                """
            }
        }

        @Test("Rank with combined normalization flags")
        func rankCombinedNormalization() async {
            await assertSQL(
                of:
                    FTSArticle
                    .where { $0.match("swift") }
                    .select {
                        (
                            $0,
                            $0.rank(
                                by: "swift", normalization: [.divideByLogLength, .divideByLength])
                        )
                    }
            ) {
                """
                SELECT "articles"."id", "articles"."title", "articles"."body", "articles"."searchVector", ts_rank("articles"."searchVector", to_tsquery('english'::regconfig, 'swift'), 3)
                FROM "articles"
                WHERE "articles"."searchVector" @@ to_tsquery('english'::regconfig, 'swift')
                """
            }
        }

        @Test("Coverage-based rank")
        func rankCoverage() async {
            await assertSQL(
                of:
                    FTSArticle
                    .where { $0.match("quick <-> brown") }
                    .select { ($0, $0.rank(byCoverage: "quick <-> brown")) }
            ) {
                """
                SELECT "articles"."id", "articles"."title", "articles"."body", "articles"."searchVector", ts_rank_cd("articles"."searchVector", to_tsquery('english'::regconfig, 'quick <-> brown'))
                FROM "articles"
                WHERE "articles"."searchVector" @@ to_tsquery('english'::regconfig, 'quick <-> brown')
                """
            }
        }

        // MARK: - Weighted Ranking

        @Test("Rank with custom weights")
        func rankWithWeights() async {
            await assertSQL(
                of:
                    FTSArticle
                    .where { $0.match("swift") }
                    .select { ($0.id, $0.rank(by: "swift", weights: [0.1, 0.2, 0.4, 1.0])) }
            ) {
                """
                SELECT "articles"."id", ts_rank(ARRAY[0.1, 0.2, 0.4, 1.0], "articles"."searchVector", to_tsquery('english'::regconfig, 'swift'))
                FROM "articles"
                WHERE "articles"."searchVector" @@ to_tsquery('english'::regconfig, 'swift')
                """
            }
        }

        @Test("Rank with weights and normalization")
        func rankWithWeightsAndNormalization() async {
            await assertSQL(
                of:
                    FTSArticle
                    .where { $0.match("swift") }
                    .select {
                        (
                            $0.id,
                            $0.rank(
                                by: "swift", weights: [0.1, 0.2, 0.4, 1.0],
                                normalization: .divideByLogLength)
                        )
                    }
            ) {
                """
                SELECT "articles"."id", ts_rank(ARRAY[0.1, 0.2, 0.4, 1.0], "articles"."searchVector", to_tsquery('english'::regconfig, 'swift'), 1)
                FROM "articles"
                WHERE "articles"."searchVector" @@ to_tsquery('english'::regconfig, 'swift')
                """
            }
        }

        @Test("Rank with weights and language")
        func rankWithWeightsAndLanguage() async {
            await assertSQL(
                of:
                    FTSArticle
                    .where { $0.match("développement", language: "french") }
                    .select {
                        (
                            $0.id,
                            $0.rank(
                                by: "développement", weights: [0.2, 0.3, 0.5, 1.0],
                                language: "french")
                        )
                    }
            ) {
                """
                SELECT "articles"."id", ts_rank(ARRAY[0.2, 0.3, 0.5, 1.0], "articles"."searchVector", to_tsquery('french'::regconfig, 'développement'))
                FROM "articles"
                WHERE "articles"."searchVector" @@ to_tsquery('french'::regconfig, 'développement')
                """
            }
        }

        @Test("Coverage rank with custom weights")
        func rankCoverageWithWeights() async {
            await assertSQL(
                of:
                    FTSArticle
                    .where { $0.match("quick <-> brown") }
                    .select {
                        (
                            $0.id,
                            $0.rank(byCoverage: "quick <-> brown", weights: [0.1, 0.2, 0.4, 1.0])
                        )
                    }
            ) {
                """
                SELECT "articles"."id", ts_rank_cd(ARRAY[0.1, 0.2, 0.4, 1.0], "articles"."searchVector", to_tsquery('english'::regconfig, 'quick <-> brown'))
                FROM "articles"
                WHERE "articles"."searchVector" @@ to_tsquery('english'::regconfig, 'quick <-> brown')
                """
            }
        }

        @Test("Coverage rank with weights and normalization")
        func rankCoverageWithWeightsAndNormalization() async {
            await assertSQL(
                of:
                    FTSArticle
                    .where { $0.match("swift & postgresql") }
                    .select {
                        (
                            $0.id,
                            $0.rank(
                                byCoverage: "swift & postgresql", weights: [0.1, 0.2, 0.4, 1.0],
                                normalization: .divideByLength)
                        )
                    }
            ) {
                """
                SELECT "articles"."id", ts_rank_cd(ARRAY[0.1, 0.2, 0.4, 1.0], "articles"."searchVector", to_tsquery('english'::regconfig, 'swift & postgresql'), 2)
                FROM "articles"
                WHERE "articles"."searchVector" @@ to_tsquery('english'::regconfig, 'swift & postgresql')
                """
            }
        }

        @Test("Compare standard vs coverage ranking with weights")
        func compareRankingMethods() async {
            await assertSQL(
                of:
                    FTSArticle
                    .where { $0.match("swift") }
                    .select {
                        (
                            $0.id,
                            $0.rank(by: "swift", weights: [0.1, 0.2, 0.4, 1.0]),
                            $0.rank(byCoverage: "swift", weights: [0.1, 0.2, 0.4, 1.0])
                        )
                    }
            ) {
                """
                SELECT "articles"."id", ts_rank(ARRAY[0.1, 0.2, 0.4, 1.0], "articles"."searchVector", to_tsquery('english'::regconfig, 'swift')), ts_rank_cd(ARRAY[0.1, 0.2, 0.4, 1.0], "articles"."searchVector", to_tsquery('english'::regconfig, 'swift'))
                FROM "articles"
                WHERE "articles"."searchVector" @@ to_tsquery('english'::regconfig, 'swift')
                """
            }
        }

        @Test("Rank with zero weight")
        func rankZeroWeight() async {
            await assertSQL(
                of:
                    FTSArticle
                    .where { $0.match("swift") }
                    .select { ($0.id, $0.rank(by: "swift", weights: [0.0, 0.0, 0.0, 1.0])) }
            ) {
                """
                SELECT "articles"."id", ts_rank(ARRAY[0.0, 0.0, 0.0, 1.0], "articles"."searchVector", to_tsquery('english'::regconfig, 'swift'))
                FROM "articles"
                WHERE "articles"."searchVector" @@ to_tsquery('english'::regconfig, 'swift')
                """
            }
        }
    }
}
