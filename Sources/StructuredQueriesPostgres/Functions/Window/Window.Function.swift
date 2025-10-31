import Foundation
import StructuredQueriesCore

// MARK: - Window Function Builder

extension Window {
  /// Builder for window functions that allows fluent OVER clause construction
  ///
  /// This type is returned by window function constructors and allows you to
  /// specify the OVER clause using a type-safe builder pattern.
  ///
  /// ## Usage
  ///
  /// ```swift
  /// // With OVER clause
  /// rowNumber().over { $0.order(by: $0.createdAt) }
  ///
  /// // Empty OVER clause
  /// rank().over()
  ///
  /// // Named window reference
  /// denseRank().over("my_window")
  /// ```
  public struct Function<Value: QueryBindable>: QueryExpression {
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
    /// rowNumber().over()
    /// // ROW_NUMBER() OVER ()
    /// ```
    public func over() -> some QueryExpression<Value> {
      var copy = self
      copy.windowSpec = WindowSpec()
      return Window.Base<Value>(
        functionName: copy.functionName,
        arguments: copy.arguments,
        windowSpec: copy.windowSpec
      )
    }

    /// Apply an OVER clause with custom window specification
    ///
    /// ```swift
    /// rank().over {
    ///     $0.partition(by: category)
    ///       .order(by: price.desc())
    /// }
    /// // RANK() OVER (PARTITION BY "category" ORDER BY "price" DESC)
    /// ```
    ///
    /// - Parameter builder: Closure that configures the window specification
    public func over(_ builder: (WindowSpec) -> WindowSpec) -> some QueryExpression<Value> {
      var copy = self
      copy.windowSpec = builder(WindowSpec())
      return Window.Base<Value>(
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
    ///     .window("dept_window") { $0.partition(by: $0.department).order(by: $0.salary.desc()) }
    ///     .select {
    ///         ($0.name, rank().over("dept_window"))
    ///     }
    /// // SELECT name, RANK() OVER dept_window
    /// // FROM employees
    /// // WINDOW dept_window AS (PARTITION BY department ORDER BY salary DESC)
    /// ```
    ///
    /// - Parameter windowName: The name of the window specification to reference
    /// - Returns: A query expression using the named window
    public func over(_ windowName: String) -> some QueryExpression<Value> {
      Window.Named<Value>(
        functionName: functionName,
        arguments: arguments,
        windowName: windowName
      )
    }

    public var queryFragment: QueryFragment {
      Window.Base<Value>(
        functionName: functionName,
        arguments: arguments,
        windowSpec: windowSpec
      ).queryFragment
    }
  }
}
