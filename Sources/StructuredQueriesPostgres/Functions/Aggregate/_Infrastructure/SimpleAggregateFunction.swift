import StructuredQueriesCore

/// Simple aggregate function helper for single or two-argument aggregates.
package struct SimpleAggregateFunction<QueryValue: QueryBindable>: QueryExpression {
    let name: String
    let column: QueryFragment
    let separator: QueryFragment?

    init(name: String, column: QueryFragment, separator: QueryFragment? = nil) {
        self.name = name
        self.column = column
        self.separator = separator
    }

    package var queryFragment: QueryFragment {
        if let separator = separator {
            // For functions like string_agg that take two arguments
            return "\(QueryFragment(stringLiteral: name))(\(column), \(separator))"
        } else {
            // For single-argument aggregate functions
            return "\(QueryFragment(stringLiteral: name))(\(column))"
        }
    }
}
