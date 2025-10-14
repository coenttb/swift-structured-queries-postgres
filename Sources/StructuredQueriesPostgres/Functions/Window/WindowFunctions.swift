import Foundation
import StructuredQueriesCore

// MARK: - Window Function Protocol

/// Protocol for window functions that can use OVER clauses
public protocol WindowFunction: QueryExpression where QueryValue: QueryBindable {
    /// The function name (e.g., "ROW_NUMBER", "RANK")
    var functionName: String { get }

    /// Optional arguments to the function
    var arguments: [QueryFragment] { get }
}

// MARK: - Window Function Base Implementation

/// Base implementation for all window functions
struct BaseWindowFunction<Value: QueryBindable>: QueryExpression {
    typealias QueryValue = Value

    let functionName: String
    let arguments: [QueryFragment]
    let windowSpec: WindowSpec?

    var queryFragment: QueryFragment {
        var fragment: QueryFragment = "\(raw: functionName)("
        if !arguments.isEmpty {
            fragment.append(arguments.joined(separator: ", "))
        }
        fragment.append(")")

        if let windowSpec {
            fragment.append(" ")
            fragment.append(windowSpec.generateOverClause())
        } else {
            fragment.append(" OVER ()")
        }

        return fragment
    }
}

// MARK: - Ranking Window Functions

/// PostgreSQL `ROW_NUMBER()` window function
///
/// Assigns a unique sequential number to each row within the window partition.
///
/// ```swift
/// User.select {
///     let createdAt = $0.createdAt
///     return ($0, rowNumber().over { $0.order(by: createdAt) })
/// }
/// // SELECT *, ROW_NUMBER() OVER (ORDER BY "created_at")
/// ```
///
/// - Returns: An integer expression with the row number
public func rowNumber() -> WindowFunctionBuilder<Int> {
    WindowFunctionBuilder(functionName: "ROW_NUMBER", arguments: [])
}

/// PostgreSQL `RANK()` window function
///
/// Assigns a rank to each row within the partition, with gaps for tied values.
/// Tied rows receive the same rank, and the next rank skips numbers.
///
/// ```swift
/// // Leaderboard with gaps for ties
/// Score.select {
///     let points = $0.points
///     return ($0, rank().over { $0.order(by: points, .desc) })
/// }
/// // Ranks: 1, 2, 2, 4, 5 (gap at 3)
/// ```
///
/// - Returns: A rank expression (bigint)
public func rank() -> WindowFunctionBuilder<Int> {
    WindowFunctionBuilder(functionName: "RANK", arguments: [])
}

/// PostgreSQL `DENSE_RANK()` window function
///
/// Assigns a rank to each row within the partition, without gaps for tied values.
/// Tied rows receive the same rank, and the next rank continues sequentially.
///
/// ```swift
/// // Leaderboard without gaps
/// Score.select {
///     let points = $0.points
///     return ($0, denseRank().over { $0.order(by: points, .desc) })
/// }
/// // Ranks: 1, 2, 2, 3, 4 (no gap)
/// ```
///
/// - Returns: A dense rank expression (bigint)
public func denseRank() -> WindowFunctionBuilder<Int> {
    WindowFunctionBuilder(functionName: "DENSE_RANK", arguments: [])
}

/// PostgreSQL `PERCENT_RANK()` window function
///
/// Calculates the relative rank of the current row: `(rank - 1) / (total rows - 1)`.
/// Returns a value between 0 and 1.
///
/// ```swift
/// Score.select {
///     let points = $0.points
///     return ($0, percentRank().over { $0.order(by: points, .desc) })
/// }
/// // Returns: 0.0, 0.25, 0.5, 0.75, 1.0
/// ```
///
/// - Returns: A double precision expression
public func percentRank() -> WindowFunctionBuilder<Double> {
    WindowFunctionBuilder(functionName: "PERCENT_RANK", arguments: [])
}

/// PostgreSQL `CUME_DIST()` window function
///
/// Calculates the cumulative distribution: (number of partition rows ≤ current row) / (total partition rows).
/// Returns a value between 0 and 1.
///
/// ```swift
/// Score.select {
///     let points = $0.points
///     return ($0, cumeDist().over { $0.order(by: points, .desc) })
/// }
/// ```
///
/// - Returns: A double precision expression
public func cumeDist() -> WindowFunctionBuilder<Double> {
    WindowFunctionBuilder(functionName: "CUME_DIST", arguments: [])
}

