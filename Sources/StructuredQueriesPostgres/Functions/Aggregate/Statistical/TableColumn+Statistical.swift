import Foundation
import StructuredQueriesCore

// MARK: - PostgreSQL Statistical Aggregate Functions

extension TableColumn where Value: Numeric {
    /// PostgreSQL STDDEV function - standard deviation
    ///
    /// ```swift
    /// Measurement.select { $0.value.stddev() }
    /// // SELECT stddev("measurements"."value") FROM "measurements"
    ///
    /// Measurement.select { $0.value.stddev(filter: $0.isValid) }
    /// // SELECT stddev("measurements"."value") FILTER (WHERE "measurements"."is_valid") FROM "measurements"
    /// ```
    ///
    /// - Parameter filter: A FILTER clause to apply to the aggregation
    /// - Returns: The standard deviation of this expression
    public func stddev(
        filter: (some QueryExpression<Bool>)? = Bool?.none
    ) -> some QueryExpression<Double> {
        AggregateFunction<Double>(
            "stddev",
            [queryFragment],
            filter: filter?.queryFragment
        )
    }

    /// PostgreSQL STDDEV_POP function - population standard deviation
    ///
    /// ```swift
    /// Measurement.select { $0.value.stddevPop() }
    /// // SELECT stddev_pop("measurements"."value") FROM "measurements"
    ///
    /// Measurement.select { $0.value.stddevPop(filter: $0.isValid) }
    /// // SELECT stddev_pop("measurements"."value") FILTER (WHERE "measurements"."is_valid") FROM "measurements"
    /// ```
    ///
    /// - Parameter filter: A FILTER clause to apply to the aggregation
    /// - Returns: The population standard deviation of this expression
    public func stddevPop(
        filter: (some QueryExpression<Bool>)? = Bool?.none
    ) -> some QueryExpression<Double> {
        AggregateFunction<Double>(
            "stddev_pop",
            [queryFragment],
            filter: filter?.queryFragment
        )
    }

    /// PostgreSQL STDDEV_SAMP function - sample standard deviation
    ///
    /// ```swift
    /// Measurement.select { $0.value.stddevSamp() }
    /// // SELECT stddev_samp("measurements"."value") FROM "measurements"
    ///
    /// Measurement.select { $0.value.stddevSamp(filter: $0.isValid) }
    /// // SELECT stddev_samp("measurements"."value") FILTER (WHERE "measurements"."is_valid") FROM "measurements"
    /// ```
    ///
    /// - Parameter filter: A FILTER clause to apply to the aggregation
    /// - Returns: The sample standard deviation of this expression
    public func stddevSamp(
        filter: (some QueryExpression<Bool>)? = Bool?.none
    ) -> some QueryExpression<Double> {
        AggregateFunction<Double>(
            "stddev_samp",
            [queryFragment],
            filter: filter?.queryFragment
        )
    }

    /// PostgreSQL VARIANCE function - variance
    ///
    /// ```swift
    /// Measurement.select { $0.value.variance() }
    /// // SELECT variance("measurements"."value") FROM "measurements"
    ///
    /// Measurement.select { $0.value.variance(filter: $0.isValid) }
    /// // SELECT variance("measurements"."value") FILTER (WHERE "measurements"."is_valid") FROM "measurements"
    /// ```
    ///
    /// - Parameter filter: A FILTER clause to apply to the aggregation
    /// - Returns: The variance of this expression
    public func variance(
        filter: (some QueryExpression<Bool>)? = Bool?.none
    ) -> some QueryExpression<Double> {
        AggregateFunction<Double>(
            "variance",
            [queryFragment],
            filter: filter?.queryFragment
        )
    }
}
