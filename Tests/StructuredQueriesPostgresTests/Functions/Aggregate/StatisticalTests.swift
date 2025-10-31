import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests {
  @Suite struct StatisticalTests {
    // MARK: - Table.stddev Tests

    @Test("Table.stddev with closure syntax")
    func tableStddevClosure() async {
      await assertSQL(of: Order.stddev { $0.amount }) {
        """
        SELECT STDDEV("orders"."amount")
        FROM "orders"
        """
      }
    }

    @Test("Table.stddev with filter using closure")
    func tableStddevWithFilterClosure() async {
      await assertSQL(of: Order.stddev(of: { $0.amount }, filter: { $0.isPaid })) {
        """
        SELECT STDDEV("orders"."amount") FILTER (WHERE "orders"."isPaid")
        FROM "orders"
        """
      }
    }

    @Test("Table.stddev with Int column")
    func tableStddevInt() async {
      await assertSQL(of: Order.stddev { $0.quantity }) {
        """
        SELECT STDDEV("orders"."quantity")
        FROM "orders"
        """
      }
    }

    @Test("Table.stddev with Double column")
    func tableStddevDouble() async {
      await assertSQL(of: Order.stddev { $0.unitPrice }) {
        """
        SELECT STDDEV("orders"."unitPrice")
        FROM "orders"
        """
      }
    }

    // MARK: - Table.variance Tests

    @Test("Table.variance with closure syntax")
    func tableVarianceClosure() async {
      await assertSQL(of: Order.variance { $0.amount }) {
        """
        SELECT VARIANCE("orders"."amount")
        FROM "orders"
        """
      }
    }

    @Test("Table.variance with filter using closure")
    func tableVarianceWithFilterClosure() async {
      await assertSQL(of: Order.variance(of: { $0.amount }, filter: { $0.isPaid })) {
        """
        SELECT VARIANCE("orders"."amount") FILTER (WHERE "orders"."isPaid")
        FROM "orders"
        """
      }
    }

    @Test("Table.variance with Int column")
    func tableVarianceInt() async {
      await assertSQL(of: Order.variance { $0.quantity }) {
        """
        SELECT VARIANCE("orders"."quantity")
        FROM "orders"
        """
      }
    }

    // MARK: - Where.stddev Tests

    @Test("Where.stddev with closure syntax")
    func whereStddevClosure() async {
      await assertSQL(of: Order.where { $0.isPaid }.stddev { $0.amount }) {
        """
        SELECT STDDEV("orders"."amount")
        FROM "orders"
        WHERE "orders"."isPaid"
        """
      }
    }

    @Test("Where.stddev with complex WHERE clause")
    func whereStddevComplexWhere() async {
      await assertSQL(
        of:
          Order
          .where { $0.isPaid && $0.amount > 100 }
          .stddev { $0.amount }
      ) {
        """
        SELECT STDDEV("orders"."amount")
        FROM "orders"
        WHERE ("orders"."isPaid") AND ("orders"."amount") > (100.0)
        """
      }
    }

    @Test("Where.stddev with filter clause")
    func whereStddevWithFilter() async {
      await assertSQL(
        of:
          Order
          .where { $0.createdAt > Date(timeIntervalSince1970: 0) }
          .stddev(of: { $0.amount }, filter: { $0.isPaid })
      ) {
        """
        SELECT STDDEV("orders"."amount") FILTER (WHERE "orders"."isPaid")
        FROM "orders"
        WHERE ("orders"."createdAt") > ('1970-01-01 00:00:00.000')
        """
      }
    }

    // MARK: - Where.variance Tests

    @Test("Where.variance with closure syntax")
    func whereVarianceClosure() async {
      await assertSQL(of: Order.where { $0.isPaid }.variance { $0.amount }) {
        """
        SELECT VARIANCE("orders"."amount")
        FROM "orders"
        WHERE "orders"."isPaid"
        """
      }
    }

    @Test("Where.variance with complex WHERE clause")
    func whereVarianceComplexWhere() async {
      await assertSQL(
        of:
          Order
          .where { $0.isPaid && $0.amount > 100 }
          .variance { $0.amount }
      ) {
        """
        SELECT VARIANCE("orders"."amount")
        FROM "orders"
        WHERE ("orders"."isPaid") AND ("orders"."amount") > (100.0)
        """
      }
    }

    @Test("Where.variance with filter clause")
    func whereVarianceWithFilter() async {
      await assertSQL(
        of:
          Order
          .where { $0.createdAt > Date(timeIntervalSince1970: 0) }
          .variance(of: { $0.amount }, filter: { $0.isPaid })
      ) {
        """
        SELECT VARIANCE("orders"."amount") FILTER (WHERE "orders"."isPaid")
        FROM "orders"
        WHERE ("orders"."createdAt") > ('1970-01-01 00:00:00.000')
        """
      }
    }

    // MARK: - Select Tests (Low-Level API)

    @Test("Select.stddev using low-level API")
    func selectStddevLowLevel() async {
      await assertSQL(of: Order.select { $0.amount.stddev() }) {
        """
        SELECT stddev("orders"."amount")
        FROM "orders"
        """
      }
    }

    @Test("Select.variance using low-level API")
    func selectVarianceLowLevel() async {
      await assertSQL(of: Order.select { $0.amount.variance() }) {
        """
        SELECT variance("orders"."amount")
        FROM "orders"
        """
      }
    }

    @Test("Select.stddev appending to existing columns")
    func selectStddevAppendToColumns() async {
      await assertSQL(of: Order.select { ($0.orderID, $0.amount.stddev()) }) {
        """
        SELECT "orders"."orderID", stddev("orders"."amount")
        FROM "orders"
        """
      }
    }

    @Test("Select.stddev with join")
    func selectStddevWithJoin() async {
      await assertSQL(
        of:
          Order
          .join(Customer.all) { $0.customerID.eq($1.id) }
          .select { order, _ in order.amount.stddev() }
      ) {
        """
        SELECT stddev("orders"."amount")
        FROM "orders"
        JOIN "customers" ON ("orders"."customerID") = ("customers"."id")
        """
      }
    }

    @Test("Select.stddev with filter")
    func selectStddevWithFilter() async {
      await assertSQL(
        of: Order.select { $0.amount.stddev(filter: $0.isPaid) }
      ) {
        """
        SELECT stddev("orders"."amount") FILTER (WHERE "orders"."isPaid")
        FROM "orders"
        """
      }
    }

    // MARK: - Statistical Variants

    @Test("StddevPop function")
    func stddevPop() async {
      await assertSQL(of: Order.select { $0.amount.stddevPop() }) {
        """
        SELECT stddev_pop("orders"."amount")
        FROM "orders"
        """
      }
    }

    @Test("StddevSamp function")
    func stddevSamp() async {
      await assertSQL(of: Order.select { $0.amount.stddevSamp() }) {
        """
        SELECT stddev_samp("orders"."amount")
        FROM "orders"
        """
      }
    }

    @Test("VarPop function")
    func varPop() async {
      await assertSQL(of: Order.select { $0.amount.varPop() }) {
        """
        SELECT VAR_POP("orders"."amount")
        FROM "orders"
        """
      }
    }

    @Test("VarSamp function")
    func varSamp() async {
      await assertSQL(of: Order.select { $0.amount.varSamp() }) {
        """
        SELECT VAR_SAMP("orders"."amount")
        FROM "orders"
        """
      }
    }

    // MARK: - Complex Expression Tests

    @Test("Stddev of calculated expression")
    func stddevCalculatedExpression() async {
      await assertSQL(of: Order.stddev { $0.quantity * $0.unitPrice }) {
        """
        SELECT STDDEV(("orders"."quantity") * ("orders"."unitPrice"))
        FROM "orders"
        """
      }
    }

    @Test("Variance of calculated expression")
    func varianceCalculatedExpression() async {
      await assertSQL(of: Order.variance { $0.quantity * $0.unitPrice }) {
        """
        SELECT VARIANCE(("orders"."quantity") * ("orders"."unitPrice"))
        FROM "orders"
        """
      }
    }

    @Test("Multiple statistical aggregates in one query")
    func multipleStatisticalAggregates() async {
      await assertSQL(
        of: Order.select { ($0.amount.stddev(), $0.amount.variance()) }
      ) {
        """
        SELECT stddev("orders"."amount"), variance("orders"."amount")
        FROM "orders"
        """
      }
    }

    @Test("Mix of statistical and numeric aggregates")
    func mixedAggregates() async {
      await assertSQL(
        of: Order.select { ($0.amount.avg(), $0.amount.stddev(), $0.amount.min(), $0.amount.max()) }
      ) {
        """
        SELECT avg("orders"."amount"), stddev("orders"."amount"), min("orders"."amount"), max("orders"."amount")
        FROM "orders"
        """
      }
    }

    // MARK: - Compile-Time Type Tests

    func compileTimeTypeTests() {
      // Verify return types compile correctly

      // Table.stddev returns Select<Double?, Order, ()>
      let _: Select<Double?, Order, ()> = Order.stddev { $0.amount }

      // Table.variance returns Select<Double?, Order, ()>
      let _: Select<Double?, Order, ()> = Order.variance { $0.amount }

      // Where.stddev returns Select<Double?, Order, ()>
      let _: Select<Double?, Order, ()> = Order.where { $0.isPaid }.stddev { $0.amount }

      // Where.variance returns Select<Double?, Order, ()>
      let _: Select<Double?, Order, ()> = Order.where { $0.isPaid }.variance { $0.amount }

      // Int column returns Double?
      let _: Select<Double?, Order, ()> = Order.stddev { $0.quantity }
    }

    // MARK: - Edge Cases

    @Test("Stddev with GROUP BY")
    func stddevWithGroupBy() async {
      await assertSQL(
        of:
          Order
          .group(by: \.customerID)
          .select { ($0.customerID, $0.amount.stddev()) }
      ) {
        """
        SELECT "orders"."customerID", stddev("orders"."amount")
        FROM "orders"
        GROUP BY "orders"."customerID"
        """
      }
    }

    @Test("Variance with GROUP BY")
    func varianceWithGroupBy() async {
      await assertSQL(
        of:
          Order
          .group(by: \.customerID)
          .select { ($0.customerID, $0.amount.variance()) }
      ) {
        """
        SELECT "orders"."customerID", variance("orders"."amount")
        FROM "orders"
        GROUP BY "orders"."customerID"
        """
      }
    }

    @Test("Stddev with HAVING clause")
    func stddevWithHaving() async {
      await assertSQL(
        of:
          Order
          .group(by: \.customerID)
          .select { ($0.customerID, $0.amount.stddev()) }
          .having { $0.amount.stddev() > 10.0 }
      ) {
        """
        SELECT "orders"."customerID", stddev("orders"."amount")
        FROM "orders"
        GROUP BY "orders"."customerID"
        HAVING (stddev("orders"."amount")) > (10.0)
        """
      }
    }

    @Test("Variance with HAVING clause")
    func varianceWithHaving() async {
      await assertSQL(
        of:
          Order
          .group(by: \.customerID)
          .select { ($0.customerID, $0.amount.variance()) }
          .having { $0.amount.variance() > 100.0 }
      ) {
        """
        SELECT "orders"."customerID", variance("orders"."amount")
        FROM "orders"
        GROUP BY "orders"."customerID"
        HAVING (variance("orders"."amount")) > (100.0)
        """
      }
    }

    @Test("Stddev with ORDER BY")
    func stddevWithOrderBy() async {
      await assertSQL(
        of:
          Order
          .group(by: \.customerID)
          .order { $0.amount.stddev().desc() }
          .select { ($0.customerID, $0.amount.stddev()) }
      ) {
        """
        SELECT "orders"."customerID", stddev("orders"."amount")
        FROM "orders"
        GROUP BY "orders"."customerID"
        ORDER BY stddev("orders"."amount") DESC
        """
      }
    }

    @Test("Stddev with multiple GROUP BY columns")
    func stddevWithMultipleGroupBy() async {
      await assertSQL(
        of:
          Order
          .group(by: \.customerID)
          .group(by: \.isPaid)
          .select { ($0.customerID, $0.isPaid, $0.amount.stddev()) }
      ) {
        """
        SELECT "orders"."customerID", "orders"."isPaid", stddev("orders"."amount")
        FROM "orders"
        GROUP BY "orders"."customerID", "orders"."isPaid"
        """
      }
    }

  }
}
