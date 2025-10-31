import Foundation

// MARK: - Core Query Function Infrastructure
//
// Generic wrappers for SQL function calls.
// These are part of the core DSL infrastructure.

/// A query expression of a generalized query function.
///
/// This struct provides a generic way to wrap any SQL function call.
/// Use this for functions that follow the pattern: `function_name(arg1, arg2, ...)`
///
/// ```swift
/// QueryFunction("upper", $0.name)
/// // SELECT upper("users"."name") FROM "users"
/// ```
public struct QueryFunction<QueryValue>: QueryExpression {
  let name: QueryFragment
  let arguments: [QueryFragment]

  package init<each Argument: QueryExpression>(
    _ name: QueryFragment,
    _ arguments: repeat each Argument
  ) {
    self.name = name
    self.arguments = Array(repeat each arguments)
  }

  public var queryFragment: QueryFragment {
    "\(name)(\(arguments.joined(separator: ", ")))"
  }
}
