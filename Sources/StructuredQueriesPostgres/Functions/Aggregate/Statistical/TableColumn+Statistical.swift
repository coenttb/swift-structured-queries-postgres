import Foundation
import StructuredQueriesCore

// MARK: - PostgreSQL Statistical Aggregate Functions

extension TableColumn where Value: Numeric {
    /// PostgreSQL STDDEV function - standard deviation
    ///
    /// ```swift
    /// Measurement.select { $0.value.stddev() }
    /// // SELECT stddev("measurements"."value") FROM "measurements"
    /// ```
    public func stddev() -> some QueryExpression<Double> {
        SimpleAggregateFunction<Double>(
            name: "stddev",
            column: queryFragment
        )
    }

    /// PostgreSQL STDDEV_POP function - population standard deviation
    ///
    /// ```swift
    /// Measurement.select { $0.value.stddevPop() }
    /// // SELECT stddev_pop("measurements"."value") FROM "measurements"
    /// ```
    public func stddevPop() -> some QueryExpression<Double> {
        SimpleAggregateFunction<Double>(
            name: "stddev_pop",
            column: queryFragment
        )
    }

    /// PostgreSQL STDDEV_SAMP function - sample standard deviation
    ///
    /// ```swift
    /// Measurement.select { $0.value.stddevSamp() }
    /// // SELECT stddev_samp("measurements"."value") FROM "measurements"
    /// ```
    public func stddevSamp() -> some QueryExpression<Double> {
        SimpleAggregateFunction<Double>(
            name: "stddev_samp",
            column: queryFragment
        )
    }

    /// PostgreSQL VARIANCE function - variance
    ///
    /// ```swift
    /// Measurement.select { $0.value.variance() }
    /// // SELECT variance("measurements"."value") FROM "measurements"
    /// ```
    public func variance() -> some QueryExpression<Double> {
        SimpleAggregateFunction<Double>(
            name: "variance",
            column: queryFragment
        )
    }
}
