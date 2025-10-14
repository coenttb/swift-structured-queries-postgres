import StructuredQueriesCore

// MARK: - Collection Operators (IN, EXISTS)

extension QueryExpression where QueryValue: QueryExpression {
    /// Returns a predicate expression indicating whether the expression is in a sequence.
    ///
    /// - Parameter expression: A sequence of expressions.
    /// - Returns: A predicate expression indicating whether this expression is in the given sequence
    public func `in`<S: Sequence>(_ expression: S) -> some QueryExpression<Bool>
    where S.Element: QueryExpression<QueryValue> {
        BinaryOperator(lhs: self, operator: "IN", rhs: S.Expression(elements: expression))
    }

    /// Returns a predicate expression indicating whether the expression is in a subquery.
    ///
    /// - Parameter query: A subquery.
    /// - Returns: A predicate expression indicating whether this expression is in the given subquery.
    public func `in`(_ query: some Statement<QueryValue>) -> some QueryExpression<Bool> {
        BinaryOperator(
            lhs: self,
            operator: "IN",
            rhs: SQLQueryExpression("(\(query.query))", as: Void.self)
        )
    }
}

extension Sequence where Element: QueryBindable {
    /// Returns a predicate expression indicating whether the sequence contains the given expression.
    ///
    /// An alias for ``QueryExpression/in(_:)``, flipped.
    ///
    /// - Parameter element: An element.
    /// - Returns: A predicate expression indicating whether the expression is in this sequence
    public func contains(
        _ element: some QueryExpression<Element.QueryValue>
    ) -> some QueryExpression<Bool> {
        element.in(self)
    }
}

extension Statement where QueryValue: QueryBindable {
    /// Returns a predicate expression indicating whether this subquery contains the given element.
    ///
    /// An alias for ``QueryExpression/in(_:)``, flipped.
    ///
    /// - Parameter element: An element.
    /// - Returns: A predicate expression indicating whether this expression is in the given subquery.
    public func contains(
        _ element: some QueryExpression<QueryValue>
    ) -> some QueryExpression<Bool> {
        element.in(self)
    }
}

extension PartialSelectStatement {
    /// Returns a predicate expression indicating whether this subquery contains any element.
    ///
    /// - Returns: A predicate expression indicating whether this subquery contains any element.
    public func exists() -> some QueryExpression<Bool> {
        SQLQueryExpression("EXISTS \(self.queryFragment)")
    }
}

extension Table {
    /// Returns a predicate expression indicating whether this table contains any element.
    ///
    /// - Returns: A predicate expression indicating whether this subquery contains any element.
    public static func exists() -> some QueryExpression<Bool> {
        all.exists()
    }
}
