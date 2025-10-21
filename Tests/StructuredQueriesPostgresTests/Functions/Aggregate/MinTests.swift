import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests {
    @Suite struct MinTests {
        // MARK: - Table.min Tests

        @Test("Table.min with closure syntax")
        func tableMinClosure() async {
            await assertSQL(of: Order.min { $0.amount }) {
                """
                SELECT min("orders"."amount")
                FROM "orders"
                """
            }
        }

        @Test("Table.min with KeyPath syntax")
        func tableMinKeyPath() async {
            await assertSQL(of: Order.min(of: \.amount)) {
                """
                SELECT min("orders"."amount")
                FROM "orders"
                """
            }
        }

        @Test("Table.min with filter using closure")
        func tableMinWithFilterClosure() async {
            await assertSQL(of: Order.min(of: { $0.amount }, filter: { $0.isPaid })) {
                """
                SELECT min("orders"."amount") FILTER (WHERE "orders"."isPaid")
                FROM "orders"
                """
            }
        }

        @Test("Table.min with filter using KeyPath")
        func tableMinWithFilterKeyPath() async {
            await assertSQL(of: Order.min(of: \.amount, filter: { $0.isPaid })) {
                """
                SELECT min("orders"."amount") FILTER (WHERE "orders"."isPaid")
                FROM "orders"
                """
            }
        }

        @Test("Table.min with Double column")
        func tableMinDouble() async {
            await assertSQL(of: Order.min { $0.unitPrice }) {
                """
                SELECT min("orders"."unitPrice")
                FROM "orders"
                """
            }
        }

        @Test("Table.min with Int column")
        func tableMinInt() async {
            await assertSQL(of: Order.min { $0.customerID }) {
                """
                SELECT min("orders"."customerID")
                FROM "orders"
                """
            }
        }

        @Test("Table.min with Date column")
        func tableMinDate() async {
            await assertSQL(of: Order.min { $0.createdAt }) {
                """
                SELECT min("orders"."createdAt")
                FROM "orders"
                """
            }
        }

        // MARK: - Where.min Tests

        @Test("Where.min with closure syntax")
        func whereMinClosure() async {
            await assertSQL(of: Order.where( { $0.isPaid }).min { $0.amount }) {
                """
                SELECT min("orders"."amount")
                FROM "orders"
                WHERE "orders"."isPaid"
                """
            }
        }

        @Test("Where.min with KeyPath syntax")
        func whereMinKeyPath() async {
            await assertSQL(of: Order.where(\.isPaid).min(of: \.amount)) {
                """
                SELECT min("orders"."amount")
                FROM "orders"
                WHERE "orders"."isPaid"
                """
            }
        }

        @Test("Where.min with complex WHERE clause")
        func whereMinComplexWhere() async {
            await assertSQL(
                of: Order
                    .where { $0.isPaid && $0.amount > 100 }
                    .min { $0.amount }
            ) {
                """
                SELECT min("orders"."amount")
                FROM "orders"
                WHERE ("orders"."isPaid") AND ("orders"."amount") > (100.0)
                """
            }
        }

        @Test("Where.min with filter clause")
        func whereMinWithFilter() async {
            await assertSQL(
                of: Order
                    .where { $0.createdAt > Date(timeIntervalSince1970: 0) }
                    .min(of: \.amount, filter: { $0.isPaid })
            ) {
                """
                SELECT min("orders"."amount") FILTER (WHERE "orders"."isPaid")
                FROM "orders"
                WHERE ("orders"."createdAt") > ('1970-01-01 00:00:00.000')
                """
            }
        }

        // MARK: - Select.min Tests

        @Test("Select.min using low-level API")
        func selectMinLowLevel() async {
            await assertSQL(of: Order.select { $0.amount.min() }) {
                """
                SELECT min("orders"."amount")
                FROM "orders"
                """
            }
        }

        @Test("Select.min appending to existing columns using low-level")
        func selectMinAppendToColumns() async {
            await assertSQL(of: Order.select { ($0.orderID, $0.amount.min()) }) {
                """
                SELECT "orders"."orderID", min("orders"."amount")
                FROM "orders"
                """
            }
        }

        @Test("Select.min with join using low-level API")
        func selectMinWithJoin() async {
            await assertSQL(
                of: Order
                    .join(Customer.all) { $0.customerID.eq($1.id) }
                    .select { order, _ in order.amount.min() }
            ) {
                """
                SELECT min("orders"."amount")
                FROM "orders"
                JOIN "customers" ON ("orders"."customerID") = ("customers"."id")
                """
            }
        }

        @Test("Select.min with join and existing columns using low-level")
        func selectMinWithJoinAndColumns() async {
            await assertSQL(
                of: Order
                    .join(Customer.all) { $0.customerID.eq($1.id) }
                    .select { ($1.name, $0.amount.min()) }
            ) {
                """
                SELECT "customers"."name", min("orders"."amount")
                FROM "orders"
                JOIN "customers" ON ("orders"."customerID") = ("customers"."id")
                """
            }
        }

        @Test("Select.min accessing joined table columns using low-level")
        func selectMinJoinedColumns() async {
            await assertSQL(
                of: Order
                    .join(LineItem.all) { $0.orderID.eq($1.orderID) }
                    .select { _, lineItem in lineItem.price.min() }
            ) {
                """
                SELECT min("lineItems"."price")
                FROM "orders"
                JOIN "lineItems" ON ("orders"."orderID") = ("lineItems"."orderID")
                """
            }
        }

        // MARK: - Nullable Column Tests

        @Test("Min of nullable column returns single optional")
        func minNullableColumn() async {
            // Test that nullable column (discount: Double?) returns Select<Double?, ...>
            // NOT Select<Double??, ...> (double optional)
            await assertSQL(of: Order.min { $0.discount }) {
                """
                SELECT min("orders"."discount")
                FROM "orders"
                """
            }
        }

        // MARK: - Complex Expression Tests

        @Test("Min of calculated expression")
        func minCalculatedExpression() async {
            await assertSQL(of: Order.min { $0.quantity * $0.unitPrice }) {
                """
                SELECT min(("orders"."quantity") * ("orders"."unitPrice"))
                FROM "orders"
                """
            }
        }

        @Test("Multiple aggregates including min in one query")
        func multipleAggregatesWithMin() async {
            await assertSQL(
                of: Order.select { ($0.amount.min(), $0.amount.max()) }
            ) {
                """
                SELECT min("orders"."amount"), max("orders"."amount")
                FROM "orders"
                """
            }
        }

        // MARK: - Compile-Time Type Tests

        func compileTimeTypeTests() {
            // Verify return types compile correctly

            // Table.min returns Select<Double?, Order, ()>
            let _: Select<Double?, Order, ()> = Order.min { $0.amount }
            let _: Select<Double?, Order, ()> = Order.min(of: \.amount)

            // Where.min returns Select<Double?, Order, ()>
            let _: Select<Double?, Order, ()> = Order.where { $0.isPaid }.min { $0.amount }
            let _: Select<Double?, Order, ()> = Order.where { $0.isPaid }.min(of: \.amount)

            // Int column returns Int?
            let _: Select<Int?, Order, ()> = Order.min { $0.customerID }

            // Date column returns Date?
            let _: Select<Date?, Order, ()> = Order.min { $0.createdAt }

            // Nullable column returns single optional, not double
            let _: Select<Double?, Order, ()> = Order.min { $0.discount }

            // Complex expression
            let _: Select<Double?, Order, ()> = Order.min { $0.quantity * $0.unitPrice }
        }

        // MARK: - Edge Cases

        @Test("Min with GROUP BY")
        func minWithGroupBy() async {
            await assertSQL(
                of: Order
                    .group(by: \.customerID)
                    .select { ($0.customerID, $0.amount.min()) }
            ) {
                """
                SELECT "orders"."customerID", min("orders"."amount")
                FROM "orders"
                GROUP BY "orders"."customerID"
                """
            }
        }

        @Test("Min with ORDER BY the min")
        func minWithOrderBy() async {
            await assertSQL(
                of: Order
                    .group(by: \.customerID)
                    .order { $0.amount.min().desc() }
                    .select { ($0.customerID, $0.amount.min()) }
            ) {
                """
                SELECT "orders"."customerID", min("orders"."amount")
                FROM "orders"
                GROUP BY "orders"."customerID"
                ORDER BY min("orders"."amount") DESC
                """
            }
        }

        @Test("Min with HAVING clause")
        func minWithHavingClause() async {
            await assertSQL(
                of: Order
                    .group(by: \.customerID)
                    .select { ($0.customerID, $0.amount.min()) }
                    .having { $0.amount.min() > 100.0 }
            ) {
                """
                SELECT "orders"."customerID", min("orders"."amount")
                FROM "orders"
                GROUP BY "orders"."customerID"
                HAVING (min("orders"."amount")) > (100.0)
                """
            }
        }

        @Test("Min with HAVING and WHERE")
        func minWithHavingAndWhere() async {
            await assertSQL(
                of: Order
                    .where { $0.isPaid }
                    .group(by: \.customerID)
                    .select { ($0.customerID, $0.amount.min()) }
                    .having { $0.amount.min() > 50.0 }
            ) {
                """
                SELECT "orders"."customerID", min("orders"."amount")
                FROM "orders"
                WHERE "orders"."isPaid"
                GROUP BY "orders"."customerID"
                HAVING (min("orders"."amount")) > (50.0)
                """
            }
        }

        @Test("Min with HAVING using different operators")
        func minWithHavingDifferentOperators() async {
            // Test less than
            await assertSQL(
                of: Order
                    .group(by: \.customerID)
                    .select { ($0.customerID, $0.amount.min()) }
                    .having { $0.amount.min() < 100.0 }
            ) {
                """
                SELECT "orders"."customerID", min("orders"."amount")
                FROM "orders"
                GROUP BY "orders"."customerID"
                HAVING (min("orders"."amount")) < (100.0)
                """
            }

            // Test greater than or equal
            await assertSQL(
                of: Order
                    .group(by: \.customerID)
                    .select { ($0.customerID, $0.amount.min()) }
                    .having { $0.amount.min() >= 25.0 }
            ) {
                """
                SELECT "orders"."customerID", min("orders"."amount")
                FROM "orders"
                GROUP BY "orders"."customerID"
                HAVING (min("orders"."amount")) >= (25.0)
                """
            }

            // Test less than or equal
            await assertSQL(
                of: Order
                    .group(by: \.customerID)
                    .select { ($0.customerID, $0.amount.min()) }
                    .having { $0.amount.min() <= 500.0 }
            ) {
                """
                SELECT "orders"."customerID", min("orders"."amount")
                FROM "orders"
                GROUP BY "orders"."customerID"
                HAVING (min("orders"."amount")) <= (500.0)
                """
            }
        }

        @Test("Min with multiple GROUP BY columns")
        func minWithMultipleGroupBy() async {
            await assertSQL(
                of: Order
                    .group(by: \.customerID)
                    .group(by: \.isPaid)
                    .select { ($0.customerID, $0.isPaid, $0.amount.min()) }
            ) {
                """
                SELECT "orders"."customerID", "orders"."isPaid", min("orders"."amount")
                FROM "orders"
                GROUP BY "orders"."customerID", "orders"."isPaid"
                """
            }
        }

        @Test("Min of earliest date per group")
        func minDatePerGroup() async {
            await assertSQL(
                of: Order
                    .group(by: \.customerID)
                    .select { ($0.customerID, $0.createdAt.min()) }
            ) {
                """
                SELECT "orders"."customerID", min("orders"."createdAt")
                FROM "orders"
                GROUP BY "orders"."customerID"
                """
            }
        }
    }
}
