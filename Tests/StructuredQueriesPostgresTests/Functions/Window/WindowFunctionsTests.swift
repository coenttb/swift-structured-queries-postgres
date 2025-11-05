import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

// Test tables for window functions
@Table("scores")
struct Score {
    let id: Int
    let playerId: Int
    let points: Int
    let gameDate: Date
}

@Table("products")
struct Product {
    let id: Int
    let name: String
    let category: String
    let price: Double
}

@Table("stock_prices")
struct StockPrice {
    let id: Int
    let symbol: String
    let date: Date
    let price: Double
}

extension SnapshotTests {
    @Suite("Window Functions") struct WindowFunctionsTests {

        // MARK: - ROW_NUMBER Tests

        @Test func rowNumberBasic() async {
            let query = Score.select {
                ($0, rowNumber().over())
            }

            await assertSQL(of: SQLQueryExpression(query)) {
                """
                SELECT "scores"."id", "scores"."playerId", "scores"."points", "scores"."gameDate", ROW_NUMBER() OVER ()
                FROM "scores"
                """
            }
        }

        @Test func rowNumberWithOrder() async {
            let query = Score.select {
                let points = $0.points
                return ($0, rowNumber().over { $0.order(by: points.desc()) })
            }

            await assertSQL(of: SQLQueryExpression(query)) {
                """
                SELECT "scores"."id", "scores"."playerId", "scores"."points", "scores"."gameDate", ROW_NUMBER() OVER (ORDER BY "scores"."points" DESC)
                FROM "scores"
                """
            }
        }

        @Test func rowNumberWithPartitionAndOrder() async {
            let query = Score.select {
                let playerId = $0.playerId
                let points = $0.points
                return (
                    $0,
                    rowNumber().over { spec in
                        spec.partition(by: playerId).order(by: points.desc())
                    }
                )
            }

            await assertSQL(of: SQLQueryExpression(query)) {
                """
                SELECT "scores"."id", "scores"."playerId", "scores"."points", "scores"."gameDate", ROW_NUMBER() OVER (PARTITION BY "scores"."playerId" ORDER BY "scores"."points" DESC)
                FROM "scores"
                """
            }
        }

        // MARK: - RANK Tests

        @Test func rankBasic() async {
            let query = Score.select {
                let points = $0.points
                return ($0, rank().over { $0.order(by: points.desc()) })
            }

            await assertSQL(of: SQLQueryExpression(query)) {
                """
                SELECT "scores"."id", "scores"."playerId", "scores"."points", "scores"."gameDate", RANK() OVER (ORDER BY "scores"."points" DESC)
                FROM "scores"
                """
            }
        }

        @Test func rankWithPartition() async {
            let query = Score.select {
                let playerId = $0.playerId
                let points = $0.points
                return (
                    $0,
                    rank().over { spec in
                        spec.partition(by: playerId).order(by: points.desc())
                    }
                )
            }

            await assertSQL(of: SQLQueryExpression(query)) {
                """
                SELECT "scores"."id", "scores"."playerId", "scores"."points", "scores"."gameDate", RANK() OVER (PARTITION BY "scores"."playerId" ORDER BY "scores"."points" DESC)
                FROM "scores"
                """
            }
        }

        // MARK: - DENSE_RANK Tests

        @Test func denseRankBasic() async {
            let query = Score.select {
                let points = $0.points
                return ($0, denseRank().over { $0.order(by: points.desc()) })
            }

            await assertSQL(of: SQLQueryExpression(query)) {
                """
                SELECT "scores"."id", "scores"."playerId", "scores"."points", "scores"."gameDate", DENSE_RANK() OVER (ORDER BY "scores"."points" DESC)
                FROM "scores"
                """
            }
        }

        // MARK: - LAG/LEAD Tests

        @Test func lagBasic() async {
            let query = StockPrice.select {
                let price = $0.price
                let date = $0.date
                return ($0, price.lag().over { $0.order(by: date.asc()) })
            }

            await assertSQL(of: SQLQueryExpression(query)) {
                """
                SELECT "stock_prices"."id", "stock_prices"."symbol", "stock_prices"."date", "stock_prices"."price", LAG("stock_prices"."price", 1) OVER (ORDER BY "stock_prices"."date" ASC)
                FROM "stock_prices"
                """
            }
        }

