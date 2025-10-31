import Foundation

extension CTE {
  /// A single common table expression clause.
  public struct Clause: QueryExpression, Sendable {
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
}

extension CTE.Clause {
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
}
