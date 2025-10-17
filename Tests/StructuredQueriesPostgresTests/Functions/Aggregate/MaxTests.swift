import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests {
    @Suite struct MaxTests {
        // MARK: - Table.max Tests

        @Test("Table.max with closure syntax")
        func tableMaxClosure() async {
            await assertSQL(of: Order.max { $0.amount }) {
                """
                SELECT max("orders"."amount")
                FROM "orders"
                """
            }
        }

        @Test("Table.max with KeyPath syntax")
        func tableMaxKeyPath() async {
            await assertSQL(of: Order.max(of: \.amount)) {
                """
                SELECT max("orders"."amount")
                FROM "orders"
                """
            }
        }

        @Test("Table.max with filter using closure")
        func tableMaxWithFilterClosure() async {
            await assertSQL(of: Order.max(of: { $0.amount }, filter: { $0.isPaid })) {
                """
                SELECT max("orders"."amount") FILTER (WHERE "orders"."isPaid")
                FROM "orders"
                """
            }
        }

        @Test("Table.max with filter using KeyPath")
        func tableMaxWithFilterKeyPath() async {
            await assertSQL(of: Order.max(of: \.amount, filter: { $0.isPaid })) {
                """
                SELECT max("orders"."amount") FILTER (WHERE "orders"."isPaid")
                FROM "orders"
                """
            }
        }

        @Test("Table.max with Double column")
        func tableMaxDouble() async {
            await assertSQL(of: Order.max { $0.unitPrice }) {
                """
                SELECT max("orders"."unitPrice")
                FROM "orders"
                """
            }
        }

        @Test("Table.max with Int column")
        func tableMaxInt() async {
            await assertSQL(of: Order.max { $0.customerID }) {
                """
                SELECT max("orders"."customerID")
                FROM "orders"
                """
            }
        }

        @Test("Table.max with Date column")
        func tableMaxDate() async {
            await assertSQL(of: Order.max { $0.createdAt }) {
                """
                SELECT max("orders"."createdAt")
                FROM "orders"
                """
            }
        }

        // MARK: - Where.max Tests

        @Test("Where.max with closure syntax")
        func whereMaxClosure() async {
            await assertSQL(of: Order.where( { $0.isPaid }).max { $0.amount }) {
                """
                SELECT max("orders"."amount")
                FROM "orders"
                WHERE "orders"."isPaid"
                """
            }
        }

        @Test("Where.max with KeyPath syntax")
        func whereMaxKeyPath() async {
            await assertSQL(of: Order.where(\.isPaid).max(of: \.amount)) {
                """
                SELECT max("orders"."amount")
                FROM "orders"
                WHERE "orders"."isPaid"
                """
            }
        }

        @Test("Where.max with complex WHERE clause")
        func whereMaxComplexWhere() async {
            await assertSQL(
                of: Order
                    .where { $0.isPaid && $0.amount > 100 }
                    .max { $0.amount }
            ) {
                """
                SELECT max("orders"."amount")
                FROM "orders"
                WHERE ("orders"."isPaid") AND ("orders"."amount") > (100.0)
                """
            }
        }

        @Test("Where.max with filter clause")
        func whereMaxWithFilter() async {
            await assertSQL(
                of: Order
                    .where { $0.createdAt > Date(timeIntervalSince1970: 0) }
                    .max(of: \.amount, filter: { $0.isPaid })
            ) {
                """
                SELECT max("orders"."amount") FILTER (WHERE "orders"."isPaid")
                FROM "orders"
                WHERE ("orders"."createdAt") > ('1970-01-01 00:00:00.000')
                """
            }
        }

        // MARK: - Select.max Tests

        @Test("Select.max using low-level API")
        func selectMaxLowLevel() async {
            await assertSQL(of: Order.select { $0.amount.max() }) {
                """
                SELECT max("orders"."amount")
                FROM "orders"
                """
            }
        }

        @Test("Select.max appending to existing columns using low-level")
        func selectMaxAppendToColumns() async {
            await assertSQL(of: Order.select { ($0.orderID, $0.amount.max()) }) {
                """
                SELECT "orders"."orderID", max("orders"."amount")
                FROM "orders"
                """
            }
        }

        @Test("Select.max with join using low-level API")
        func selectMaxWithJoin() async {
            await assertSQL(
                of: Order
                    .join(Customer.all) { $0.customerID.eq($1.id) }
                    .select { order, _ in order.amount.max() }
            ) {
                """
                SELECT max("orders"."amount")
                FROM "orders"
                JOIN "customers" ON ("orders"."customerID") = ("customers"."id")
                """
            }
        }

        @Test("Select.max with join and existing columns using low-level")
        func selectMaxWithJoinAndColumns() async {
            await assertSQL(
                of: Order
                    .join(Customer.all) { $0.customerID.eq($1.id) }
                    .select { ($1.name, $0.amount.max()) }
            ) {
                """
                SELECT "customers"."name", max("orders"."amount")
                FROM "orders"
                JOIN "customers" ON ("orders"."customerID") = ("customers"."id")
                """
            }
        }

        @Test("Select.max accessing joined table columns using low-level")
        func selectMaxJoinedColumns() async {
            await assertSQL(
                of: Order
                    .join(LineItem.all) { $0.orderID.eq($1.orderID) }
                    .select { _, lineItem in lineItem.price.max() }
            ) {
                """
                SELECT max("lineItems"."price")
                FROM "orders"
                JOIN "lineItems" ON ("orders"."orderID") = ("lineItems"."orderID")
                """
            }
        }

        // MARK: - Nullable Column Tests

        @Test("Max of nullable column returns single optional")
        func maxNullableColumn() async {
            // Test that nullable column (discount: Double?) returns Select<Double?, ...>
            // NOT Select<Double??, ...> (double optional)
            await assertSQL(of: Order.max { $0.discount }) {
                """
                SELECT max("orders"."discount")
                FROM "orders"
                """
            }
        }

        // MARK: - Complex Expression Tests

        @Test("Max of calculated expression")
        func maxCalculatedExpression() async {
            await assertSQL(of: Order.max { $0.quantity * $0.unitPrice }) {
                """
                SELECT max(("orders"."quantity") * ("orders"."unitPrice"))
                FROM "orders"
                """
            }
        }

        @Test("Multiple aggregates including max in one query")
        func multipleAggregatesWithMax() async {
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

            // Table.max returns Select<Double?, Order, ()>
            let _: Select<Double?, Order, ()> = Order.max { $0.amount }
            let _: Select<Double?, Order, ()> = Order.max(of: \.amount)

            // Where.max returns Select<Double?, Order, ()>
            let _: Select<Double?, Order, ()> = Order.where { $0.isPaid }.max { $0.amount }
            let _: Select<Double?, Order, ()> = Order.where { $0.isPaid }.max(of: \.amount)

            // Int column returns Int?
            let _: Select<Int?, Order, ()> = Order.max { $0.customerID }

            // Date column returns Date?
            let _: Select<Date?, Order, ()> = Order.max { $0.createdAt }

            // Nullable column returns single optional, not double
            let _: Select<Double?, Order, ()> = Order.max { $0.discount }

            // Complex expression
            let _: Select<Double?, Order, ()> = Order.max { $0.quantity * $0.unitPrice }
        }

        // MARK: - Edge Cases

        @Test("Max with GROUP BY")
        func maxWithGroupBy() async {
            await assertSQL(
                of: Order
                    .group(by: \.customerID)
                    .select { ($0.customerID, $0.amount.max()) }
            ) {
                """
                SELECT "orders"."customerID", max("orders"."amount")
                FROM "orders"
                GROUP BY "orders"."customerID"
                """
            }
        }

        @Test("Max with ORDER BY the max")
        func maxWithOrderBy() async {
            await assertSQL(
                of: Order
                    .group(by: \.customerID)
                    .order { $0.amount.max().desc() }
                    .select { ($0.customerID, $0.amount.max()) }
            ) {
                """
                SELECT "orders"."customerID", max("orders"."amount")
                FROM "orders"
                GROUP BY "orders"."customerID"
                ORDER BY max("orders"."amount") DESC
                """
            }
        }

        @Test("Max with HAVING clause")
        func maxWithHavingClause() async {
            await assertSQL(
                of: Order
                    .group(by: \.customerID)
                    .select { ($0.customerID, $0.amount.max()) }
                    .having { $0.amount.max() > 1000.0 }
            ) {
                """
                SELECT "orders"."customerID", max("orders"."amount")
                FROM "orders"
                GROUP BY "orders"."customerID"
                HAVING (max("orders"."amount")) > (1000.0)
                """
            }
        }

        @Test("Max with HAVING and WHERE")
        func maxWithHavingAndWhere() async {
            await assertSQL(
                of: Order
                    .where { $0.isPaid }
                    .group(by: \.customerID)
                    .select { ($0.customerID, $0.amount.max()) }
                    .having { $0.amount.max() > 500.0 }
            ) {
                """
                SELECT "orders"."customerID", max("orders"."amount")
                FROM "orders"
                WHERE "orders"."isPaid"
                GROUP BY "orders"."customerID"
                HAVING (max("orders"."amount")) > (500.0)
                """
            }
        }

        @Test("Max with HAVING using different operators")
        func maxWithHavingDifferentOperators() async {
            // Test less than
            await assertSQL(
                of: Order
                    .group(by: \.customerID)
                    .select { ($0.customerID, $0.amount.max()) }
                    .having { $0.amount.max() < 1000.0 }
            ) {
                """
                SELECT "orders"."customerID", max("orders"."amount")
                FROM "orders"
                GROUP BY "orders"."customerID"
                HAVING (max("orders"."amount")) < (1000.0)
                """
            }

            // Test greater than or equal
            await assertSQL(
                of: Order
                    .group(by: \.customerID)
                    .select { ($0.customerID, $0.amount.max()) }
                    .having { $0.amount.max() >= 250.0 }
            ) {
                """
                SELECT "orders"."customerID", max("orders"."amount")
                FROM "orders"
                GROUP BY "orders"."customerID"
                HAVING (max("orders"."amount")) >= (250.0)
                """
            }

            // Test less than or equal
            await assertSQL(
                of: Order
                    .group(by: \.customerID)
                    .select { ($0.customerID, $0.amount.max()) }
                    .having { $0.amount.max() <= 5000.0 }
            ) {
                """
                SELECT "orders"."customerID", max("orders"."amount")
                FROM "orders"
                GROUP BY "orders"."customerID"
                HAVING (max("orders"."amount")) <= (5000.0)
                """
            }
        }

        @Test("Max with multiple GROUP BY columns")
        func maxWithMultipleGroupBy() async {
            await assertSQL(
                of: Order
                    .group(by: \.customerID)
                    .group(by: \.isPaid)
                    .select { ($0.customerID, $0.isPaid, $0.amount.max()) }
            ) {
                """
                SELECT "orders"."customerID", "orders"."isPaid", max("orders"."amount")
                FROM "orders"
                GROUP BY "orders"."customerID", "orders"."isPaid"
                """
            }
        }

        @Test("Max of latest date per group")
        func maxDatePerGroup() async {
            await assertSQL(
                of: Order
                    .group(by: \.customerID)
                    .select { ($0.customerID, $0.createdAt.max()) }
            ) {
                """
                SELECT "orders"."customerID", max("orders"."createdAt")
                FROM "orders"
                GROUP BY "orders"."customerID"
                """
            }
        }
    }
}