/// PostgreSQL `NTILE(n)` window function
///
/// Divides the partition into `n` buckets and assigns each row a bucket number (1 to n).
/// Useful for creating percentiles or quartiles.
///
/// ```swift
/// // Divide into quartiles
/// User.select {
///     let age = $0.age
///     return ($0, ntile(4).over { $0.order(by: age) })
/// }
/// // Returns: 1, 1, 2, 2, 3, 3, 4, 4
/// ```
///
/// - Parameter buckets: Number of buckets (must be positive)
/// - Returns: An integer expression (1 to n)
public func ntile(_ buckets: Int) -> WindowFunctionBuilder<Int> {
    precondition(buckets > 0, "ntile buckets must be positive")
    return WindowFunctionBuilder(
        functionName: "NTILE",
        arguments: [QueryFragment(stringLiteral: "\(buckets)")]
    )
}

// MARK: - Value Access Window Functions

extension QueryExpression {
    /// PostgreSQL `LAG()` window function
    ///
    /// Accesses the value from a row that is `offset` rows before the current row.
    /// Returns the default value if the offset points to a row outside the partition.
    ///
    /// ```swift
    /// // Compare with previous day's price
    /// StockPrice.select {
    ///     let price = $0.price
    ///     let date = $0.date
    ///     return ($0, price.lag(offset: 1, default: 0).over { $0.order(by: date) })
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - offset: Number of rows to look back (default: 1)
    ///   - default: Default value when offset goes out of bounds
    /// - Returns: The lagged value expression
    public func lag(
        offset: Int = 1,
        default defaultValue: QueryValue? = nil
    ) -> WindowFunctionBuilder<QueryValue?> where QueryValue: QueryBindable {
        var args: [QueryFragment] = [self.queryFragment, QueryFragment(stringLiteral: "\(offset)")]
        if let defaultValue {
            args.append("\(bind: defaultValue)")
        }
        return WindowFunctionBuilder(functionName: "LAG", arguments: args)
    }

    /// PostgreSQL `LEAD()` window function
    ///
    /// Accesses the value from a row that is `offset` rows after the current row.
    /// Returns the default value if the offset points to a row outside the partition.
    ///
    /// ```swift
    /// // Compare with next day's price
    /// StockPrice.select {
    ///     let price = $0.price
    ///     let date = $0.date
    ///     return ($0, price.lead(offset: 1, default: 0).over { $0.order(by: date) })
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - offset: Number of rows to look ahead (default: 1)
    ///   - default: Default value when offset goes out of bounds
    /// - Returns: The lead value expression
    public func lead(
        offset: Int = 1,
        default defaultValue: QueryValue? = nil
    ) -> WindowFunctionBuilder<QueryValue?> where QueryValue: QueryBindable {
        var args: [QueryFragment] = [self.queryFragment, QueryFragment(stringLiteral: "\(offset)")]
        if let defaultValue {
            args.append("\(bind: defaultValue)")
        }
        return WindowFunctionBuilder(functionName: "LEAD", arguments: args)
    }

    /// PostgreSQL `FIRST_VALUE()` window function
    ///
    /// Returns the value from the first row of the window frame.
    ///
    /// ```swift
    /// // Show highest price in each category
    /// Product.select {
    ///     let category = $0.category
    ///     let price = $0.price
    ///     return ($0, price.firstValue().over {
    ///         $0.partition(by: category)
    ///           .order(by: price, .desc)
    ///     })
    /// }
    /// ```
    ///
    /// - Returns: The first value in the frame
    public func firstValue() -> WindowFunctionBuilder<QueryValue> where QueryValue: QueryBindable {
        WindowFunctionBuilder(functionName: "FIRST_VALUE", arguments: [self.queryFragment])
    }

    /// PostgreSQL `LAST_VALUE()` window function
    ///
    /// Returns the value from the last row of the window frame.
    ///
    /// **Note:** Default frame is `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`,
    /// so you often need to specify a frame to get the actual last value in the partition.
    ///
    /// ```swift
    /// // Get last value in partition
    /// Product.select {
    ///     let category = $0.category
    ///     let price = $0.price
    ///     return ($0, price.lastValue().over {
    ///         $0.partition(by: category)
    ///           .order(by: price, .desc)
    ///     })
    /// }
    /// ```
    ///
    /// - Returns: The last value in the frame
    public func lastValue() -> WindowFunctionBuilder<QueryValue> where QueryValue: QueryBindable {
        WindowFunctionBuilder(functionName: "LAST_VALUE", arguments: [self.queryFragment])
    }

