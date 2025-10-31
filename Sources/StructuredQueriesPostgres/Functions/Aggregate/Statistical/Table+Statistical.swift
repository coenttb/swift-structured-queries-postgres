import StructuredQueriesCore

extension Table {
  /// Computes the standard deviation of a numeric column for the entire table.
  ///
  /// ```swift
  /// Measurement.stddev { $0.value }
  /// // SELECT STDDEV("measurements"."value") FROM "measurements"
  /// ```
  ///
  /// - Parameter expression: A closure that returns the column to compute standard deviation for.
  /// - Returns: A select statement that returns the standard deviation as `Double?`.
  @inlinable
  public static func stddev(
    of expression: (TableColumns) -> some QueryExpression<some Numeric>
  ) -> Select<Double?, Self, ()> {
    _aggregateSelect(of: expression) { $0.stddev() }
  }

  /// Computes the standard deviation with a filter for the entire table.
  ///
  /// ```swift
  /// Measurement.stddev(of: { $0.value }, filter: { $0.isValid })
  /// // SELECT STDDEV("measurements"."value") FILTER (WHERE "measurements"."is_valid") FROM "measurements"
  /// ```
  ///
  /// - Parameters:
  ///   - expression: A closure that returns the column to compute standard deviation for.
  ///   - filter: A FILTER clause to apply to the aggregation.
  /// - Returns: A select statement that returns the standard deviation as `Double?`.
  @inlinable
  public static func stddev<Filter: QueryExpression<Bool>>(
    of expression: (TableColumns) -> some QueryExpression<some Numeric>,
    filter: @escaping (TableColumns) -> Filter
  ) -> Select<Double?, Self, ()> {
    _aggregateSelect(of: expression, filter: filter) { $0.stddev(filter: $1) }
  }

  /// Computes the variance of a numeric column for the entire table.
  ///
  /// ```swift
  /// Measurement.variance { $0.value }
  /// // SELECT VARIANCE("measurements"."value") FROM "measurements"
  /// ```
  ///
  /// - Parameter expression: A closure that returns the column to compute variance for.
  /// - Returns: A select statement that returns the variance as `Double?`.
  @inlinable
  public static func variance(
    of expression: (TableColumns) -> some QueryExpression<some Numeric>
  ) -> Select<Double?, Self, ()> {
    _aggregateSelect(of: expression) { $0.variance() }
  }

  /// Computes the variance with a filter for the entire table.
  ///
  /// ```swift
  /// Measurement.variance(of: { $0.value }, filter: { $0.isValid })
  /// // SELECT VARIANCE("measurements"."value") FILTER (WHERE "measurements"."is_valid") FROM "measurements"
  /// ```
  ///
  /// - Parameters:
  ///   - expression: A closure that returns the column to compute variance for.
  ///   - filter: A FILTER clause to apply to the aggregation.
  /// - Returns: A select statement that returns the variance as `Double?`.
  @inlinable
  public static func variance<Filter: QueryExpression<Bool>>(
    of expression: (TableColumns) -> some QueryExpression<some Numeric>,
    filter: @escaping (TableColumns) -> Filter
  ) -> Select<Double?, Self, ()> {
    _aggregateSelect(of: expression, filter: filter) { $0.variance(filter: $1) }
  }
}
