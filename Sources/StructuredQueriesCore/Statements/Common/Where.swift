/// A `WHERE` clause used to apply a filter to a statement.
///
/// See ``Table/where(_:)`` for how to create this type.
@dynamicMemberLookup
public struct Where<From: Table>: Sendable {
  public static func + (lhs: Self, rhs: Self) -> Self {
    Where(predicates: (lhs.predicates + rhs.predicates).removingDuplicates())
  }

  var predicates: [QueryFragment] = []
  var scope = Scope.default

  public init(
    predicates: [QueryFragment] = [],
    scope: Scope = Scope.default
  ) {
    self.predicates = predicates
    self.scope = scope
  }

  public static subscript(dynamicMember keyPath: KeyPath<From.Type, Self>) -> Self {
    From.self[keyPath: keyPath]
  }

  public subscript<each C: QueryRepresentable, each J: Table>(
    dynamicMember keyPath: KeyPath<From.Type, Select<(repeat each C), From, (repeat each J)>>
  ) -> Select<(repeat each C), From, (repeat each J)> {
    self + From.self[keyPath: keyPath]
  }

  public subscript(dynamicMember keyPath: KeyPath<From.Type, Self>) -> Self {
    self + From.self[keyPath: keyPath]
  }

  public subscript(
    dynamicMember keyPath: KeyPath<From.PrimaryTable.Type, Where<From.PrimaryTable>>
  ) -> Self
  where From: TableDraft {
    self + unsafeBitCast(From.PrimaryTable.self[keyPath: keyPath], to: Self.self)
  }
}

extension Where: SelectStatement {
  public typealias QueryValue = ()

  public func asSelect() -> SelectOf<From> {
    let select: SelectOf<From>
    switch scope {
    case .default:
      select = Select(clauses: From.all._selectClauses)
    case .empty:
      select = Select(isEmpty: true, where: predicates)
    case .unscoped:
      select = Select()
    }
    return select.and(self)
  }

  public var _selectClauses: _SelectClauses {
    _SelectClauses(isEmpty: scope == .empty, where: predicates)
  }

  public var query: QueryFragment {
    asSelect().query
  }
}
