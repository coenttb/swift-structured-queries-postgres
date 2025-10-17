import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests {
    @Suite struct SumTests {
        // MARK: - Table.sum Tests

        @Test("Table.sum with closure syntax")
        func tableSumClosure() async {
            await assertSQL(of: Order.sum { $0.amount }) {
                """
                SELECT SUM("orders"."amount")
                FROM "orders"
                """
            }
        }

        @Test("Table.sum with KeyPath syntax")
        func tableSumKeyPath() async {
            await assertSQL(of: Order.sum(of: \.amount)) {
                """
                SELECT SUM("orders"."amount")
                FROM "orders"
                """
            }
        }

        @Test("Table.sum with filter using closure")
        func tableSumWithFilterClosure() async {
            await assertSQL(of: Order.sum(of: { $0.amount }, filter: { $0.isPaid })) {
                """
                SELECT SUM("orders"."amount") FILTER (WHERE "orders"."isPaid")
                FROM "orders"
                """
            }
        }

        @Test("Table.sum with filter using KeyPath")
        func tableSumWithFilterKeyPath() async {
            await assertSQL(of: Order.sum(of: \.amount, filter: { $0.isPaid })) {
                """
                SELECT SUM("orders"."amount") FILTER (WHERE "orders"."isPaid")
                FROM "orders"
                """
            }
        }

        @Test("Table.sum with Double column")
        func tableSumDouble() async {
            await assertSQL(of: Order.sum { $0.unitPrice }) {
                """
                SELECT SUM("orders"."unitPrice")
                FROM "orders"
                """
            }
        }

        // MARK: - Where.sum Tests

        @Test("Where.sum with closure syntax")
        func whereSumClosure() async {
            await assertSQL(of: Order.where( { $0.isPaid }).sum { $0.amount }) {
                """
                SELECT SUM("orders"."amount")
                FROM "orders"
                WHERE "orders"."isPaid"
                """
            }
        }

        @Test("Where.sum with KeyPath syntax")
        func whereSumKeyPath() async {
            await assertSQL(of: Order.where(\.isPaid).sum(of: \.amount)) {
                """
                SELECT SUM("orders"."amount")
                FROM "orders"
                WHERE "orders"."isPaid"
                """
            }
        }

        @Test("Where.sum with complex WHERE clause")
        func whereSumComplexWhere() async {
            await assertSQL(
                of: Order
                    .where { $0.isPaid && $0.amount > 100 }
                    .sum { $0.amount }
            ) {
                """
                SELECT SUM("orders"."amount")
                FROM "orders"
                WHERE ("orders"."isPaid") AND ("orders"."amount") > (100.0)
                """
            }
        }

        @Test("Where.sum with filter clause")
        func whereSumWithFilter() async {
            await assertSQL(
                of: Order
                    .where { $0.createdAt > Date(timeIntervalSince1970: 0) }
                    .sum(of: \.amount, filter: { $0.isPaid })
            ) {
                """
                SELECT SUM("orders"."amount") FILTER (WHERE "orders"."isPaid")
                FROM "orders"
                WHERE ("orders"."createdAt") > ('1970-01-01 00:00:00.000')
                """
            }
        }

        // MARK: - Select.sum Tests

        @Test("Select.sum using low-level API")
        func selectSumLowLevel() async {
            await assertSQL(of: Order.select { $0.amount.sum() }) {
                """
                SELECT SUM("orders"."amount")
                FROM "orders"
                """
            }
        }

        @Test("Select.sum appending to existing columns using low-level")
        func selectSumAppendToColumns() async {
            await assertSQL(of: Order.select { ($0.orderID, $0.amount.sum()) }) {
                """
                SELECT "orders"."orderID", SUM("orders"."amount")
                FROM "orders"
                """
            }
        }

        @Test("Select.sum with join using low-level API")
        func selectSumWithJoin() async {
            await assertSQL(
                of: Order
                    .join(Customer.all) { $0.customerID.eq($1.id) }
                    .select { order, _ in order.amount.sum() }
            ) {
                """
                SELECT SUM("orders"."amount")
                FROM "orders"
                JOIN "customers" ON ("orders"."customerID") = ("customers"."id")
                """
            }
        }

        @Test("Select.sum with join and existing columns using low-level")
        func selectSumWithJoinAndColumns() async {
            await assertSQL(
                of: Order
                    .join(Customer.all) { $0.customerID.eq($1.id) }
                    .select { ($1.name, $0.amount.sum()) }
            ) {
                """
                SELECT "customers"."name", SUM("orders"."amount")
                FROM "orders"
                JOIN "customers" ON ("orders"."customerID") = ("customers"."id")
                """
            }
        }

        @Test("Select.sum accessing joined table columns using low-level")
        func selectSumJoinedColumns() async {
            await assertSQL(
                of: Order
                    .join(LineItem.all) { $0.orderID.eq($1.orderID) }
                    .select { _, lineItem in (lineItem.price * lineItem.quantity).sum() }
            ) {
                """
                SELECT SUM(("lineItems"."price") * ("lineItems"."quantity"))
                FROM "orders"
                JOIN "lineItems" ON ("orders"."orderID") = ("lineItems"."orderID")
                """
            }
        }

        // MARK: - Nullable Column Tests

        @Test("Sum of nullable column returns single optional")
        func sumNullableColumn() async {
            // Test that nullable column (discount: Double?) returns Select<Double?, ...>
            // NOT Select<Double??, ...> (double optional)
            await assertSQL(of: Order.sum { $0.discount }) {
                """
                SELECT SUM("orders"."discount")
                FROM "orders"
                """
            }
        }

        @Test("Sum with DISTINCT")
        func sumDistinct() async {
            await assertSQL(of: Order.select { $0.amount.sum(distinct: true) }) {
                """
                SELECT SUM(DISTINCT "orders"."amount")
                FROM "orders"
                """
            }
        }

        // MARK: - Complex Expression Tests

        @Test("Sum of calculated expression")
        func sumCalculatedExpression() async {
            await assertSQL(of: Order.sum { $0.quantity * $0.unitPrice }) {
                """
                SELECT SUM(("orders"."quantity") * ("orders"."unitPrice"))
                FROM "orders"
                """
            }
        }

        @Test("Multiple aggregates in one query")
        func multipleAggregates() async {
            await assertSQL(
                of: Order.select { ($0.amount.sum(), $0.quantity.sum()) }
            ) {
                """
                SELECT SUM("orders"."amount"), SUM("orders"."quantity")
                FROM "orders"
                """
            }
        }

        // MARK: - Compile-Time Type Tests

        func compileTimeTypeTests() {
            // Verify return types compile correctly

            // Table.sum returns Select<Double?, Order, ()>
            let _: Select<Double?, Order, ()> = Order.sum { $0.amount }
            let _: Select<Double?, Order, ()> = Order.sum(of: \.amount)

            // Where.sum returns Select<Double?, Order, ()>
            let _: Select<Double?, Order, ()> = Order.where { $0.isPaid }.sum { $0.amount }
            let _: Select<Double?, Order, ()> = Order.where { $0.isPaid }.sum(of: \.amount)

            // Double column returns Double?
            let _: Select<Double?, Order, ()> = Order.sum { $0.quantity }

            // Nullable column returns single optional, not double
            let _: Select<Double?, Order, ()> = Order.sum { $0.discount }

            // Complex expression
            let _: Select<Double?, Order, ()> = Order.sum { $0.quantity * $0.unitPrice }
        }

        // MARK: - Edge Cases

        @Test("Sum with GROUP BY")
        func sumWithGroupBy() async {
            await assertSQL(
                of: Order
                    .group(by: \.customerID)
                    .select { ($0.customerID, $0.amount.sum()) }
            ) {
                """
                SELECT "orders"."customerID", SUM("orders"."amount")
                FROM "orders"
                GROUP BY "orders"."customerID"
                """
            }
        }

        @Test("Sum with HAVING")
        func sumWithHaving() async {
            await assertSQL(
                of: Order
                    .group(by: \.customerID)
                    .select { ($0.customerID, $0.amount.sum()) }
            ) {
                """
                SELECT "orders"."customerID", SUM("orders"."amount")
                FROM "orders"
                GROUP BY "orders"."customerID"
                """
            }
        }

        @Test("Sum with ORDER BY the sum")
        func sumWithOrderBy() async {
            await assertSQL(
                of: Order
                    .group(by: \.customerID)
                    .order { $0.amount.sum().desc() }
                    .select { ($0.customerID, $0.amount.sum()) }
            ) {
                """
                SELECT "orders"."customerID", SUM("orders"."amount")
                FROM "orders"
                GROUP BY "orders"."customerID"
                ORDER BY SUM("orders"."amount") DESC
                """
            }
        }

        @Test("Sum with HAVING clause")
        func sumWithHavingClause() async {
            await assertSQL(
                of: Order
                    .group(by: \.customerID)
                    .select { ($0.customerID, $0.amount.sum()) }
                    .having { $0.amount.sum() > 1000.0 }
            ) {
                """
                SELECT "orders"."customerID", SUM("orders"."amount")
                FROM "orders"
                GROUP BY "orders"."customerID"
                HAVING (SUM("orders"."amount")) > (1000.0)
                """
            }
        }

        @Test("Sum with HAVING and WHERE")
        func sumWithHavingAndWhere() async {
            await assertSQL(
                of: Order
                    .where { $0.isPaid }
                    .group(by: \.customerID)
                    .select { ($0.customerID, $0.amount.sum()) }
                    .having { $0.amount.sum() > 500.0 }
            ) {
                """
                SELECT "orders"."customerID", SUM("orders"."amount")
                FROM "orders"
                WHERE "orders"."isPaid"
                GROUP BY "orders"."customerID"
                HAVING (SUM("orders"."amount")) > (500.0)
                """
            }
        }

        @Test("Sum with HAVING using different operators")
        func sumWithHavingDifferentOperators() async {
            // Test less than
            await assertSQL(
                of: Order
                    .group(by: \.customerID)
                    .select { ($0.customerID, $0.amount.sum()) }
                    .having { $0.amount.sum() < 100.0 }
            ) {
                """
                SELECT "orders"."customerID", SUM("orders"."amount")
                FROM "orders"
                GROUP BY "orders"."customerID"
                HAVING (SUM("orders"."amount")) < (100.0)
                """
            }

            // Test greater than or equal
            await assertSQL(
                of: Order
                    .group(by: \.customerID)
                    .select { ($0.customerID, $0.amount.sum()) }
                    .having { $0.amount.sum() >= 250.0 }
            ) {
                """
                SELECT "orders"."customerID", SUM("orders"."amount")
                FROM "orders"
                GROUP BY "orders"."customerID"
                HAVING (SUM("orders"."amount")) >= (250.0)
                """
            }

            // Test less than or equal
            await assertSQL(
                of: Order
                    .group(by: \.customerID)
                    .select { ($0.customerID, $0.amount.sum()) }
                    .having { $0.amount.sum() <= 5000.0 }
            ) {
                """
                SELECT "orders"."customerID", SUM("orders"."amount")
                FROM "orders"
                GROUP BY "orders"."customerID"
                HAVING (SUM("orders"."amount")) <= (5000.0)
                """
            }
        }
    }
}
