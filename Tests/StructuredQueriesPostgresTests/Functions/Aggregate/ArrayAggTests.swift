import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests {
    @Suite struct ArrayAggTests {
        // MARK: - Table.arrayAgg Tests

        @Test("Table.arrayAgg with closure syntax")
        func tableArrayAggClosure() async {
            await assertSQL(of: Customer.arrayAgg { $0.name }) {
                """
                SELECT array_agg("customers"."name")
                FROM "customers"
                """
            }
        }

        @Test("Table.arrayAgg with filter using closure")
        func tableArrayAggWithFilterClosure() async {
            await assertSQL(of: Order.arrayAgg(of: { $0.orderID }, filter: { $0.isPaid })) {
                """
                SELECT array_agg("orders"."orderID") FILTER (WHERE "orders"."isPaid")
                FROM "orders"
                """
            }
        }

        @Test("Table.arrayAgg with Int column")
        func tableArrayAggInt() async {
            await assertSQL(of: Customer.arrayAgg { $0.id }) {
                """
                SELECT array_agg("customers"."id")
                FROM "customers"
                """
            }
        }

        @Test("Table.arrayAgg with Date column")
        func tableArrayAggDate() async {
            await assertSQL(of: Order.arrayAgg { $0.createdAt }) {
                """
                SELECT array_agg("orders"."createdAt")
                FROM "orders"
                """
            }
        }

        // MARK: - Where.arrayAgg Tests

        @Test("Where.arrayAgg with closure syntax")
        func whereArrayAggClosure() async {
            await assertSQL(of: Order.where { $0.isPaid }.arrayAgg { $0.orderID }) {
                """
                SELECT array_agg("orders"."orderID")
                FROM "orders"
                WHERE "orders"."isPaid"
                """
            }
        }

        @Test("Where.arrayAgg with complex WHERE clause")
        func whereArrayAggComplexWhere() async {
            await assertSQL(
                of: Order
                    .where { $0.isPaid && $0.amount > 100 }
                    .arrayAgg { $0.orderID }
            ) {
                """
                SELECT array_agg("orders"."orderID")
                FROM "orders"
                WHERE ("orders"."isPaid") AND ("orders"."amount") > (100.0)
                """
            }
        }

        @Test("Where.arrayAgg with filter clause")
        func whereArrayAggWithFilter() async {
            await assertSQL(
                of: Order
                    .where { $0.createdAt > Date(timeIntervalSince1970: 0) }
                    .arrayAgg(of: { $0.orderID }, filter: { $0.isPaid })
            ) {
                """
                SELECT array_agg("orders"."orderID") FILTER (WHERE "orders"."isPaid")
                FROM "orders"
                WHERE ("orders"."createdAt") > ('1970-01-01 00:00:00.000')
                """
            }
        }

        // MARK: - Select.arrayAgg Tests (Low-Level API)

        @Test("Select.arrayAgg using low-level API")
        func selectArrayAggLowLevel() async {
            await assertSQL(of: Customer.select { $0.name.arrayAgg() }) {
                """
                SELECT array_agg("customers"."name")
                FROM "customers"
                """
            }
        }

        @Test("Select.arrayAgg appending to existing columns")
        func selectArrayAggAppendToColumns() async {
            await assertSQL(of: Customer.select { ($0.id, $0.name.arrayAgg()) }) {
                """
                SELECT "customers"."id", array_agg("customers"."name")
                FROM "customers"
                """
            }
        }

        @Test("Select.arrayAgg with join using low-level API")
        func selectArrayAggWithJoin() async {
            await assertSQL(
                of: Order
                    .join(Customer.all) { $0.customerID.eq($1.id) }
                    .select { order, _ in order.orderID.arrayAgg() }
            ) {
                """
                SELECT array_agg("orders"."orderID")
                FROM "orders"
                JOIN "customers" ON ("orders"."customerID") = ("customers"."id")
                """
            }
        }

        @Test("Select.arrayAgg with distinct")
        func selectArrayAggDistinct() async {
            await assertSQL(of: Customer.select { $0.name.arrayAgg(distinct: true) }) {
                """
                SELECT array_agg(DISTINCT "customers"."name")
                FROM "customers"
                """
            }
        }

        @Test("Select.arrayAgg with filter")
        func selectArrayAggWithFilter() async {
            await assertSQL(
                of: Order.select { $0.orderID.arrayAgg(filter: $0.isPaid) }
            ) {
                """
                SELECT array_agg("orders"."orderID") FILTER (WHERE "orders"."isPaid")
                FROM "orders"
                """
            }
        }

        // MARK: - Complex Expression Tests

        @Test("ArrayAgg of calculated expression")
        func arrayAggCalculatedExpression() async {
            await assertSQL(of: Order.select { ($0.quantity * $0.unitPrice).arrayAgg() }) {
                """
                SELECT array_agg(("orders"."quantity") * ("orders"."unitPrice"))
                FROM "orders"
                """
            }
        }

        // MARK: - Compile-Time Type Tests

        func compileTimeTypeTests() {
            // Verify return types compile correctly

            // Table.arrayAgg returns Select<String?, Customer, ()>
            let _: Select<String?, Customer, ()> = Customer.arrayAgg { $0.name }

            // Where.arrayAgg returns Select<String?, Order, ()>
            let _: Select<String?, Order, ()> = Order.where { $0.isPaid }.arrayAgg { $0.orderID }

            // Int column returns String? (array serialized as string)
            let _: Select<String?, Customer, ()> = Customer.arrayAgg { $0.id }
        }

        // MARK: - Edge Cases

        @Test("ArrayAgg with GROUP BY")
        func arrayAggWithGroupBy() async {
            await assertSQL(
                of: Order
                    .group(by: \.customerID)
                    .select { ($0.customerID, $0.orderID.arrayAgg()) }
            ) {
                """
                SELECT "orders"."customerID", array_agg("orders"."orderID")
                FROM "orders"
                GROUP BY "orders"."customerID"
                """
            }
        }

        @Test("ArrayAgg with ORDER BY")
        func arrayAggWithOrderBy() async {
            await assertSQL(
                of: Customer
                    .select { $0.name.arrayAgg(order: $0.name.asc()) }
            ) {
                """
                SELECT array_agg("customers"."name" ORDER BY "customers"."name" ASC)
                FROM "customers"
                """
            }
        }

        @Test("ArrayAgg with HAVING clause")
        func arrayAggWithHaving() async {
            await assertSQL(
                of: Order
                    .group(by: \.customerID)
                    .select { ($0.customerID, $0.orderID.arrayAgg()) }
                    .having { $0.orderID.count() > 1 }
            ) {
                """
                SELECT "orders"."customerID", array_agg("orders"."orderID")
                FROM "orders"
                GROUP BY "orders"."customerID"
                HAVING (count("orders"."orderID")) > (1)
                """
            }
        }

        @Test("ArrayAgg with multiple GROUP BY columns")
        func arrayAggWithMultipleGroupBy() async {
            await assertSQL(
                of: Order
                    .group(by: \.customerID)
                    .group(by: \.isPaid)
                    .select { ($0.customerID, $0.isPaid, $0.orderID.arrayAgg()) }
            ) {
                """
                SELECT "orders"."customerID", "orders"."isPaid", array_agg("orders"."orderID")
                FROM "orders"
                GROUP BY "orders"."customerID", "orders"."isPaid"
                """
            }
        }

        @Test("ArrayAgg with distinct and order")
        func arrayAggDistinctWithOrder() async {
            await assertSQL(
                of: Customer.select { $0.name.arrayAgg(distinct: true, order: $0.name.desc()) }
            ) {
                """
                SELECT array_agg(DISTINCT "customers"."name" ORDER BY "customers"."name" DESC)
                FROM "customers"
                """
            }
        }

        @Test("ArrayAgg with distinct and filter")
        func arrayAggDistinctWithFilter() async {
            await assertSQL(
                of: Order.select { $0.orderID.arrayAgg(distinct: true, filter: $0.isPaid) }
            ) {
                """
                SELECT array_agg(DISTINCT "orders"."orderID") FILTER (WHERE "orders"."isPaid")
                FROM "orders"
                """
            }
        }

        @Test("Multiple aggregates including arrayAgg")
        func multipleAggregatesWithArrayAgg() async {
            await assertSQL(
                of: Customer.select { ($0.id.count(), $0.name.arrayAgg()) }
            ) {
                """
                SELECT count("customers"."id"), array_agg("customers"."name")
                FROM "customers"
                """
            }
        }

        @Test("ArrayAgg of nullable column")
        func arrayAggNullableColumn() async {
            await assertSQL(of: Order.arrayAgg { $0.discount }) {
                """
                SELECT array_agg("orders"."discount")
                FROM "orders"
                """
            }
        }
    }
}
