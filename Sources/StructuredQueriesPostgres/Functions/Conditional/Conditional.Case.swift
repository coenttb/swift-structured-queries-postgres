import StructuredQueriesCore

extension Conditional {
    /// A type that builds SQL `CASE` expressions.
    ///
    /// ```swift
    /// Case(5).when(condition1, then: result1)
    /// // Generates: CASE 5 WHEN condition1 THEN result1 END
    /// ```
    public struct Case<Base, QueryValue: _OptionalPromotable> {
        var base: QueryFragment?

        /// Creates a SQL `CASE` expression builder.
        ///
        /// - Parameter base: A "base" expression to test against for each `WHEN`.
        public init(
            _ base: some QueryExpression<Base>
        ) {
            self.base = base.queryFragment
        }

        /// Creates a SQL `CASE` expression builder.
        public init() where Base == Bool {}

        /// Adds a `WHEN` clause to a `CASE` expression.
        ///
        /// - Parameters:
        ///   - condition: A condition to test.
        ///   - expression: A return value should the condition pass.
        /// - Returns: A `CASE` expression builder.
        public func when(
            _ condition: some QueryExpression<Base>,
            then expression: some QueryExpression<QueryValue>
        ) -> Conditional.Builder<Base, QueryValue?> {
            Conditional.Builder(
                base: base,
                cases: [
                    Conditional.When(predicate: condition.queryFragment, expression: expression.queryFragment)
                        .queryFragment
                ]
            )
        }

        /// Adds a `WHEN` clause to a `CASE` expression.
        ///
        /// - Parameters:
        ///   - condition: A condition to test.
        ///   - expression: A return value should the condition pass.
        /// - Returns: A `CASE` expression builder.
        public func when(
            _ condition: some QueryExpression<Base>,
            then expression: some QueryExpression<QueryValue._Optionalized>
        ) -> Conditional.Builder<Base, QueryValue._Optionalized> {
            Conditional.Builder(
                base: base,
                cases: [
                    Conditional.When(predicate: condition.queryFragment, expression: expression.queryFragment)
                        .queryFragment
                ]
            )
        }
    }
}
