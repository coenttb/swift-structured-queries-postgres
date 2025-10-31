/// A type representing a database table with a primary key.
public protocol PrimaryKeyedTable<PrimaryKey>: Table
where TableColumns: PrimaryKeyedTableDefinition<PrimaryKey> {
  /// A type representing this table's primary key.
  ///
  /// For auto-incrementing tables, this is typically `Int`.
  associatedtype PrimaryKey: QueryRepresentable & QueryExpression
  where PrimaryKey.QueryValue == PrimaryKey

  /// A type that represents this type, but with an optional primary key.
  ///
  /// This type can be used to stage an inserted row.
  associatedtype Draft: TableDraft where Draft.PrimaryTable == Self
}

// A type representing a draft to be saved to a table with a primary key.
public protocol TableDraft: Table {
  /// A type that represents the table with a primary key.
  associatedtype PrimaryTable: PrimaryKeyedTable where PrimaryTable.Draft == Self

  typealias PrimaryKey = PrimaryTable.PrimaryKey

  /// Creates a draft from a primary keyed table.
  init(_ primaryTable: PrimaryTable)
}

extension TableDraft {
  public static subscript(
    dynamicMember keyPath: KeyPath<PrimaryTable.Type, some Statement<PrimaryTable>>
  ) -> some Statement<Self> {
    SQLQueryExpression("\(PrimaryTable.self[keyPath: keyPath])")
  }

  public static subscript(
    dynamicMember keyPath: KeyPath<PrimaryTable.Type, some SelectStatementOf<PrimaryTable>>
  ) -> SelectOf<Self> {
    unsafeBitCast(PrimaryTable.self[keyPath: keyPath].asSelect(), to: SelectOf<Self>.self)
  }

  public static var all: SelectOf<Self> {
    unsafeBitCast(PrimaryTable.all.asSelect(), to: SelectOf<Self>.self)
  }
}

/// A type representing a database table's columns.
///
/// Don't conform to this protocol directly. Instead, use the `@Table` and `@Column` macros to
/// generate a conformance.
public protocol PrimaryKeyedTableDefinition<PrimaryKey>: TableDefinition
where QueryValue: PrimaryKeyedTable {
  /// A type representing this table's primary key.
  ///
  /// For auto-incrementing tables, this is typically `Int`.
  associatedtype PrimaryKey: QueryRepresentable & QueryExpression
  where PrimaryKey.QueryValue == PrimaryKey

  associatedtype PrimaryColumn: _TableColumnExpression<QueryValue, PrimaryKey>

  /// The column representing this table's primary key.
  var primaryKey: PrimaryColumn { get }
}

extension TableDefinition where QueryValue: TableDraft {
  public subscript<Member>(
    dynamicMember keyPath: KeyPath<QueryValue.PrimaryTable.TableColumns, Member>
  ) -> Member {
    QueryValue.PrimaryTable.columns[keyPath: keyPath]
  }
}
