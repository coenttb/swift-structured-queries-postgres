import Foundation
import StructuredQueriesCore

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
  ) -> Window.Function<QueryValue?> where QueryValue: QueryBindable {
    var args: [QueryFragment] = [self.queryFragment, QueryFragment(stringLiteral: "\(offset)")]
    if let defaultValue {
      args.append("\(bind: defaultValue)")
    }
    return Window.Function(functionName: "LAG", arguments: args)
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
  ) -> Window.Function<QueryValue?> where QueryValue: QueryBindable {
    var args: [QueryFragment] = [self.queryFragment, QueryFragment(stringLiteral: "\(offset)")]
    if let defaultValue {
      args.append("\(bind: defaultValue)")
    }
    return Window.Function(functionName: "LEAD", arguments: args)
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
  ///           .order(by: price.desc())
  ///     })
  /// }
  /// ```
  ///
  /// - Returns: The first value in the frame
  public func firstValue() -> Window.Function<QueryValue> where QueryValue: QueryBindable {
    Window.Function(functionName: "FIRST_VALUE", arguments: [self.queryFragment])
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
  ///           .order(by: price.desc())
  ///     })
  /// }
  /// ```
  ///
  /// - Returns: The last value in the frame
  public func lastValue() -> Window.Function<QueryValue> where QueryValue: QueryBindable {
    Window.Function(functionName: "LAST_VALUE", arguments: [self.queryFragment])
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
  ///           .order(by: price.desc())
  ///     })
  /// }
  /// ```
  ///
  /// - Parameter n: Row number (1-indexed, must be positive)
  /// - Returns: The nth value in the frame
  public func nthValue(_ n: Int) -> Window.Function<QueryValue?>
  where QueryValue: QueryBindable {
    precondition(n > 0, "nth value position must be positive (1-indexed)")
    return Window.Function(
      functionName: "NTH_VALUE",
      arguments: [self.queryFragment, QueryFragment(stringLiteral: "\(n)")]
    )
  }
}
