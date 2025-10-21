import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests {
    @Suite struct JsonbAggTests {
        // MARK: - Table.jsonbAgg Tests

        @Test("Table.jsonbAgg with closure syntax")
        func tableJsonbAggClosure() async {
            await assertSQL(of: Customer.jsonbAgg { $0.name }) {
                """
                SELECT JSONB_AGG("customers"."name")
                FROM "customers"
                """
            }
        }

        @Test("Table.jsonbAgg with filter using closure")
        func tableJsonbAggWithFilterClosure() async {
            await assertSQL(of: Order.jsonbAgg(of: { $0.orderID }, filter: { $0.isPaid })) {
                """
                SELECT JSONB_AGG("orders"."orderID") FILTER (WHERE "orders"."isPaid")
                FROM "orders"
                """
            }
        }

        @Test("Table.jsonbAgg with Int column")
        func tableJsonbAggInt() async {
            await assertSQL(of: Customer.jsonbAgg { $0.id }) {
                """
                SELECT JSONB_AGG("customers"."id")
                FROM "customers"
                """
            }
        }

        @Test("Table.jsonbAgg with Date column")
        func tableJsonbAggDate() async {
            await assertSQL(of: Order.jsonbAgg { $0.createdAt }) {
                """
                SELECT JSONB_AGG("orders"."createdAt")
                FROM "orders"
                """
            }
        }

        // MARK: - Where.jsonbAgg Tests

        @Test("Where.jsonbAgg with closure syntax")
        func whereJsonbAggClosure() async {
            await assertSQL(of: Order.where { $0.isPaid }.jsonbAgg { $0.orderID }) {
                """
                SELECT JSONB_AGG("orders"."orderID")
                FROM "orders"
                WHERE "orders"."isPaid"
                """
            }
        }

        @Test("Where.jsonbAgg with complex WHERE clause")
        func whereJsonbAggComplexWhere() async {
            await assertSQL(
                of: Order
                    .where { $0.isPaid && $0.amount > 100 }
                    .jsonbAgg { $0.orderID }
            ) {
                """
                SELECT JSONB_AGG("orders"."orderID")
                FROM "orders"
                WHERE ("orders"."isPaid") AND ("orders"."amount") > (100.0)
                """
            }
        }

        @Test("Where.jsonbAgg with filter clause")
        func whereJsonbAggWithFilter() async {
            await assertSQL(
                of: Order
                    .where { $0.createdAt > Date(timeIntervalSince1970: 0) }
                    .jsonbAgg(of: { $0.orderID }, filter: { $0.isPaid })
            ) {
                """
                SELECT JSONB_AGG("orders"."orderID") FILTER (WHERE "orders"."isPaid")
                FROM "orders"
                WHERE ("orders"."createdAt") > ('1970-01-01 00:00:00.000')
                """
            }
        }

        // MARK: - Select.jsonbAgg Tests (Low-Level API)

        @Test("Select.jsonbAgg using low-level API")
        func selectJsonbAggLowLevel() async {
            await assertSQL(of: Customer.select { $0.name.jsonbAgg() }) {
                """
                SELECT jsonb_agg("customers"."name")
                FROM "customers"
                """
            }
        }

        @Test("Select.jsonbAgg appending to existing columns")
        func selectJsonbAggAppendToColumns() async {
            await assertSQL(of: Customer.select { ($0.id, $0.name.jsonbAgg()) }) {
                """
                SELECT "customers"."id", jsonb_agg("customers"."name")
                FROM "customers"
                """
            }
        }

        @Test("Select.jsonbAgg with join using low-level API")
        func selectJsonbAggWithJoin() async {
            await assertSQL(
                of: Order
                    .join(Customer.all) { $0.customerID.eq($1.id) }
                    .select { order, _ in order.orderID.jsonbAgg() }
            ) {
                """
                SELECT jsonb_agg("orders"."orderID")
                FROM "orders"
                JOIN "customers" ON ("orders"."customerID") = ("customers"."id")
                """
            }
        }

        @Test("Select.jsonbAgg with distinct")
        func selectJsonbAggDistinct() async {
            await assertSQL(of: Customer.select { $0.name.jsonbAgg(distinct: true) }) {
                """
                SELECT jsonb_agg(DISTINCT "customers"."name")
                FROM "customers"
                """
            }
        }

        @Test("Select.jsonbAgg with filter")
        func selectJsonbAggWithFilter() async {
            await assertSQL(
                of: Order.select { $0.orderID.jsonbAgg(filter: $0.isPaid) }
            ) {
                """
                SELECT jsonb_agg("orders"."orderID") FILTER (WHERE "orders"."isPaid")
                FROM "orders"
                """
            }
        }

        // MARK: - Complex Expression Tests

        @Test("JsonbAgg of calculated expression")
        func jsonbAggCalculatedExpression() async {
            await assertSQL(of: Order.select { ($0.quantity * $0.unitPrice).jsonbAgg() }) {
                """
                SELECT jsonb_agg(("orders"."quantity") * ("orders"."unitPrice"))
                FROM "orders"
                """
            }
        }

        // MARK: - Compile-Time Type Tests

        func compileTimeTypeTests() {
            // Verify return types compile correctly

            // Table.jsonbAgg returns Select<String?, Customer, ()>
            let _: Select<String?, Customer, ()> = Customer.jsonbAgg { $0.name }

            // Where.jsonbAgg returns Select<String?, Order, ()>
            let _: Select<String?, Order, ()> = Order.where { $0.isPaid }.jsonbAgg { $0.orderID }

            // Int column returns String? (JSONB array serialized as string)
            let _: Select<String?, Customer, ()> = Customer.jsonbAgg { $0.id }
        }

        // MARK: - Edge Cases

        @Test("JsonbAgg with GROUP BY")
        func jsonbAggWithGroupBy() async {
            await assertSQL(
                of: Order
                    .group(by: \.customerID)
                    .select { ($0.customerID, $0.orderID.jsonbAgg()) }
            ) {
                """
                SELECT "orders"."customerID", jsonb_agg("orders"."orderID")
                FROM "orders"
                GROUP BY "orders"."customerID"
                """
            }
        }

        @Test("JsonbAgg with ORDER BY")
        func jsonbAggWithOrderBy() async {
            await assertSQL(
                of: Customer
                    .select { $0.name.jsonbAgg(order: $0.name.asc()) }
            ) {
                """
                SELECT jsonb_agg("customers"."name" ORDER BY "customers"."name" ASC)
                FROM "customers"
                """
            }
        }

        @Test("JsonbAgg with HAVING clause")
        func jsonbAggWithHaving() async {
            await assertSQL(
                of: Order
                    .group(by: \.customerID)
                    .select { ($0.customerID, $0.orderID.jsonbAgg()) }
                    .having { $0.orderID.count() > 1 }
            ) {
                """
                SELECT "orders"."customerID", jsonb_agg("orders"."orderID")
                FROM "orders"
                GROUP BY "orders"."customerID"
                HAVING (count("orders"."orderID")) > (1)
                """
            }
        }

        @Test("JsonbAgg with multiple GROUP BY columns")
        func jsonbAggWithMultipleGroupBy() async {
            await assertSQL(
                of: Order
                    .group(by: \.customerID)
                    .group(by: \.isPaid)
                    .select { ($0.customerID, $0.isPaid, $0.orderID.jsonbAgg()) }
            ) {
                """
                SELECT "orders"."customerID", "orders"."isPaid", jsonb_agg("orders"."orderID")
                FROM "orders"
                GROUP BY "orders"."customerID", "orders"."isPaid"
                """
            }
        }

        @Test("JsonbAgg with distinct and order")
        func jsonbAggDistinctWithOrder() async {
            await assertSQL(
                of: Customer.select { $0.name.jsonbAgg(distinct: true, order: $0.name.desc()) }
            ) {
                """
                SELECT jsonb_agg(DISTINCT "customers"."name" ORDER BY "customers"."name" DESC)
                FROM "customers"
                """
            }
        }

        @Test("JsonbAgg with distinct and filter")
        func jsonbAggDistinctWithFilter() async {
            await assertSQL(
                of: Order.select { $0.orderID.jsonbAgg(distinct: true, filter: $0.isPaid) }
            ) {
                """
                SELECT jsonb_agg(DISTINCT "orders"."orderID") FILTER (WHERE "orders"."isPaid")
                FROM "orders"
                """
            }
        }

        @Test("Multiple aggregates including jsonbAgg")
        func multipleAggregatesWithJsonbAgg() async {
            await assertSQL(
                of: Customer.select { ($0.id.count(), $0.name.jsonbAgg()) }
            ) {
                """
                SELECT count("customers"."id"), jsonb_agg("customers"."name")
                FROM "customers"
                """
            }
        }

        @Test("JsonbAgg of nullable column")
        func jsonbAggNullableColumn() async {
            await assertSQL(of: Order.jsonbAgg { $0.discount }) {
                """
                SELECT JSONB_AGG("orders"."discount")
                FROM "orders"
                """
            }
        }

        @Test("JsonbAgg vs ArrayAgg comparison in same query")
        func jsonbAggVsArrayAgg() async {
            await assertSQL(
                of: Customer.select { ($0.name.arrayAgg(), $0.name.jsonbAgg()) }
            ) {
                """
                SELECT array_agg("customers"."name"), jsonb_agg("customers"."name")
                FROM "customers"
                """
            }
        }
    }
}
