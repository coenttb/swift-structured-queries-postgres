import Foundation
import StructuredQueriesCore

// MARK: - PostgreSQL COALESCE Function
//
// PostgreSQL Chapter 9.18: Conditional Expressions
// https://www.postgresql.org/docs/current/functions-conditional.html
//
// COALESCE returns the first non-NULL value from its arguments.

extension Conditional {
  /// A query expression of a COALESCE function.
  ///
  /// Represents PostgreSQL's `COALESCE` function which returns the first non-NULL value.
  /// This is used to implement Swift's `??` operator for query expressions.
  ///
  /// ```swift
  /// User.select { $0.nickname ?? $0.name }
  /// // SELECT coalesce("users"."nickname", "users"."name") FROM "users"
  /// ```
  public struct Coalesce<QueryValue>: QueryExpression {
    private let arguments: [QueryFragment]

    fileprivate init(_ arguments: [QueryFragment]) {
      self.arguments = arguments
    }

    public var queryFragment: QueryFragment {
      "coalesce(\(arguments.joined(separator: ", ")))"
    }

    public static func ?? <T: _OptionalProtocol<QueryValue>>(
      lhs: some QueryExpression<T>,
      rhs: Self
    ) -> Coalesce<QueryValue> {
      Self([lhs.queryFragment] + rhs.arguments)
    }
  }
}

extension Conditional.Coalesce where QueryValue: _OptionalProtocol {
  public static func ?? (
    lhs: some QueryExpression<QueryValue>,
    rhs: Self
  ) -> Self {
    Self([lhs.queryFragment] + rhs.arguments)
  }
}

// MARK: - NULL Handling Extensions

extension QueryExpression where QueryValue: _OptionalProtocol {
  /// Wraps this optional query expression with the `ifnull` function.
  ///
  /// PostgreSQL's `COALESCE` function (which `ifnull` maps to) returns the first non-NULL value.
  ///
  /// ```swift
  /// Reminder
  ///   .select { $0.dueDate.ifnull(#sql("date()")) }
  /// // SELECT ifnull("reminders"."dueDate", date())
  /// // FROM "reminders"
  /// ```
  ///
  /// - Parameter other: A non-optional fallback value
  /// - Returns: A non-optional expression of the `ifnull` function wrapping this expression.
  public func ifnull(
    _ other: some QueryExpression<QueryValue.Wrapped>
  ) -> some QueryExpression<QueryValue.Wrapped> {
    QueryFunction("ifnull", self, other)
  }

  /// Wraps this optional query expression with the `ifnull` function.
  ///
  /// PostgreSQL's `COALESCE` function (which `ifnull` maps to) returns the first non-NULL value.
  ///
  /// ```swift
  /// Reminder
  ///   .select { $0.dueDate.ifnull(#sql("date()")) }
  /// // SELECT ifnull("reminders"."dueDate", date())
  /// // FROM "reminders"
  /// ```
  ///
  /// - Parameter other: An optional fallback value
  /// - Returns: An optional expression of the `ifnull` function wrapping this expression.
  public func ifnull(
    _ other: some QueryExpression<QueryValue>
  ) -> some QueryExpression<QueryValue> {
    QueryFunction("ifnull", self, other)
  }

  /// Applies each side of the operator to the `coalesce` function
  ///
  /// ```swift
  /// Reminder.select { $0.date ?? #sql("date()") }
  /// // SELECT coalesce("reminders"."date", date()) FROM "reminders"
  /// ```
  ///
  /// > Tip: Heavily overloaded Swift operators can tax the compiler. You can use ``ifnull(_:)``,
  /// > instead, if you find a particular query builds slowly. See
  /// > <doc:CompilerPerformance#Method-operators> for more information.
  ///
  /// - Parameters:
  ///   - lhs: An optional query expression.
  ///   - rhs: A non-optional query expression
  /// - Returns: A non-optional query expression of the `coalesce` function wrapping both arguments.
  public static func ?? (
    lhs: Self,
    rhs: some QueryExpression<QueryValue.Wrapped>
  ) -> Conditional.Coalesce<QueryValue.Wrapped> {
    Conditional.Coalesce([lhs.queryFragment, rhs.queryFragment])
  }

  /// Applies each side of the operator to the `coalesce` function
  ///
  /// ```swift
  /// Reminder.select { $0.date ?? #sql("date()") }
  /// // SELECT coalesce("reminders"."date", date()) FROM "reminders"
  /// ```
  ///
  /// > Tip: Heavily overloaded Swift operators can tax the compiler. You can use ``ifnull(_:)``,
  /// > instead, if you find a particular query builds slowly. See
  /// > <doc:CompilerPerformance#Method-operators> for more information.
  ///
  /// - Parameters:
  ///   - lhs: An optional query expression.
  ///   - rhs: Another optional query expression
  /// - Returns: An optional query expression of the `coalesce` function wrapping both arguments.
  public static func ?? (
    lhs: Self,
    rhs: some QueryExpression<QueryValue>
  ) -> Conditional.Coalesce<QueryValue> {
    Conditional.Coalesce([lhs.queryFragment, rhs.queryFragment])
  }

  @_documentation(visibility: private)
  @available(
    *,
    deprecated,
    message:
      "Left side of 'NULL' coalescing operator '??' has non-optional query type, so the right side is never used"
  )
  public static func ?? (
    lhs: some QueryExpression<QueryValue.Wrapped>,
    rhs: Self
  ) -> Conditional.Coalesce<QueryValue> {
    Conditional.Coalesce([lhs.queryFragment, rhs.queryFragment])
  }
}

extension QueryExpression {
  @_documentation(visibility: private)
  @available(
    *,
    deprecated,
    message:
      "Left side of 'NULL' coalescing operator '??' has non-optional query type, so the right side is never used"
  )
  public static func ?? (
    lhs: some QueryExpression<QueryValue>,
    rhs: Self
  ) -> Conditional.Coalesce<QueryValue> {
    Conditional.Coalesce([lhs.queryFragment, rhs.queryFragment])
  }
}
