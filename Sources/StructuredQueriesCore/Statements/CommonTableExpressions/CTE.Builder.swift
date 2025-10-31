import Foundation

extension CTE {
  /// A builder of common table expressions.
  ///
  /// This result builder is used by ``With/init(recursive:_:query:)`` to insert
  /// any number of common table expressions into a `WITH` statement.
  @resultBuilder
  public enum Builder {
    public static func buildExpression<CTETable: Table>(
      _ expression: some PartialSelectStatement<CTETable>
    ) -> Clause {
      Clause(
        tableName: "\(CTETable.self)",
        select: expression.query,
        materialization: nil
      )
    }

    public static func buildBlock(
      _ component: Clause
    ) -> [Clause] {
      [component]
    }

    public static func buildPartialBlock(
      first: Clause
    ) -> [Clause] {
      [first]
    }

    public static func buildPartialBlock(
      accumulated: [Clause],
      next: Clause
    ) -> [Clause] {
      accumulated + [next]
    }
  }
}
