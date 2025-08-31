import MacroTesting
import StructuredQueriesPostgresMacros
import Testing

extension SnapshotTests {
  @MainActor
  @Suite struct BindMacroTests {
    @Test func basics() {
      assertMacro {
        #"""
        \(date) < #bind(Date())
        """#
      } expansion: {
        #"""
        \(date) < StructuredQueriesPostgresCore.BindQueryExpression(Date())
        """#
      }
    }

    @Test func queryValueType() {
      assertMacro {
        #"""
        \(date) < #bind(Date(), as: Date.UnixTimeRepresentation.self)
        """#
      } expansion: {
        #"""
        \(date) < StructuredQueriesPostgresCore.BindQueryExpression(Date(), as: Date.UnixTimeRepresentation.self)
        """#
      }
    }
  }
}
