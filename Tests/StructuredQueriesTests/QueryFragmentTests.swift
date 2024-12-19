import Foundation
import InlineSnapshotTesting
import StructuredQueries
import StructuredQueriesTestSupport
import Testing

extension SnapshotTests {
  struct QueryFragmentTests {
    @Test func string() {
      assertInlineSnapshot(
        of: SQLQueryExpression("'What''s the point?'", as: String.self),
        as: .sql
      ) {
        """
        'What''s the point?'
        """
      }
    }
    @Test func identifier() {
      assertInlineSnapshot(
        of: SQLQueryExpression(#""What's the point?""#, as: String.self),
        as: .sql
      ) {
        """
        "What's the point?"
        """
      }
    }
    @Test func brackets() {
      assertInlineSnapshot(
        of: SQLQueryExpression("[What's the point?]", as: String.self),
        as: .sql
      ) {
        """
        [What's the point?]
        """
      }
    }
    @Test func backticks() {
      assertInlineSnapshot(
        of: SQLQueryExpression("`What's the point?`", as: String.self),
        as: .sql
      ) {
        """
        `What's the point?`
        """
      }
    }
  }
}
