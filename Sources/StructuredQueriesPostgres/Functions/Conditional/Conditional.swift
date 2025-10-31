import Foundation
import StructuredQueriesCore

// MARK: - PostgreSQL Conditional Expressions
//
// PostgreSQL Chapter 9.18: Conditional Expressions
// https://www.postgresql.org/docs/current/functions-conditional.html
//
// SQL CASE expressions for conditional value selection.

/// Namespace for PostgreSQL conditional expression types.
///
/// Contains types for building SQL CASE expressions with WHEN/THEN/ELSE clauses.
///
/// See <doc:ConditionalExpressions> for more information.
public enum Conditional {}

// MARK: - Convenience Constructors

/// Creates a SQL `CASE` expression builder with a base expression.
///
/// ```swift
/// Case(myValue).when(condition1, then: result1)
/// ```
public func Case<Base, QueryValue: _OptionalPromotable>(
  _ base: some QueryExpression<Base>
) -> Conditional.Case<Base, QueryValue> {
  Conditional.Case(base)
}

/// Creates a SQL `CASE` expression builder without a base expression.
///
/// ```swift
/// Case().when(boolCondition, then: result)
/// ```
public func Case<QueryValue: _OptionalPromotable>() -> Conditional.Case<Bool, QueryValue> {
  Conditional.Case()
}
