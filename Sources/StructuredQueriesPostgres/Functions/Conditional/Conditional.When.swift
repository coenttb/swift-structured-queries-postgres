import StructuredQueriesCore

extension Conditional {
    /// A WHEN...THEN clause for CASE expressions.
    struct When: QueryExpression {
        typealias QueryValue = Never

        let predicate: QueryFragment
        let expression: QueryFragment

        public var queryFragment: QueryFragment {
            "WHEN \(predicate) THEN \(expression)"
        }
    }
}