        @Test func lagWithDefault() async {
            let query = StockPrice.select {
                let price = $0.price
                let date = $0.date
                return ($0, price.lag(offset: 1, default: 0.0).over { $0.order(by: date.asc()) })
            }

            await assertSQL(of: SQLQueryExpression(query)) {
                """
                SELECT "stock_prices"."id", "stock_prices"."symbol", "stock_prices"."date", "stock_prices"."price", LAG("stock_prices"."price", 1, 0.0) OVER (ORDER BY "stock_prices"."date" ASC)
                FROM "stock_prices"
                """
            }
        }

        @Test func leadBasic() async {
            let query = StockPrice.select {
                let price = $0.price
                let date = $0.date
                return ($0, price.lead().over { $0.order(by: date.asc()) })
            }

            await assertSQL(of: SQLQueryExpression(query)) {
                """
                SELECT "stock_prices"."id", "stock_prices"."symbol", "stock_prices"."date", "stock_prices"."price", LEAD("stock_prices"."price", 1) OVER (ORDER BY "stock_prices"."date" ASC)
                FROM "stock_prices"
                """
            }
        }

        // MARK: - FIRST_VALUE/LAST_VALUE Tests

        @Test func firstValueBasic() async {
            let query = Product.select {
                let price = $0.price
                return ($0, price.firstValue().over { $0.order(by: price.desc()) })
            }

            await assertSQL(of: SQLQueryExpression(query)) {
                """
                SELECT "products"."id", "products"."name", "products"."category", "products"."price", FIRST_VALUE("products"."price") OVER (ORDER BY "products"."price" DESC)
                FROM "products"
                """
            }
        }

        @Test func lastValueWithPartition() async {
            let query = Product.select {
                let category = $0.category
                let price = $0.price
                return (
                    $0,
                    price.lastValue().over { spec in
                        spec.partition(by: category).order(by: price.desc())
                    }
                )
            }

            await assertSQL(of: SQLQueryExpression(query)) {
                """
                SELECT "products"."id", "products"."name", "products"."category", "products"."price", LAST_VALUE("products"."price") OVER (PARTITION BY "products"."category" ORDER BY "products"."price" DESC)
                FROM "products"
                """
            }
        }

        // MARK: - NTH_VALUE Tests

        @Test func nthValueSecond() async {
            let query = Product.select {
                let category = $0.category
                let price = $0.price
                return (
                    $0,
                    price.nthValue(2).over { spec in
                        spec.partition(by: category).order(by: price.desc())
                    }
                )
            }

            await assertSQL(of: SQLQueryExpression(query)) {
                """
                SELECT "products"."id", "products"."name", "products"."category", "products"."price", NTH_VALUE("products"."price", 2) OVER (PARTITION BY "products"."category" ORDER BY "products"."price" DESC)
                FROM "products"
                """
            }
        }

        // MARK: - NTILE Tests

        @Test func ntileQuartiles() async {
            let query = Product.select {
                let price = $0.price
                return ($0, ntile(4).over { $0.order(by: price.asc()) })
            }

            await assertSQL(of: SQLQueryExpression(query)) {
                """
                SELECT "products"."id", "products"."name", "products"."category", "products"."price", NTILE(4) OVER (ORDER BY "products"."price" ASC)
                FROM "products"
                """
            }
        }

        // MARK: - PERCENT_RANK and CUME_DIST Tests

        @Test func percentRank() async {
            let query = Score.select {
                let points = $0.points
                return (
                    $0, StructuredQueriesPostgres.percentRank().over { $0.order(by: points.desc()) }
                )
            }

            await assertSQL(of: SQLQueryExpression(query)) {
                """
                SELECT "scores"."id", "scores"."playerId", "scores"."points", "scores"."gameDate", PERCENT_RANK() OVER (ORDER BY "scores"."points" DESC)
                FROM "scores"
                """
            }
        }

        @Test func cumeDist() async {
            let query = Score.select {
                let points = $0.points
                return (
                    $0, StructuredQueriesPostgres.cumeDist().over { $0.order(by: points.desc()) }
                )
            }

            await assertSQL(of: SQLQueryExpression(query)) {
                """
                SELECT "scores"."id", "scores"."playerId", "scores"."points", "scores"."gameDate", CUME_DIST() OVER (ORDER BY "scores"."points" DESC)
                FROM "scores"
                """
            }
        }
    }
}
