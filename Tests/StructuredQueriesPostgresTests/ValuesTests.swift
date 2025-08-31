import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests {
  @Suite struct ValuesTests {
    @Test func basics() {
      assertInlineSnapshot(of: Values(1, "Hello", true), as: .sql) {
        """
        SELECT 1, 'Hello', true
        """
      }
    }

    @Test func union() {
      assertInlineSnapshot(
        of: Values(1, "Hello", true)
          .union(Values(2, "Goodbye", false)),
        as: .sql
      ) {
        """
        SELECT 1, 'Hello', true
          UNION
        SELECT 2, 'Goodbye', false
        """
      }
    }
  }
}
