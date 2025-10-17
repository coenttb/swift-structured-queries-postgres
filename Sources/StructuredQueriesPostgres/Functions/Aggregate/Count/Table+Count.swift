import StructuredQueriesCore

extension Table {
    /// A select statement for this table's row count.
    ///
    /// ```swift
    /// Order.count()
    /// // SELECT count(*) FROM "orders"
    ///
    /// Order.count(filter: { $0.isPaid })
    /// // SELECT count(*) FILTER (WHERE "orders"."isPaid") FROM "orders"
    /// ```
    ///
    /// - Parameter filter: A `FILTER` clause to apply to the aggregation.
    /// - Returns: A select statement that selects `count(*)`.
    public static func count(
        filter: ((TableColumns) -> some QueryExpression<Bool>)? = nil
    ) -> Select<Int, Self, ()> {
        Self.all
            .asSelect()
            .select { _ in
                    .count(filter: filter?(columns))
            }
    }
}
