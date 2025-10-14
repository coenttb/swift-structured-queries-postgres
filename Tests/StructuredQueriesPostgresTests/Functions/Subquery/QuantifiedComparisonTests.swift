import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests.Subquery {
    @Suite("Quantified Comparison") struct QuantifiedComparisonTests {

        // MARK: - ANY Operator Tests

        @Test func equalsAny() async {
            // Create a subquery expression using raw SQL
            let subquery = #sql(
                "SELECT id FROM shop_products WHERE featured = true", as: [Int].self)

            await assertSQL(
                of: ShopProduct.where { $0.id.equalsAny(subquery) }
            ) {
                """
                SELECT "shopProducts"."id", "shopProducts"."name", "shopProducts"."price"
                FROM "shopProducts"
                WHERE ("shopProducts"."id" = ANY (SELECT id FROM shop_products WHERE featured = true))
                """
            }
        }

        @Test func lessThanAny() async {
            let subquery = #sql("SELECT price FROM competitors", as: [Double].self)

            await assertSQL(
                of: ShopProduct.where { $0.price.lessThanAny(subquery) }
            ) {
                """
                SELECT "shopProducts"."id", "shopProducts"."name", "shopProducts"."price"
                FROM "shopProducts"
                WHERE ("shopProducts"."price" < ANY (SELECT price FROM competitors))
                """
            }
        }

        @Test func greaterThanAny() async {
            let subquery = #sql("SELECT score FROM benchmarks", as: [Double].self)

            await assertSQL(
                of: ShopProduct.where { $0.price.greaterThanAny(subquery) }
            ) {
                """
                SELECT "shopProducts"."id", "shopProducts"."name", "shopProducts"."price"
                FROM "shopProducts"
                WHERE ("shopProducts"."price" > ANY (SELECT score FROM benchmarks))
                """
            }
        }

        @Test func notEqualsAny() async {
            let subquery = #sql("SELECT id FROM banned_products", as: [Int].self)

            await assertSQL(
                of: ShopProduct.where { $0.id.notEqualsAny(subquery) }
            ) {
                """
                SELECT "shopProducts"."id", "shopProducts"."name", "shopProducts"."price"
                FROM "shopProducts"
                WHERE ("shopProducts"."id" <> ANY (SELECT id FROM banned_products))
                """
            }
        }

        // MARK: - ALL Operator Tests

        @Test func equalsAll() async {
            let subquery = #sql("SELECT required_value FROM requirements", as: [Int].self)

            await assertSQL(
                of: ShopProduct.where { $0.id.equalsAll(subquery) }
            ) {
                """
                SELECT "shopProducts"."id", "shopProducts"."name", "shopProducts"."price"
                FROM "shopProducts"
                WHERE ("shopProducts"."id" = ALL (SELECT required_value FROM requirements))
                """
            }
        }

        @Test func lessThanAll() async {
            let subquery = #sql("SELECT max_price FROM price_limits", as: [Double].self)

            await assertSQL(
                of: ShopProduct.where { $0.price.lessThanAll(subquery) }
            ) {
                """
                SELECT "shopProducts"."id", "shopProducts"."name", "shopProducts"."price"
                FROM "shopProducts"
                WHERE ("shopProducts"."price" < ALL (SELECT max_price FROM price_limits))
                """
            }
        }

        @Test func greaterThanAll() async {
            let subquery = #sql("SELECT min_score FROM minimum_requirements", as: [Double].self)

            await assertSQL(
                of: ShopProduct.where { $0.price.greaterThanAll(subquery) }
            ) {
                """
                SELECT "shopProducts"."id", "shopProducts"."name", "shopProducts"."price"
                FROM "shopProducts"
                WHERE ("shopProducts"."price" > ALL (SELECT min_score FROM minimum_requirements))
                """
            }
        }

        @Test func notEqualsAll() async {
            let subquery = #sql("SELECT id FROM excluded_products", as: [Int].self)

            await assertSQL(
                of: ShopProduct.where { $0.id.notEqualsAll(subquery) }
            ) {
                """
                SELECT "shopProducts"."id", "shopProducts"."name", "shopProducts"."price"
                FROM "shopProducts"
                WHERE ("shopProducts"."id" <> ALL (SELECT id FROM excluded_products))
                """
            }
        }

        // MARK: - SOME Operator Tests

        @Test func lessThanSome() async {
            let subquery = #sql("SELECT price FROM competitor_products", as: [Double].self)

            await assertSQL(
                of: ShopProduct.where { $0.price.lessThanSome(subquery) }
            ) {
                """
                SELECT "shopProducts"."id", "shopProducts"."name", "shopProducts"."price"
                FROM "shopProducts"
                WHERE ("shopProducts"."price" < SOME (SELECT price FROM competitor_products))
                """
            }
        }

        @Test func greaterThanSome() async {
            let subquery = #sql("SELECT baseline_price FROM baselines", as: [Double].self)

            await assertSQL(
                of: ShopProduct.where { $0.price.greaterThanSome(subquery) }
            ) {
                """
                SELECT "shopProducts"."id", "shopProducts"."name", "shopProducts"."price"
                FROM "shopProducts"
                WHERE ("shopProducts"."price" > SOME (SELECT baseline_price FROM baselines))
                """
            }
        }
    }
}

// MARK: - Test Model

@Table
private struct ShopProduct {
    let id: Int
    let name: String
    let price: Double
}

// MARK: - SnapshotTests.Subquery Namespace

extension SnapshotTests {
    enum Subquery {}
}
