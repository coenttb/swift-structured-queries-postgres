import StructuredQueriesCore

extension Conditional {
  /// A `CASE` expression builder with accumulated WHEN clauses.
  public struct Builder<Base, QueryValue: _OptionalProtocol>: QueryExpression {
    var base: QueryFragment?
    var cases: [QueryFragment]

    /// Adds a `WHEN` clause to a `CASE` expression.
    ///
    /// - Parameters:
    ///   - condition: A condition to test.
    ///   - expression: A return value should the condition pass.
    /// - Returns: A `CASE` expression builder.
    public func when(
      _ condition: some QueryExpression<Base>,
      then expression: some QueryExpression<QueryValue>
    ) -> Conditional.Builder<Base, QueryValue> {
      var cases = self
      cases.cases.append(
        Conditional.When(predicate: condition.queryFragment, expression: expression.queryFragment)
          .queryFragment
      )
      return cases
    }

    /// Adds a `WHEN` clause to a `CASE` expression.
    ///
    /// - Parameters:
    ///   - condition: A condition to test.
    ///   - expression: A return value should the condition pass.
    /// - Returns: A `CASE` expression builder.
    public func when(
      _ condition: some QueryExpression<Base>,
      then expression: some QueryExpression<QueryValue.Wrapped>
    ) -> Conditional.Builder<Base, QueryValue> {
      var cases = self
      cases.cases.append(
        Conditional.When(predicate: condition.queryFragment, expression: expression.queryFragment)
          .queryFragment
      )
      return cases
    }

    /// Terminates a `CASE` expression with an `ELSE` clause.
    ///
    /// - Parameter expression: A return value should every `WHEN` condition fail.
    /// - Returns: A `CASE` expression.
    public func `else`(
      _ expression: some QueryExpression<QueryValue.Wrapped>
    ) -> some QueryExpression<QueryValue.Wrapped> {
      var cases = self
      cases.cases.append("ELSE \(expression)")
      return SQLQueryExpression(cases.queryFragment)
    }

    public var queryFragment: QueryFragment {
      var query: QueryFragment = "CASE"
      if let base {
        query.append(" \(base)")
      }
      query.append(" \(cases.joined(separator: " ")) END")
      return query
    }
  }
}
