/// An `UPDATE` statement.
///
/// This type of statement is constructed from ``Table/update(or:set:)`` and
/// ``Where/update(or:set:)``.
///
/// To learn more, see <doc:UpdateStatements>.
public struct Update<From: Table, Returning>: Sendable {
  var isEmpty: Bool
  var updates: Updates<From>
  var `where`: [QueryFragment] = []
  var returning: [QueryFragment] = []
}

/// A convenience type alias for a non-`RETURNING ``Update``.
public typealias UpdateOf<Base: Table> = Update<Base, ()>

extension Update: Statement {
  public typealias QueryValue = Returning

  public var query: QueryFragment {
    guard !isEmpty, !updates.isEmpty
    else { return "" }

    var query: QueryFragment = "UPDATE "
    if let schemaName = From.schemaName {
      query.append("\(quote: schemaName).")
    }
    query.append("\(quote: From.tableName)")
    if let tableAlias = From.tableAlias {
      query.append(" AS \(quote: tableAlias)")
    }
    query.append("\(.newlineOrSpace)\(updates)")
    if !`where`.isEmpty {
      query.append("\(.newlineOrSpace)WHERE \(`where`.joined(separator: " AND "))")
    }
    if !returning.isEmpty {
      query.append("\(.newlineOrSpace)RETURNING \(returning.joined(separator: ", "))")
    }
    return query
  }
}
