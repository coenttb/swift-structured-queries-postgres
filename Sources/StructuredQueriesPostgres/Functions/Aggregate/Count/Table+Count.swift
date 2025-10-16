import StructuredQueriesCore

extension Table {
    /// A select statement for this table's row count.
    ///
    /// - Parameter filter: A `FILTER` clause to apply to the aggregation.
    /// - Returns: A select statement that selects `count(*)`.
    public static func count(
        filter: ((TableColumns) -> some QueryExpression<Bool>)? = nil
    ) -> Select<Int, Self, ()> {
        Where().count(filter: filter)
    }
}
