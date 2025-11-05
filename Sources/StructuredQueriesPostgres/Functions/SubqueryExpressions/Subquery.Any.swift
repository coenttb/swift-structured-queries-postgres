import Foundation
import StructuredQueriesCore

extension Subquery {
    /// Wrapper for ANY quantified comparison
    ///
    /// PostgreSQL's ANY operator returns true if the comparison is true for any value in the subquery.
    ///
    /// ```swift
    /// Product.where { $0.price < .any(competitorPrices) }
    /// // SELECT … FROM "products" WHERE "products"."price" < ANY (SELECT price FROM competitors)
    /// ```
    public struct `Any`<Value: QueryBindable>: QueryExpression {
        public typealias QueryValue = Value

        public let queryFragment: QueryFragment

        public init<Q: QueryExpression>(_ subquery: Q) where Q.QueryValue == [Value] {
            self.queryFragment = "ANY (\(subquery.queryFragment))"
        }

        public init(_ subquery: QueryFragment) {
            self.queryFragment = "ANY (\(subquery))"
        }
    }
}
