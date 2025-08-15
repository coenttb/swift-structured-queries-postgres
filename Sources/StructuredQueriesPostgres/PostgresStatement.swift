import Foundation
import NIOCore
import PostgresNIO
import StructuredQueries

/// Converts StructuredQueries QueryFragments to PostgreSQL-compatible SQL
public struct PostgresStatement {
  public let query: PostgresQuery

  public init(queryFragment: QueryFragment) {
    var parameterIndex = 0
    var bindings = PostgresBindings()
    var sqlParts: [String] = []

    // Process segments to build SQL and bindings
    for segment in queryFragment.segments {
      switch segment {
      case .sql(let sql):
        sqlParts.append(sql)
      case .binding(let binding):
        parameterIndex += 1
        sqlParts.append("$\(parameterIndex)")
        Self.appendBinding(binding, to: &bindings)
      }
    }

    // Join the SQL parts and normalize whitespace (replace newlines with spaces)
    var sql = sqlParts.joined()
      .replacingOccurrences(of: "\n", with: " ")
      .replacingOccurrences(of: "  ", with: " ")  // Clean up any double spaces

    // Transform boolean columns in WHERE clauses for PostgreSQL compatibility
    // Since we're using INTEGER columns for booleans, we need explicit comparisons
    sql = Self.transformBooleanWhereClause(sql)

    self.query = PostgresQuery(unsafeSQL: sql, binds: bindings)
  }

  private static func transformBooleanWhereClause(_ sql: String) -> String {
    // Only transform boolean columns that appear in WHERE/HAVING/ON clauses
    // Skip any that appear in UPDATE SET clauses

    let booleanColumns = ["isCompleted", "isFlagged"]
    var result = sql

    // Only process the part after WHERE (if it exists)
    if let whereRange = result.range(of: " WHERE ", options: .caseInsensitive) {
      let beforeWhere = String(result[..<whereRange.upperBound])
      let afterWhere = String(result[whereRange.upperBound...])

      var transformed = afterWhere
      for column in booleanColumns {
        // Match boolean column used as a condition (not followed by comparison operator)
        let pattern = "(\"[^\"]+\"\\.\"" + column + "\")(?!\\s*[=<>!])"
        transformed = transformed.replacingOccurrences(
          of: pattern,
          with: "$1 != 0",
          options: .regularExpression
        )
      }

      result = beforeWhere + transformed
    }

    return result
  }

  private static func appendBinding(_ binding: QueryBinding, to bindings: inout PostgresBindings) {
    switch binding {
    case .null:
      bindings.appendNull()
    case .int(let value):
        bindings.append(Int(value), context: .default)
    case .double(let value):
      bindings.append(value, context: .default)
    case .text(let value):
      bindings.append(value, context: .default)
    case .blob(let bytes):
      // Convert [UInt8] to ByteBuffer for PostgreSQL bytea type
      var buffer = ByteBufferAllocator().buffer(capacity: bytes.count)
      buffer.writeBytes(bytes)
      bindings.append(buffer, context: .default)
    case .date(let date):
      bindings.append(date, context: .default)
    case .uuid(let uuid):
      bindings.append(uuid, context: .default)
    case .invalid(let error):
      // Log error and append null as fallback
      print("Warning: Invalid binding with error: \(error)")
      bindings.appendNull()
    }
  }
}
