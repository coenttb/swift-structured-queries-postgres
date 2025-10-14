import Foundation

/// Creates a common table expression that can be used to factor subqueries, or create hierarchical
/// or recursive queries of trees and graphs.
public struct With<Base: Statement>: Statement, Sendable {
    public typealias QueryValue = Base.QueryValue
    public typealias From = Never

    var ctes: [CommonTableExpressionClause]
    var statement: QueryFragment
    let recursive: Bool?

    @_disfavoredOverload
    public init(
        recursive: Bool? = nil,
        @CommonTableExpressionBuilder _ ctes: () -> [CommonTableExpressionClause],
        query statement: () -> Base
    ) {
        self.recursive = recursive
        self.ctes = ctes()
        self.statement = statement().query
    }

    public init<S: SelectStatement, each J: Table>(
        recursive: Bool? = nil,
        @CommonTableExpressionBuilder _ ctes: () -> [CommonTableExpressionClause],
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
        @CommonTableExpressionBuilder _ ctes: () -> [CommonTableExpressionClause],
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

extension With: PartialSelectStatement where Base: PartialSelectStatement {}

extension QueryFragment {
    fileprivate var presence: Self? { isEmpty ? nil : self }
}

/// Materialization hint for CTEs (PostgreSQL 12+).
///
/// Controls whether PostgreSQL computes and stores CTE results separately
/// or inlines them into the main query.
public enum MaterializationHint: Sendable {
    /// Force materialization: compute CTE once and store results
    case materialized

    /// Prevent materialization: inline the CTE into the main query
    case notMaterialized
}

public struct CommonTableExpressionClause: QueryExpression, Sendable {
    public typealias QueryValue = ()
    let tableName: QueryFragment
    let select: QueryFragment
    let materialization: MaterializationHint?

    public init(
        tableName: QueryFragment,
        select: QueryFragment,
        materialization: MaterializationHint? = nil
    ) {
        self.tableName = tableName
        self.select = select
        self.materialization = materialization
    }

    public var queryFragment: QueryFragment {
        guard !select.isEmpty else { return "" }

        var fragment: QueryFragment = tableName

        // Add materialization hint (PostgreSQL 12+ feature)
        if let materialization {
            switch materialization {
            case .materialized:
                fragment.append(" AS MATERIALIZED")
            case .notMaterialized:
                fragment.append(" AS NOT MATERIALIZED")
            }
        } else {
            fragment.append(" AS")
        }

        fragment.append(" (\(.newline)\(select.indented())\(.newline))")
        return fragment
    }

    /// Checks if this CTE is recursive (references itself in the query).
    ///
    /// A CTE is considered recursive if:
    /// 1. The query contains UNION or UNION ALL
    /// 2. The query references the CTE's own table name (self-reference)
    ///
    /// This follows PostgreSQL's requirement that recursive CTEs must use `WITH RECURSIVE`.
    var isRecursive: Bool {
        let tableNameString = extractTableName(from: tableName)
        let selectSQL = extractSQL(from: select)

        // Check for UNION pattern (required for recursion)
        let hasUnion = selectSQL.contains("UNION ALL") || selectSQL.contains("UNION")
        guard hasUnion else { return false }

        // Check for self-reference in FROM clause
        // Look for: FROM "tableName" or FROM tableName
        let quotedTableName = "\"\(tableNameString)\""
        return selectSQL.contains("FROM \(quotedTableName)")
            || selectSQL.contains("FROM \(tableNameString)")
    }

    /// Extracts the table name string from a QueryFragment.
    private func extractTableName(from fragment: QueryFragment) -> String {
        // QueryFragment for table name is typically just the string
        fragment.segments
            .compactMap { segment in
                if case .sql(let sql) = segment {
                    return sql.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                return nil
            }
            .joined()
    }

    /// Extracts SQL string from QueryFragment for pattern matching.
    private func extractSQL(from fragment: QueryFragment) -> String {
        fragment.segments
            .compactMap { segment in
                if case .sql(let sql) = segment {
                    return sql
                }
                return nil
            }
            .joined()
    }
}

/// A builder of common table expressions.
///
/// This result builder is used by ``With/init(_:query:)`` to insert any number of common table
/// expressions into a `WITH` statement.
@resultBuilder
public enum CommonTableExpressionBuilder {
    public static func buildExpression<CTETable: Table>(
        _ expression: some PartialSelectStatement<CTETable>
    ) -> CommonTableExpressionClause {
        CommonTableExpressionClause(
            tableName: "\(CTETable.self)",
            select: expression.query,
            materialization: nil
        )
    }

    public static func buildBlock(
        _ component: CommonTableExpressionClause
    ) -> [CommonTableExpressionClause] {
        [component]
    }

    public static func buildPartialBlock(
        first: CommonTableExpressionClause
    ) -> [CommonTableExpressionClause] {
        [first]
    }

    public static func buildPartialBlock(
        accumulated: [CommonTableExpressionClause],
        next: CommonTableExpressionClause
    ) -> [CommonTableExpressionClause] {
        accumulated + [next]
    }
}
