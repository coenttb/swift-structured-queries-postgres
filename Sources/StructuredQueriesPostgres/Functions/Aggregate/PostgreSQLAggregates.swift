import Foundation
import StructuredQueriesCore

// MARK: - PostgreSQL-specific Aggregate Functions

extension TableColumn {
    /// PostgreSQL STRING_AGG function - concatenates strings with a separator
    /// Equivalent to SQLite's GROUP_CONCAT
    ///
    /// ```swift
    /// User.select { $0.name.stringAgg(", ") }
    /// // SELECT string_agg("users"."name", ', ') FROM "users"
    /// ```
    public func stringAgg(_ separator: String) -> some QueryExpression<String?> {
        SimpleAggregateFunction<String?>(
            name: "string_agg",
            column: queryFragment,
            separator: separator.queryFragment
        )
    }

    /// PostgreSQL ARRAY_AGG function - aggregates values into an array
    ///
    /// ```swift
    /// User.select { $0.id.arrayAgg() }
    /// // SELECT array_agg("users"."id") FROM "users"
    /// ```
    public func arrayAgg() -> some QueryExpression<String?> {
        SimpleAggregateFunction<String?>(
            name: "array_agg",
            column: queryFragment
        )
    }

    /// PostgreSQL JSON_AGG function - aggregates values into a JSON array
    ///
    /// ```swift
    /// User.select { $0.name.jsonAgg() }
    /// // SELECT json_agg("users"."name") FROM "users"
    /// ```
    public func jsonAgg() -> some QueryExpression<String?> {
        SimpleAggregateFunction<String?>(
            name: "json_agg",
            column: queryFragment
        )
    }

    /// PostgreSQL JSONB_AGG function - aggregates values into a JSONB array
    ///
    /// ```swift
    /// User.select { $0.name.jsonbAgg() }
    /// // SELECT jsonb_agg("users"."name") FROM "users"
    /// ```
    public func jsonbAgg() -> some QueryExpression<String?> {
        SimpleAggregateFunction<String?>(
            name: "jsonb_agg",
            column: queryFragment
        )
    }
}

// MARK: - Statistical Functions

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

// MARK: - Simple aggregate function helper

private struct SimpleAggregateFunction<QueryValue: QueryBindable>: QueryExpression {
    let name: String
    let column: QueryFragment
    let separator: QueryFragment?

    init(name: String, column: QueryFragment, separator: QueryFragment? = nil) {
        self.name = name
        self.column = column
        self.separator = separator
    }

    var queryFragment: QueryFragment {
        if let separator = separator {
            // For functions like string_agg that take two arguments
            return "\(QueryFragment(stringLiteral: name))(\(column), \(separator))"
        } else {
            // For single-argument aggregate functions
            return "\(QueryFragment(stringLiteral: name))(\(column))"
        }
    }
}
