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
                \(date) < SQLQueryExpression(BindQueryExpression(Date())
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
                \(date) < SQLQueryExpression(BindQueryExpression(Date(), as: Date.UnixTimeRepresentation.self)
                """#
            }
        }
    }
}
