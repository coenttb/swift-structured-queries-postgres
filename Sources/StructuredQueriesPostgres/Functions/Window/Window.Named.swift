import Foundation
import StructuredQueriesCore

// MARK: - Named Window Function

extension Window {
  /// A window function that references a named window specification
  ///
  /// This internal type is used when a window function references a named window
  /// defined in the query's WINDOW clause.
  ///
  /// ```swift
  /// Employee
  ///     .window("dept_window") { $0.partition(by: $0.department) }
  ///     .select { rank().over("dept_window") }
  /// // RANK() OVER dept_window
  /// ```
  struct Named<Value: QueryBindable>: QueryExpression {
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
}
