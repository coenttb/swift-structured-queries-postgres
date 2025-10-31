import StructuredQueriesCore

/// Wraps a select statement with a materialization hint for use in CTEs.
///
/// This wrapper allows you to control PostgreSQL's CTE evaluation strategy
/// using the `MATERIALIZED` or `NOT MATERIALIZED` keywords.
///
/// Example:
/// ```swift
/// With {
///     ExpensiveQuery.all.materialized()  // Force materialization
/// } query: {
///     ExpensiveQuery.all
/// }
/// // SQL: WITH "expensiveQueries" AS MATERIALIZED (...)
/// ```
public struct MaterializedSelect<Base: PartialSelectStatement>: PartialSelectStatement {
  public typealias QueryValue = Base.QueryValue
  public typealias From = Base.From
  public typealias Joins = Base.Joins

  let base: Base
  let materialization: CTE.Clause.MaterializationHint

  public var query: QueryFragment { base.query }
}

extension PartialSelectStatement {
  /// Adds MATERIALIZED hint to force PostgreSQL to compute and store CTE results.
  ///
  /// Use when the CTE is referenced multiple times and is expensive to compute.
  /// PostgreSQL will compute the CTE once, store the results, and reuse them for
  /// each reference.
  ///
  /// **PostgreSQL 12+ only**
  ///
  /// Example:
  /// ```swift
  /// With {
  ///     Stats
  ///         .select { StatsAggregate.Columns(...) }
  ///         .materialized()
  /// } query: {
  ///     StatsAggregate.all
  ///         .union(all: true, StatsAggregate.all)  // Reuses materialized results
  /// }
  /// ```
  ///
  /// - Returns: A wrapped select statement with MATERIALIZED hint.
  public func materialized() -> MaterializedSelect<Self> {
    MaterializedSelect(base: self, materialization: .materialized)
  }

  /// Adds NOT MATERIALIZED hint to prevent PostgreSQL from materializing the CTE.
  ///
  /// Use when the CTE is a simple filter that can benefit from index usage.
  /// PostgreSQL will inline the CTE into the main query, allowing indexes
  /// on the underlying tables to be used.
  ///
  /// **PostgreSQL 12+ only**
  ///
  /// Example:
  /// ```swift
  /// With {
  ///     User.where { $0.id == 1 }.notMaterialized()
  /// } query: {
  ///     User.select(\.name)
  /// }
  /// ```
  ///
  /// - Returns: A wrapped select statement with NOT MATERIALIZED hint.
  public func notMaterialized() -> MaterializedSelect<Self> {
    MaterializedSelect(base: self, materialization: .notMaterialized)
  }
}
