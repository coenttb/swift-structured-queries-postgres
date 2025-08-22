import Dependencies
import Foundation
import PostgresNIO
import StructuredQueries
import StructuredQueriesPostgres
import Testing

// Helper to assert SQL generation for any statement
func assertPostgresQuery<S: Statement>(
    _ statement: S,
    sql expectedSQL: String? = nil,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    function: StaticString = #function,
    line: UInt = #line,
    column: UInt = #column
) {
    // Test SQL generation
    if let expectedSQL = expectedSQL {
        let queryFragment = statement.query
        let postgresStatement = PostgresStatement(queryFragment: queryFragment)
        let actualSQL = postgresStatement.query.sql

        #expect(
            actualSQL == expectedSQL,
            "SQL mismatch:\nExpected: \(expectedSQL)\nActual: \(actualSQL)",
            sourceLocation: SourceLocation(
                fileID: fileID.description,
                filePath: filePath.description,
                line: Int(line),
                column: Int(column)
            )
        )
    }
}

// Overload for simple queries without custom types
func assertPostgresQuery(
    _ fragment: QueryFragment,
    sql expectedSQL: String? = nil,
    bindings expectedBindings: [QueryBinding]? = nil,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    function: StaticString = #function,
    line: UInt = #line,
    column: UInt = #column
) {
    let postgresStatement = PostgresStatement(queryFragment: fragment)

    if let expectedSQL = expectedSQL {
        let actualSQL = postgresStatement.query.sql
        #expect(
            actualSQL == expectedSQL,
            "SQL mismatch:\nExpected: \(expectedSQL)\nActual: \(actualSQL)",
            sourceLocation: SourceLocation(
                fileID: fileID.description,
                filePath: filePath.description,
                line: Int(line),
                column: Int(column)
            )
        )
    }

    if let expectedBindings = expectedBindings {
        // PostgresBindings doesn't expose count directly, but we can validate the SQL parameters
        let paramCount = postgresStatement.query.sql.components(separatedBy: "$").count - 1
        #expect(
            paramCount == expectedBindings.count,
            "Binding count mismatch: Expected \(expectedBindings.count), got \(paramCount)",
            sourceLocation: SourceLocation(
                fileID: fileID.description,
                filePath: filePath.description,
                line: Int(line),
                column: Int(column)
            )
        )
    }
}

// Helper to format results for testing
func formatResults<T: CustomStringConvertible>(_ items: [T]) -> String {
    guard !items.isEmpty else { return "┌─────┐\n│ (empty) │\n└─────┘" }

    var lines: [String] = []
    lines.append("┌─────────────────────┐")

    for (index, item) in items.enumerated() {
        let description = String(describing: item)
        let formattedLines = description.split(separator: "\n").map { "│ \($0)" }
        lines.append(contentsOf: formattedLines)

        if index < items.count - 1 {
            lines.append("├─────────────────────┤")
        }
    }

    lines.append("└─────────────────────┘")
    return lines.joined(separator: "\n")
}
