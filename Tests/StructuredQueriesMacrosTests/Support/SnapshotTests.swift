import MacroTesting
import SnapshotTesting
import StructuredQueries
import StructuredQueriesMacros
import Testing

@MainActor
@Suite(
  .serialized,
  .macros(
    record: .failed,
    macros: [
      "_Draft": TableMacro.self,
      "bind": BindMacro.self,
      "Column": ColumnMacro.self,
      "Ephemeral": EphemeralMacro.self,
      "Table": TableMacro.self,
      "Selection": SelectionMacro.self,
      "sql": SQLMacro.self,
    ]
  )
) struct SnapshotTests {}

extension Snapshotting where Value: QueryExpression {
  static var sql: Snapshotting<Value, String> {
    SimplySnapshotting.lines.pullback(\.queryFragment.debugDescription)
  }
}
