import StructuredQueriesCore

extension Where {
    /// Computes the standard deviation of a numeric column for rows matching the WHERE clause.
    ///
    /// ```swift
    /// Measurement.where { $0.isValid }.stddev { $0.value }
    /// // SELECT STDDEV("measurements"."value") FROM "measurements" WHERE "measurements"."is_valid"
    /// ```
    ///
    /// - Parameter expression: A closure that returns the column to compute standard deviation for.
    /// - Returns: A select statement that returns the standard deviation as `Double?`.
    @inlinable
    public func stddev(
        of expression: (From.TableColumns) -> some QueryExpression<some Numeric>
    ) -> Select<Double?, From, ()> {
        _aggregateSelect(of: expression) { $0.stddev() }
    }

    /// Computes the standard deviation with a filter for rows matching the WHERE clause.
    ///
    /// ```swift
    /// Measurement.where { $0.createdAt > date }.stddev(of: { $0.value }, filter: { $0.isValid })
    /// // SELECT STDDEV("measurements"."value") FILTER (WHERE "measurements"."is_valid") FROM "measurements" WHERE ...
    /// ```
    ///
    /// - Parameters:
    ///   - expression: A closure that returns the column to compute standard deviation for.
    ///   - filter: A FILTER clause to apply to the aggregation.
    /// - Returns: A select statement that returns the standard deviation as `Double?`.
    @inlinable
    public func stddev<Filter: QueryExpression<Bool>>(
        of expression: (From.TableColumns) -> some QueryExpression<some Numeric>,
        filter: @escaping (From.TableColumns) -> Filter
    ) -> Select<Double?, From, ()> {
        _aggregateSelect(of: expression, filter: filter) { $0.stddev(filter: $1) }
    }

    /// Computes the variance of a numeric column for rows matching the WHERE clause.
    ///
    /// ```swift
    /// Measurement.where { $0.isValid }.variance { $0.value }
    /// // SELECT VARIANCE("measurements"."value") FROM "measurements" WHERE "measurements"."is_valid"
    /// ```
    ///
    /// - Parameter expression: A closure that returns the column to compute variance for.
    /// - Returns: A select statement that returns the variance as `Double?`.
    @inlinable
    public func variance(
        of expression: (From.TableColumns) -> some QueryExpression<some Numeric>
    ) -> Select<Double?, From, ()> {
        _aggregateSelect(of: expression) { $0.variance() }
    }

    /// Computes the variance with a filter for rows matching the WHERE clause.
    ///
    /// ```swift
    /// Measurement.where { $0.createdAt > date }.variance(of: { $0.value }, filter: { $0.isValid })
    /// // SELECT VARIANCE("measurements"."value") FILTER (WHERE "measurements"."is_valid") FROM "measurements" WHERE ...
    /// ```
    ///
    /// - Parameters:
    ///   - expression: A closure that returns the column to compute variance for.
    ///   - filter: A FILTER clause to apply to the aggregation.
    /// - Returns: A select statement that returns the variance as `Double?`.
    @inlinable
    public func variance<Filter: QueryExpression<Bool>>(
        of expression: (From.TableColumns) -> some QueryExpression<some Numeric>,
        filter: @escaping (From.TableColumns) -> Filter
    ) -> Select<Double?, From, ()> {
        _aggregateSelect(of: expression, filter: filter) { $0.variance(filter: $1) }
    }
}
