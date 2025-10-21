import Foundation

extension CTE {
    /// Creates a common table expression for factoring subqueries or recursive queries.
    ///
    /// Also available as the global ``With`` typealias.
    public struct With<Base: Statement>: Statement, Sendable {
        public typealias QueryValue = Base.QueryValue
        public typealias From = Never

        var ctes: [Clause]
        var statement: QueryFragment
        let recursive: Bool?

        @_disfavoredOverload
        public init(
            recursive: Bool? = nil,
            @Builder _ ctes: () -> [Clause],
            query statement: () -> Base
        ) {
            self.recursive = recursive
            self.ctes = ctes()
            self.statement = statement().query
        }

        public init<S: SelectStatement, each J: Table>(
            recursive: Bool? = nil,
            @Builder _ ctes: () -> [Clause],
            query statement: () -> S
        )
        where
            S.QueryValue == (),
            S.Joins == (repeat each J),
            Base == Select<(S.From, repeat each J), S.From, (repeat each J)>
        {
            self.recursive = recursive
            self.ctes = ctes()
            self.statement = statement().query
        }

        @_disfavoredOverload
        public init<S: SelectStatement>(
            recursive: Bool? = nil,
            @Builder _ ctes: () -> [Clause],
            query statement: () -> S
        )
        where
            S.QueryValue == (),
            S.Joins == (),
            Base == Select<S.From, S.From, ()>
        {
            self.recursive = recursive
            self.ctes = ctes()
            self.statement = statement().query
        }

        public var query: QueryFragment {
            guard !statement.isEmpty else { return "" }
            let cteFragments = ctes.compactMap(\.queryFragment.presence)
            guard !cteFragments.isEmpty else { return "" }

            var query: QueryFragment = "WITH"

            // Add RECURSIVE keyword if needed (auto-detect or explicit)
            if isRecursive {
                query.append(" RECURSIVE")
            }

            query.append(" \(cteFragments.joined(separator: ", "))\(.newlineOrSpace)\(statement)")
            return query
        }

        /// Determines if this WITH clause should include the RECURSIVE keyword.
        ///
        /// Returns true if:
        /// - The `recursive` parameter was explicitly set to `true`, or
        /// - Auto-detection finds a recursive CTE (contains UNION/UNION ALL with self-reference)
        private var isRecursive: Bool {
            // Use explicit value if provided
            if let recursive {
                return recursive
            }

            // Auto-detect: check if any CTE references itself
            return ctes.contains { cte in
                cte.isRecursive
            }
        }
    }
}

extension CTE.With: PartialSelectStatement where Base: PartialSelectStatement {}

extension QueryFragment {
    fileprivate var presence: Self? { isEmpty ? nil : self }
}