    /// PostgreSQL `NTH_VALUE()` window function
    ///
    /// Returns the value from the nth row of the window frame (1-indexed).
    ///
    /// ```swift
    /// // Get second-highest price in each category
    /// Product.select {
    ///     let category = $0.category
    ///     let price = $0.price
    ///     return ($0, price.nthValue(2).over {
    ///         $0.partition(by: category)
    ///           .order(by: price, .desc)
    ///     })
    /// }
    /// ```
    ///
    /// - Parameter n: Row number (1-indexed, must be positive)
    /// - Returns: The nth value in the frame
    public func nthValue(_ n: Int) -> WindowFunctionBuilder<QueryValue?>
    where QueryValue: QueryBindable {
        precondition(n > 0, "nth value position must be positive (1-indexed)")
        return WindowFunctionBuilder(
            functionName: "NTH_VALUE",
            arguments: [self.queryFragment, QueryFragment(stringLiteral: "\(n)")]
        )
    }
}

// MARK: - Window Function Builder

/// Builder for window functions that allows fluent OVER clause construction
///
/// This type is returned by window function constructors and allows you to
/// specify the OVER clause using a type-safe builder pattern.
public struct WindowFunctionBuilder<Value: QueryBindable>: QueryExpression {
    public typealias QueryValue = Value

    let functionName: String
    let arguments: [QueryFragment]
    var windowSpec: WindowSpec?

    init(functionName: String, arguments: [QueryFragment]) {
        self.functionName = functionName
        self.arguments = arguments
        self.windowSpec = nil
    }

    /// Apply an OVER clause with no partitioning or ordering
    ///
    /// ```swift
    /// .rowNumber().over()
    /// // ROW_NUMBER() OVER ()
    /// ```
    public func over() -> some QueryExpression<Value> {
        var copy = self
        copy.windowSpec = WindowSpec()
        return BaseWindowFunction<Value>(
            functionName: copy.functionName,
            arguments: copy.arguments,
            windowSpec: copy.windowSpec
        )
    }

    /// Apply an OVER clause with custom window specification
    ///
    /// ```swift
    /// .rank().over {
    ///     $0.partition(by: category)
    ///       .order(by: price, .desc)
    /// }
    /// // RANK() OVER (PARTITION BY "category" ORDER BY "price" DESC)
    /// ```
    ///
    /// - Parameter builder: Closure that configures the window specification
    public func over(_ builder: (WindowSpec) -> WindowSpec) -> some QueryExpression<Value> {
        var copy = self
        copy.windowSpec = builder(WindowSpec())
        return BaseWindowFunction<Value>(
            functionName: copy.functionName,
            arguments: copy.arguments,
            windowSpec: copy.windowSpec
        )
    }

    /// Apply an OVER clause referencing a named window
    ///
    /// References a window specification defined in the query's WINDOW clause.
    ///
    /// ```swift
    /// Employee
    ///     .window("dept_window") { $0.partition(by: $0.department).order(by: $0.salary, .desc) }
    ///     .select {
    ///         ($0.name, $0.salary.rank().over("dept_window"))
    ///     }
    /// // SELECT name, RANK() OVER dept_window
    /// // FROM employees
    /// // WINDOW dept_window AS (PARTITION BY department ORDER BY salary DESC)
    /// ```
    ///
    /// - Parameter windowName: The name of the window specification to reference
    /// - Returns: A query expression using the named window
    public func over(_ windowName: String) -> some QueryExpression<Value> {
        NamedWindowFunction<Value>(
            functionName: functionName,
            arguments: arguments,
            windowName: windowName
        )
    }

    public var queryFragment: QueryFragment {
        BaseWindowFunction<Value>(
            functionName: functionName,
            arguments: arguments,
            windowSpec: windowSpec
        ).queryFragment
    }
}

// MARK: - Named Window Function

/// A window function that references a named window specification
struct NamedWindowFunction<Value: QueryBindable>: QueryExpression {
    typealias QueryValue = Value

    let functionName: String
    let arguments: [QueryFragment]
    let windowName: String

    var queryFragment: QueryFragment {
        var fragment: QueryFragment = "\(raw: functionName)("
        if !arguments.isEmpty {
            fragment.append(arguments.joined(separator: ", "))
        }
        fragment.append(")")
        fragment.append(" OVER \(raw: windowName)")
        return fragment
    }
}
