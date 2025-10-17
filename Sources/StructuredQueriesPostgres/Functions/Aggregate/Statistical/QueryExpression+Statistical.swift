import Foundation
import StructuredQueriesCore

// MARK: - PostgreSQL Statistical Aggregate Functions

extension QueryExpression where QueryValue: Numeric {
    /// PostgreSQL STDDEV function - standard deviation
    ///
    /// ```swift
    /// Measurement.select { $0.value.stddev() }
    /// // SELECT STDDEV("measurements"."value") FROM "measurements"
    ///
    /// Measurement.select { $0.value.stddev(filter: $0.isValid) }
    /// // SELECT STDDEV("measurements"."value") FILTER (WHERE "measurements"."is_valid") FROM "measurements"
    /// ```
    ///
    /// - Parameter filter: A FILTER clause to apply to the aggregation
    /// - Returns: The standard deviation of this expression
    public func stddev(
        filter: (some QueryExpression<Bool>)? = Bool?.none
    ) -> some QueryExpression<Double?> {
        AggregateFunction<Double?>(
            "STDDEV",
            [queryFragment],
            filter: filter?.queryFragment
        )
    }

    /// PostgreSQL STDDEV_POP function - population standard deviation
    ///
    /// ```swift
    /// Measurement.select { $0.value.stddevPop() }
    /// // SELECT STDDEV_POP("measurements"."value") FROM "measurements"
    ///
    /// Measurement.select { $0.value.stddevPop(filter: $0.isValid) }
    /// // SELECT STDDEV_POP("measurements"."value") FILTER (WHERE "measurements"."is_valid") FROM "measurements"
    /// ```
    ///
    /// - Parameter filter: A FILTER clause to apply to the aggregation
    /// - Returns: The population standard deviation of this expression
    public func stddevPop(
        filter: (some QueryExpression<Bool>)? = Bool?.none
    ) -> some QueryExpression<Double?> {
        AggregateFunction<Double?>(
            "STDDEV_POP",
            [queryFragment],
            filter: filter?.queryFragment
        )
    }

    /// PostgreSQL STDDEV_SAMP function - sample standard deviation
    ///
    /// ```swift
    /// Measurement.select { $0.value.stddevSamp() }
    /// // SELECT STDDEV_SAMP("measurements"."value") FROM "measurements"
    ///
    /// Measurement.select { $0.value.stddevSamp(filter: $0.isValid) }
    /// // SELECT STDDEV_SAMP("measurements"."value") FILTER (WHERE "measurements"."is_valid") FROM "measurements"
    /// ```
    ///
    /// - Parameter filter: A FILTER clause to apply to the aggregation
    /// - Returns: The sample standard deviation of this expression
    public func stddevSamp(
        filter: (some QueryExpression<Bool>)? = Bool?.none
    ) -> some QueryExpression<Double?> {
        AggregateFunction<Double?>(
            "STDDEV_SAMP",
            [queryFragment],
            filter: filter?.queryFragment
        )
    }

    /// PostgreSQL VARIANCE function - variance
    ///
    /// ```swift
    /// Measurement.select { $0.value.variance() }
    /// // SELECT VARIANCE("measurements"."value") FROM "measurements"
    ///
    /// Measurement.select { $0.value.variance(filter: $0.isValid) }
    /// // SELECT VARIANCE("measurements"."value") FILTER (WHERE "measurements"."is_valid") FROM "measurements"
    /// ```
    ///
    /// - Parameter filter: A FILTER clause to apply to the aggregation
    /// - Returns: The variance of this expression
    public func variance(
        filter: (some QueryExpression<Bool>)? = Bool?.none
    ) -> some QueryExpression<Double?> {
        AggregateFunction<Double?>(
            "VARIANCE",
            [queryFragment],
            filter: filter?.queryFragment
        )
    }

    /// PostgreSQL VAR_POP function - population variance
    ///
    /// ```swift
    /// Measurement.select { $0.value.varPop() }
    /// // SELECT VAR_POP("measurements"."value") FROM "measurements"
    /// ```
    ///
    /// - Parameter filter: A FILTER clause to apply to the aggregation
    /// - Returns: The population variance of this expression
    public func varPop(
        filter: (some QueryExpression<Bool>)? = Bool?.none
    ) -> some QueryExpression<Double?> {
        AggregateFunction<Double?>(
            "VAR_POP",
            [queryFragment],
            filter: filter?.queryFragment
        )
    }

    /// PostgreSQL VAR_SAMP function - sample variance
    ///
    /// ```swift
    /// Measurement.select { $0.value.varSamp() }
    /// // SELECT VAR_SAMP("measurements"."value") FROM "measurements"
    /// ```
    ///
    /// - Parameter filter: A FILTER clause to apply to the aggregation
    /// - Returns: The sample variance of this expression
    public func varSamp(
        filter: (some QueryExpression<Bool>)? = Bool?.none
    ) -> some QueryExpression<Double?> {
        AggregateFunction<Double?>(
            "VAR_SAMP",
            [queryFragment],
            filter: filter?.queryFragment
        )
    }
}
