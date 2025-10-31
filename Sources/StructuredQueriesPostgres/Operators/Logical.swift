import StructuredQueriesCore

// MARK: - 9.1. Logical Operators

extension QueryExpression where QueryValue == Bool {
  /// Returns a logical AND operation on two predicate expressions.
  ///
  /// > Important: Overloaded operators can strain the Swift compiler's type checking ability.
  /// > Consider using ``and(_:)``, instead.
  ///
  /// - Parameters:
  ///   - lhs: The left-hand side of the operation.
  ///   - rhs: The right-hand side of the operation.
  /// - Returns: A predicate expression.
  public static func && (
    lhs: Self,
    rhs: some QueryExpression<QueryValue>
  ) -> some QueryExpression<QueryValue> {
    lhs.and(rhs)
  }

  /// Returns a logical OR operation on two predicate expressions.
  ///
  /// > Important: Overloaded operators can strain the Swift compiler's type checking ability.
  /// > Consider using ``or(_:)``, instead.
  ///
  /// - Parameters:
  ///   - lhs: The left-hand side of the operation.
  ///   - rhs: The right-hand side of the operation.
  /// - Returns: A predicate expression.
  public static func || (
    lhs: Self,
    rhs: some QueryExpression<QueryValue>
  ) -> some QueryExpression<QueryValue> {
    lhs.or(rhs)
  }

  /// Returns a logical NOT operation on a predicate expression.
  ///
  /// - Parameter expression: The predicate expression to negate.
  /// - Returns: A negated predicate expression.
  public static prefix func ! (expression: Self) -> some QueryExpression<QueryValue> {
    expression.not()
  }

  /// Returns a logical AND operation on two predicate expressions.
  ///
  /// - Parameter other: The right-hand side of the operation to this predicate's left-hand side.
  /// - Returns: A predicate expression.
  public func and(_ other: some QueryExpression<QueryValue>) -> some QueryExpression<QueryValue> {
    BinaryOperator(lhs: self, operator: "AND", rhs: other)
  }

  /// Returns a logical OR operation on two predicate expressions.
  ///
  /// - Parameter other: The right-hand side of the operation to this predicate's left-hand side.
  /// - Returns: A predicate expression.
  public func or(_ other: some QueryExpression<QueryValue>) -> some QueryExpression<QueryValue> {
    BinaryOperator(lhs: self, operator: "OR", rhs: other)
  }

  /// Returns a logical NOT operation on this predicate expression.
  ///
  /// - Returns: This predicate expression, negated.
  public func not() -> some QueryExpression<QueryValue> {
    UnaryOperator(operator: "NOT", base: self)
  }
}

// NB: This overload is required due to an overload resolution bug of 'Updates[dynamicMember:]'.
// swiftlint:disable:next prefer_some_over_any
@_documentation(visibility: private)
public prefix func ! (
  expression: any QueryExpression<Bool>
) -> some QueryExpression<Bool> {
  func open(_ expression: some QueryExpression<Bool>) -> SQLQueryExpression<Bool> {
    SQLQueryExpression(expression.not())
  }
  return open(expression)
}

extension SQLQueryExpression<Bool> {
  public mutating func toggle() {
    self = Self(not())
  }
}
