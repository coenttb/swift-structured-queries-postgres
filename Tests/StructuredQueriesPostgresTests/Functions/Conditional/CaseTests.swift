import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests {
  @Suite struct CaseTests {
    @Test func dynamicCase() async {
      let ids = Array([2, 3, 5, 1, 4].enumerated())
      let (first, rest) = (ids.first!, ids.dropFirst())
      let caseExpression =
        rest
        .reduce(Case(5).when(first.element, then: first.offset)) { cases, id in
          cases.when(id.element, then: id.offset)
        }
        .else(0)

      await assertSQL(
        of: Values(caseExpression)
      ) {
        """
        SELECT CASE 5 WHEN 2 THEN 0 WHEN 3 THEN 1 WHEN 5 THEN 2 WHEN 1 THEN 3 WHEN 4 THEN 4 ELSE 0 END
        """
      }
    }
  }
}
