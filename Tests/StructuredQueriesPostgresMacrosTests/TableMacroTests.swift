import MacroTesting
import StructuredQueriesPostgresMacros
import Testing

extension SnapshotTests {
    @MainActor
    @Suite struct TableMacroTests {
        @Test func basics() {
            assertMacro {
                """
                @Table
                struct Foo {
                  var bar: Int
                }
                """
            } expansion: {
                #"""
                struct Foo {
                  var bar: Int

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                    public typealias QueryValue = Foo
                    public let bar = SQLQueryExpression(_TableColumn<QueryValue, Int>.for("bar", keyPath: \QueryValue.bar)
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.bar._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.bar._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.bar)"
                    }
                  }

                  public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = Foo
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public init(
                      bar: some SQLQueryExpression(QueryExpression<Int>
                    ) {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: bar._allColumns)
                      self.allColumns = allColumns
                    }
                  }
                }

                nonisolated extension Foo: SQLQueryExpression(Table, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    var columnWidth = 0
                    columnWidth += Int._columnWidth
                    return columnWidth
                  }
                  public nonisolated static var tableName: String {
                    "foos"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    let bar = try decoder.decode(Int.self)
                    guard let bar else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    self.bar = bar
                  }
                }
                """#
            }
        }

        @Test func selection() {
            assertMacro {
                """
                @Selection
                struct Foo {
                  var bar: Int
                }
                """
            } expansion: {
                #"""
                struct Foo {
                  var bar: Int

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                    public typealias QueryValue = Foo
                    public let bar = SQLQueryExpression(_TableColumn<QueryValue, Int>.for("bar", keyPath: \QueryValue.bar)
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.bar._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.bar._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.bar)"
                    }
                  }

                  public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = Foo
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public init(
                      bar: some SQLQueryExpression(QueryExpression<Int>
                    ) {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: bar._allColumns)
                      self.allColumns = allColumns
                    }
                  }
                }

                nonisolated extension Foo: SQLQueryExpression(Table, SQLQueryExpression(_Selection, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    var columnWidth = 0
                    columnWidth += Int._columnWidth
                    return columnWidth
                  }
                  public nonisolated static var tableName: String {
                    "foos"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    let bar = try decoder.decode(Int.self)
                    guard let bar else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    self.bar = bar
                  }
                }
                """#
            }
        }

        @Test func tableSelection() {
            assertMacro {
                """
                @Table @Selection
                struct Foo {
                  var bar: Int
                }
                """
            } diagnostics: {
                """
                @Table @Selection
                       ┬─────────
                       ╰─ ⚠️ '@Table' and '@Selection' should not be applied together

                Apply '@Table' to types representing stored tables, virtual tables, and database views.

                Apply '@Selection' to types representing multiple columns that can be selected from a table or query, and types that represent common table expressions.
                          ✏️ Remove '@Selection'
                          ✏️ Remove '@Table'
                struct Foo {
                  var bar: Int
                }
                """
            } fixes: {
                """
                struct Foo {
                  var bar: Int
                }
                """
            } expansion: {
                """
                struct Foo {
                  var bar: Int
                }
                """
            }
        }

        @Test func comment() {
            assertMacro {
                """
                @Table
                struct User {
                  /// The user's identifier.
                  let id: /* TODO: UUID */Int // Primary key
                  /// The user's email.
                  var email: String? = ""  // TODO: Should this be non-optional?
                  /// The user's age.
                  var age: Int
                }
                """
            } expansion: {
                #"""
                struct User {
                  /// The user's identifier.
                  let id: /* TODO: UUID */Int // Primary key
                  /// The user's email.
                  var email: String? = ""  // TODO: Should this be non-optional?
                  /// The user's age.
                  var age: Int

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition, SQLQueryExpression(PrimaryKeyedTableDefinition {
                    public typealias QueryValue = User
                    public typealias PrimaryKey = Int
                    public let id = SQLQueryExpression(_TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
                    public let primaryKey = SQLQueryExpression(_TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
                    public let email = SQLQueryExpression(_TableColumn<QueryValue, String?>.for("email", keyPath: \QueryValue.email, default: "")
                    public let age = SQLQueryExpression(_TableColumn<QueryValue, Int>.for("age", keyPath: \QueryValue.age)
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                      allColumns.append(contentsOf: QueryValue.columns.email._allColumns)
                      allColumns.append(contentsOf: QueryValue.columns.age._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                      writableColumns.append(contentsOf: QueryValue.columns.email._writableColumns)
                      writableColumns.append(contentsOf: QueryValue.columns.age._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.id), \(self.email), \(self.age)"
                    }
                  }

                  public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = User
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public init(
                      id: some SQLQueryExpression(QueryExpression<Int>,
                      email: some SQLQueryExpression(QueryExpression<String?> = String?(queryOutput: ""),
                      age: some SQLQueryExpression(QueryExpression<Int>
                    ) {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: id._allColumns)
                      allColumns.append(contentsOf: email._allColumns)
                      allColumns.append(contentsOf: age._allColumns)
                      self.allColumns = allColumns
                    }
                  }

                  public struct Draft: SQLQueryExpression(TableDraft {
                    public typealias PrimaryTable = User
                    let id: /* TODO: UUID */ Int? // Primary key
                    var email: String? = ""
                    var age: Int
                    public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                      public typealias QueryValue = Draft
                      public let id = SQLQueryExpression(_TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
                      public let email = SQLQueryExpression(_TableColumn<QueryValue, String?>.for("email", keyPath: \QueryValue.email, default: "")
                      public let age = SQLQueryExpression(_TableColumn<QueryValue, Int>.for("age", keyPath: \QueryValue.age)
                      public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                        var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                        allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                        allColumns.append(contentsOf: QueryValue.columns.email._allColumns)
                        allColumns.append(contentsOf: QueryValue.columns.age._allColumns)
                        return allColumns
                      }
                      public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                        var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                        writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                        writableColumns.append(contentsOf: QueryValue.columns.email._writableColumns)
                        writableColumns.append(contentsOf: QueryValue.columns.age._writableColumns)
                        return writableColumns
                      }
                      public var queryFragment: QueryFragment {
                        "\(self.id), \(self.email), \(self.age)"
                      }
                    }
                    public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                      public typealias QueryValue = Draft
                      public let allColumns: [any SQLQueryExpression(QueryExpression]
                      public init(
                        id: some SQLQueryExpression(QueryExpression<Int?> = Int?(queryOutput: nil),
                        email: some SQLQueryExpression(QueryExpression<String?> = String?(queryOutput: ""),
                        age: some SQLQueryExpression(QueryExpression<Int>
                      ) {
                        var allColumns: [any SQLQueryExpression(QueryExpression] = []
                        allColumns.append(contentsOf: id._allColumns)
                        allColumns.append(contentsOf: email._allColumns)
                        allColumns.append(contentsOf: age._allColumns)
                        self.allColumns = allColumns
                      }
                    }
                    public typealias QueryValue = Self

                    public typealias From = Swift.Never

                    public nonisolated static var columns: TableColumns {
                      TableColumns()
                    }

                    public nonisolated static var _columnWidth: Int {
                      var columnWidth = 0
                      columnWidth += Int?._columnWidth
                      columnWidth += String?._columnWidth
                      columnWidth += Int._columnWidth
                      return columnWidth
                    }

                    public nonisolated static var tableName: String {
                      User.tableName
                    }

                    public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                      self.id = try decoder.decode(Int.self) ?? nil
                      self.email = try decoder.decode(String.self) ?? ""
                      let age = try decoder.decode(Int.self)
                      guard let age else {
                        throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                      }
                      self.age = age
                    }

                    public nonisolated init(_ other: User) {
                      self.id = other.id
                      self.email = other.email
                      self.age = other.age
                    }
                    public init(
                      id: /* TODO: UUID */ Int? = nil,
                      email: String? = "",
                      age: Int
                    ) {
                      self.id = id
                      self.email = email
                      self.age = age
                    }
                  }
                }

                nonisolated extension User: SQLQueryExpression(Table, SQLQueryExpression(PrimaryKeyedTable, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    var columnWidth = 0
                    columnWidth += Int._columnWidth
                    columnWidth += String?._columnWidth
                    columnWidth += Int._columnWidth
                    return columnWidth
                  }
                  public nonisolated static var tableName: String {
                    "users"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    let id = try decoder.decode(Int.self)
                    self.email = try decoder.decode(String.self) ?? ""  // TODO: Should this be non-optional?
                    let age = try decoder.decode(Int.self)
                    guard let id else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    guard let age else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    self.id = id
                    self.age = age
                  }
                }
                """#
            }
        }

        @Test func tableName() {
            assertMacro {
                """
                @Table("foo")
                struct Foo {
                  var bar: Int
                }
                """
            } expansion: {
                #"""
                struct Foo {
                  var bar: Int

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                    public typealias QueryValue = Foo
                    public let bar = SQLQueryExpression(_TableColumn<QueryValue, Int>.for("bar", keyPath: \QueryValue.bar)
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.bar._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.bar._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.bar)"
                    }
                  }

                  public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = Foo
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public init(
                      bar: some SQLQueryExpression(QueryExpression<Int>
                    ) {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: bar._allColumns)
                      self.allColumns = allColumns
                    }
                  }
                }

                nonisolated extension Foo: SQLQueryExpression(Table, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    var columnWidth = 0
                    columnWidth += Int._columnWidth
                    return columnWidth
                  }
                  public nonisolated static var tableName: String {
                    "foo"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    let bar = try decoder.decode(Int.self)
                    guard let bar else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    self.bar = bar
                  }
                }
                """#
            }
        }

        @Test func tableNameNil() {
            assertMacro {
                """
                @Table(nil)
                struct Foo {
                  var bar: Int
                }
                """
            } diagnostics: {
                """
                @Table(nil)
                       ┬──
                       ╰─ 🛑 Argument must be a non-empty string literal
                struct Foo {
                  var bar: Int
                }
                """
            }
        }

        @Test func tableNameEmpty() {
            assertMacro {
                """
                @Table("")
                struct Foo {
                  var bar: Int
                }
                """
            } diagnostics: {
                """
                @Table("")
                       ┬─
                       ╰─ 🛑 Argument must be a non-empty string literal
                struct Foo {
                  var bar: Int
                }
                """
            }
        }

        @Test func schemaName() {
            assertMacro {
                """
                @Table("bar", schema: "foo")
                struct Bar {
                  var baz: Int
                }
                """
            } expansion: {
                #"""
                struct Bar {
                  var baz: Int

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                    public typealias QueryValue = Bar
                    public let baz = SQLQueryExpression(_TableColumn<QueryValue, Int>.for("baz", keyPath: \QueryValue.baz)
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.baz._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.baz._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.baz)"
                    }
                  }

                  public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = Bar
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public init(
                      baz: some SQLQueryExpression(QueryExpression<Int>
                    ) {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: baz._allColumns)
                      self.allColumns = allColumns
                    }
                  }
                }

                nonisolated extension Bar: SQLQueryExpression(Table, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    var columnWidth = 0
                    columnWidth += Int._columnWidth
                    return columnWidth
                  }
                  public nonisolated static var tableName: String {
                    "bar"
                  }
                  public nonisolated static let schemaName: Swift.String? = "foo"
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    let baz = try decoder.decode(Int.self)
                    guard let baz else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    self.baz = baz
                  }
                }
                """#
            }
        }

        @Test func schemaNameNil() {
            assertMacro {
                """
                @Table(schema: nil)
                struct Foo {
                  var bar: Int
                }
                """
            } diagnostics: {
                """
                @Table(schema: nil)
                               ┬──
                               ╰─ 🛑 Argument must be a non-empty string literal
                struct Foo {
                  var bar: Int
                }
                """
            }
        }

        @Test func schemaNameEmpty() {
            assertMacro {
                """
                @Table(schema: "")
                struct Foo {
                  var bar: Int
                }
                """
            } diagnostics: {
                """
                @Table(schema: "")
                               ┬─
                               ╰─ 🛑 Argument must be a non-empty string literal
                struct Foo {
                  var bar: Int
                }
                """
            }
        }

        @Test func literals() {
            assertMacro {
                """
                @Table
                struct Foo {
                  var c1 = true
                  var c2 = 1
                  var c3 = 1.2
                  var c4 = ""
                }
                """
            } expansion: {
                #"""
                struct Foo {
                  var c1 = true
                  var c2 = 1
                  var c3 = 1.2
                  var c4 = ""

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                    public typealias QueryValue = Foo
                    public let c1 = SQLQueryExpression(_TableColumn<QueryValue, Swift.Bool>.for("c1", keyPath: \QueryValue.c1, default: true)
                    public let c2 = SQLQueryExpression(_TableColumn<QueryValue, Swift.Int>.for("c2", keyPath: \QueryValue.c2, default: 1)
                    public let c3 = SQLQueryExpression(_TableColumn<QueryValue, Swift.Double>.for("c3", keyPath: \QueryValue.c3, default: 1.2)
                    public let c4 = SQLQueryExpression(_TableColumn<QueryValue, Swift.String>.for("c4", keyPath: \QueryValue.c4, default: "")
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.c1._allColumns)
                      allColumns.append(contentsOf: QueryValue.columns.c2._allColumns)
                      allColumns.append(contentsOf: QueryValue.columns.c3._allColumns)
                      allColumns.append(contentsOf: QueryValue.columns.c4._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.c1._writableColumns)
                      writableColumns.append(contentsOf: QueryValue.columns.c2._writableColumns)
                      writableColumns.append(contentsOf: QueryValue.columns.c3._writableColumns)
                      writableColumns.append(contentsOf: QueryValue.columns.c4._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.c1), \(self.c2), \(self.c3), \(self.c4)"
                    }
                  }

                  public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = Foo
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public init(
                      c1: some SQLQueryExpression(QueryExpression<Swift.Bool> = Swift.Bool(queryOutput: true),
                      c2: some SQLQueryExpression(QueryExpression<Swift.Int> = Swift.Int(queryOutput: 1),
                      c3: some SQLQueryExpression(QueryExpression<Swift.Double> = Swift.Double(queryOutput: 1.2),
                      c4: some SQLQueryExpression(QueryExpression<Swift.String> = Swift.String(queryOutput: "")
                    ) {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: c1._allColumns)
                      allColumns.append(contentsOf: c2._allColumns)
                      allColumns.append(contentsOf: c3._allColumns)
                      allColumns.append(contentsOf: c4._allColumns)
                      self.allColumns = allColumns
                    }
                  }
                }

                nonisolated extension Foo: SQLQueryExpression(Table, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    var columnWidth = 0
                    columnWidth += Swift.Bool._columnWidth
                    columnWidth += Swift.Int._columnWidth
                    columnWidth += Swift.Double._columnWidth
                    columnWidth += Swift.String._columnWidth
                    return columnWidth
                  }
                  public nonisolated static var tableName: String {
                    "foos"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    self.c1 = try decoder.decode(Swift.Bool.self) ?? true
                    self.c2 = try decoder.decode(Swift.Int.self) ?? 1
                    self.c3 = try decoder.decode(Swift.Double.self) ?? 1.2
                    self.c4 = try decoder.decode(Swift.String.self) ?? ""
                  }
                }
                """#
            }
        }

        @Test func columnName() {
            assertMacro {
                """
                @Table
                struct Foo {
                  @Column("Bar")
                  var bar: Int
                }
                """
            } expansion: {
                #"""
                struct Foo {
                  var bar: Int

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                    public typealias QueryValue = Foo
                    public let bar = SQLQueryExpression(TableColumn<QueryValue, Int>("Bar", keyPath: \QueryValue.bar)
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.bar._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.bar._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.bar)"
                    }
                  }

                  public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = Foo
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public init(
                      bar: some SQLQueryExpression(QueryExpression<Int>
                    ) {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: bar._allColumns)
                      self.allColumns = allColumns
                    }
                  }
                }

                nonisolated extension Foo: SQLQueryExpression(Table, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    var columnWidth = 0
                    columnWidth += Int._columnWidth
                    return columnWidth
                  }
                  public nonisolated static var tableName: String {
                    "foos"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    let bar = try decoder.decode(Int.self)
                    guard let bar else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    self.bar = bar
                  }
                }
                """#
            }
        }

        @Test func columnNameNil() {
            assertMacro {
                """
                @Table
                struct Foo {
                  @Column(nil)
                  var bar: Int
                }
                """
            } diagnostics: {
                """
                @Table
                struct Foo {
                  @Column(nil)
                          ┬──
                          ╰─ 🛑 Argument must be a non-empty string literal
                  var bar: Int
                }
                """
            }
        }

        @Test func columnNameEmpty() {
            assertMacro {
                """
                @Table
                struct Foo {
                  @Column("")
                  var bar: Int
                }
                """
            } diagnostics: {
                """
                @Table
                struct Foo {
                  @Column("")
                          ┬─
                          ╰─ 🛑 Argument must be a non-empty string literal
                  var bar: Int
                }
                """
            }
        }

        @Test func representable() {
            assertMacro {
                """
                @Table
                struct Foo {
                  @Column(as: Date.UnixTimeRepresentation.self)
                  var bar: Date
                }
                """
            } expansion: {
                #"""
                struct Foo {
                  var bar: Date

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                    public typealias QueryValue = Foo
                    public let bar = SQLQueryExpression(TableColumn<QueryValue, Date.UnixTimeRepresentation>("bar", keyPath: \QueryValue.bar)
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.bar._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.bar._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.bar)"
                    }
                  }

                  public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = Foo
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public init(
                      bar: some SQLQueryExpression(QueryExpression<Date.UnixTimeRepresentation>
                    ) {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: bar._allColumns)
                      self.allColumns = allColumns
                    }
                  }
                }

                nonisolated extension Foo: SQLQueryExpression(Table, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    var columnWidth = 0
                    columnWidth += Date.UnixTimeRepresentation._columnWidth
                    return columnWidth
                  }
                  public nonisolated static var tableName: String {
                    "foos"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    let bar = try decoder.decode(Date.UnixTimeRepresentation.self)
                    guard let bar else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    self.bar = bar
                  }
                }
                """#
            }
        }

        @Test func columnGenerated() throws {
            assertMacro {
                """
                @Table struct User {
                  var name: String
                  @Column(generated: .stored)
                  let generated: String
                }
                """
            } expansion: {
                #"""
                struct User {
                  var name: String
                  let generated: String

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                    public typealias QueryValue = User
                    public let name = SQLQueryExpression(_TableColumn<QueryValue, String>.for("name", keyPath: \QueryValue.name)
                    public let generated = SQLQueryExpression(GeneratedColumn<QueryValue, String>("generated", keyPath: \QueryValue.generated)
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
                      allColumns.append(contentsOf: QueryValue.columns.generated._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.name), \(self.generated)"
                    }
                  }

                  public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = User
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public init(
                      name: some SQLQueryExpression(QueryExpression<String>,
                      generated: some SQLQueryExpression(QueryExpression<String>
                    ) {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: name._allColumns)
                      allColumns.append(contentsOf: generated._allColumns)
                      self.allColumns = allColumns
                    }
                  }
                }

                nonisolated extension User: SQLQueryExpression(Table, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    var columnWidth = 0
                    columnWidth += String._columnWidth
                    columnWidth += String._columnWidth
                    return columnWidth
                  }
                  public nonisolated static var tableName: String {
                    "users"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    let name = try decoder.decode(String.self)
                    let generated = try decoder.decode(String.self)
                    guard let name else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    guard let generated else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    self.name = name
                    self.generated = generated
                  }
                }
                """#
            }
        }

        @Test func columnGeneratedDiagnostic() throws {
            assertMacro {
                """
                @Table struct User {
                  var name: String
                  @Column(generated: .stored)
                  var generated: String
                }
                """
            } diagnostics: {
                """
                @Table struct User {
                  var name: String
                  @Column(generated: .stored)
                  var generated: String
                  ┬──
                  ╰─ 🛑 Generated column property must be declared with a 'let'
                     ✏️ Replace 'var' with 'let'
                }
                """
            } fixes: {
                """
                @Table struct User {
                  var name: String
                  @Column(generated: .stored)
                  let generated: String
                }
                """
            } expansion: {
                #"""
                struct User {
                  var name: String
                  let generated: String

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                    public typealias QueryValue = User
                    public let name = SQLQueryExpression(_TableColumn<QueryValue, String>.for("name", keyPath: \QueryValue.name)
                    public let generated = SQLQueryExpression(GeneratedColumn<QueryValue, String>("generated", keyPath: \QueryValue.generated)
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
                      allColumns.append(contentsOf: QueryValue.columns.generated._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.name), \(self.generated)"
                    }
                  }

                  public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = User
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public init(
                      name: some SQLQueryExpression(QueryExpression<String>,
                      generated: some SQLQueryExpression(QueryExpression<String>
                    ) {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: name._allColumns)
                      allColumns.append(contentsOf: generated._allColumns)
                      self.allColumns = allColumns
                    }
                  }
                }

                nonisolated extension User: SQLQueryExpression(Table, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    var columnWidth = 0
                    columnWidth += String._columnWidth
                    columnWidth += String._columnWidth
                    return columnWidth
                  }
                  public nonisolated static var tableName: String {
                    "users"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    let name = try decoder.decode(String.self)
                    let generated = try decoder.decode(String.self)
                    guard let name else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    guard let generated else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    self.name = name
                    self.generated = generated
                  }
                }
                """#
            }
        }

        @Test func columnGeneratedPrimaryKeyedTable() throws {
            assertMacro {
                """
                @Table struct User {
                  let id: Int
                  var name: String
                  @Column(generated: .stored)
                  let generated: Int
                }
                """
            } expansion: {
                #"""
                struct User {
                  let id: Int
                  var name: String
                  let generated: Int

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition, SQLQueryExpression(PrimaryKeyedTableDefinition {
                    public typealias QueryValue = User
                    public typealias PrimaryKey = Int
                    public let id = SQLQueryExpression(_TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
                    public let primaryKey = SQLQueryExpression(_TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
                    public let name = SQLQueryExpression(_TableColumn<QueryValue, String>.for("name", keyPath: \QueryValue.name)
                    public let generated = SQLQueryExpression(GeneratedColumn<QueryValue, Int>("generated", keyPath: \QueryValue.generated)
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                      allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
                      allColumns.append(contentsOf: QueryValue.columns.generated._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                      writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.id), \(self.name), \(self.generated)"
                    }
                  }

                  public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = User
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public init(
                      id: some SQLQueryExpression(QueryExpression<Int>,
                      name: some SQLQueryExpression(QueryExpression<String>,
                      generated: some SQLQueryExpression(QueryExpression<Int>
                    ) {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: id._allColumns)
                      allColumns.append(contentsOf: name._allColumns)
                      allColumns.append(contentsOf: generated._allColumns)
                      self.allColumns = allColumns
                    }
                  }

                  public struct Draft: SQLQueryExpression(TableDraft {
                    public typealias PrimaryTable = User
                    let id: Int?
                    var name: String
                    public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                      public typealias QueryValue = Draft
                      public let id = SQLQueryExpression(_TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
                      public let name = SQLQueryExpression(_TableColumn<QueryValue, String>.for("name", keyPath: \QueryValue.name)
                      public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                        var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                        allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                        allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
                        return allColumns
                      }
                      public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                        var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                        writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                        writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
                        return writableColumns
                      }
                      public var queryFragment: QueryFragment {
                        "\(self.id), \(self.name)"
                      }
                    }
                    public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                      public typealias QueryValue = Draft
                      public let allColumns: [any SQLQueryExpression(QueryExpression]
                      public init(
                        id: some SQLQueryExpression(QueryExpression<Int?> = Int?(queryOutput: nil),
                        name: some SQLQueryExpression(QueryExpression<String>
                      ) {
                        var allColumns: [any SQLQueryExpression(QueryExpression] = []
                        allColumns.append(contentsOf: id._allColumns)
                        allColumns.append(contentsOf: name._allColumns)
                        self.allColumns = allColumns
                      }
                    }
                    public typealias QueryValue = Self

                    public typealias From = Swift.Never

                    public nonisolated static var columns: TableColumns {
                      TableColumns()
                    }

                    public nonisolated static var _columnWidth: Int {
                      var columnWidth = 0
                      columnWidth += Int?._columnWidth
                      columnWidth += String._columnWidth
                      return columnWidth
                    }

                    public nonisolated static var tableName: String {
                      User.tableName
                    }

                    public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                      self.id = try decoder.decode(Int.self) ?? nil
                      let name = try decoder.decode(String.self)
                      guard let name else {
                        throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                      }
                      self.name = name
                    }

                    public nonisolated init(_ other: User) {
                      self.id = other.id
                      self.name = other.name
                    }
                    public init(
                      id: Int? = nil,
                      name: String
                    ) {
                      self.id = id
                      self.name = name
                    }
                  }
                }

                nonisolated extension User: SQLQueryExpression(Table, SQLQueryExpression(PrimaryKeyedTable, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    var columnWidth = 0
                    columnWidth += Int._columnWidth
                    columnWidth += String._columnWidth
                    columnWidth += Int._columnWidth
                    return columnWidth
                  }
                  public nonisolated static var tableName: String {
                    "users"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    let id = try decoder.decode(Int.self)
                    let name = try decoder.decode(String.self)
                    let generated = try decoder.decode(Int.self)
                    guard let id else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    guard let name else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    guard let generated else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    self.id = id
                    self.name = name
                    self.generated = generated
                  }
                }
                """#
            }
        }

        @Test func computed() {
            assertMacro {
                """
                @Table
                struct Foo {
                  var bar: Int
                  var baz: Int { 42 }
                }
                """
            } expansion: {
                #"""
                struct Foo {
                  var bar: Int
                  var baz: Int { 42 }

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                    public typealias QueryValue = Foo
                    public let bar = SQLQueryExpression(_TableColumn<QueryValue, Int>.for("bar", keyPath: \QueryValue.bar)
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.bar._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.bar._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.bar)"
                    }
                  }

                  public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = Foo
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public init(
                      bar: some SQLQueryExpression(QueryExpression<Int>
                    ) {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: bar._allColumns)
                      self.allColumns = allColumns
                    }
                  }
                }

                nonisolated extension Foo: SQLQueryExpression(Table, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    var columnWidth = 0
                    columnWidth += Int._columnWidth
                    return columnWidth
                  }
                  public nonisolated static var tableName: String {
                    "foos"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    let bar = try decoder.decode(Int.self)
                    guard let bar else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    self.bar = bar
                  }
                }
                """#
            }
        }

        @Test func `static`() {
            assertMacro {
                """
                @Table
                struct Foo {
                  var bar: Int
                  static var baz: Int { 42 }
                }
                """
            } expansion: {
                #"""
                struct Foo {
                  var bar: Int
                  static var baz: Int { 42 }

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                    public typealias QueryValue = Foo
                    public let bar = SQLQueryExpression(_TableColumn<QueryValue, Int>.for("bar", keyPath: \QueryValue.bar)
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.bar._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.bar._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.bar)"
                    }
                  }

                  public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = Foo
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public init(
                      bar: some SQLQueryExpression(QueryExpression<Int>
                    ) {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: bar._allColumns)
                      self.allColumns = allColumns
                    }
                  }
                }

                nonisolated extension Foo: SQLQueryExpression(Table, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    var columnWidth = 0
                    columnWidth += Int._columnWidth
                    return columnWidth
                  }
                  public nonisolated static var tableName: String {
                    "foos"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    let bar = try decoder.decode(Int.self)
                    guard let bar else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    self.bar = bar
                  }
                }
                """#
            }
        }

        @Test func backticks() {
            assertMacro {
                """
                @Table
                struct Foo {
                  var `bar`: Int
                }
                """
            } expansion: {
                #"""
                struct Foo {
                  var `bar`: Int

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                    public typealias QueryValue = Foo
                    public let `bar` = SQLQueryExpression(_TableColumn<QueryValue, Int>.for("bar", keyPath: \QueryValue.`bar`)
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.`bar`._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.`bar`._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.`bar`)"
                    }
                  }

                  public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = Foo
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public init(
                      `bar`: some SQLQueryExpression(QueryExpression<Int>
                    ) {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: `bar`._allColumns)
                      self.allColumns = allColumns
                    }
                  }
                }

                nonisolated extension Foo: SQLQueryExpression(Table, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    var columnWidth = 0
                    columnWidth += Int._columnWidth
                    return columnWidth
                  }
                  public nonisolated static var tableName: String {
                    "foos"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    let `bar` = try decoder.decode(Int.self)
                    guard let `bar` else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    self.`bar` = `bar`
                  }
                }
                """#
            }
        }

        @Test func capitalSelf() {
            assertMacro {
                """
                @Table
                struct Foo {
                  var bar: ID<Self>
                }
                """
            } expansion: {
                #"""
                struct Foo {
                  var bar: ID<Self>

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                    public typealias QueryValue = Foo
                    public let bar = SQLQueryExpression(_TableColumn<QueryValue, ID<Foo>>.for("bar", keyPath: \QueryValue.bar)
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.bar._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.bar._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.bar)"
                    }
                  }

                  public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = Foo
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public init(
                      bar: some SQLQueryExpression(QueryExpression<ID<Foo>>
                    ) {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: bar._allColumns)
                      self.allColumns = allColumns
                    }
                  }
                }

                nonisolated extension Foo: SQLQueryExpression(Table, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    var columnWidth = 0
                    columnWidth += ID<Foo>._columnWidth
                    return columnWidth
                  }
                  public nonisolated static var tableName: String {
                    "foos"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    let bar = try decoder.decode(ID<Foo>.self)
                    guard let bar else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    self.bar = bar
                  }
                }
                """#
            }
        }

        @Test func capitalSelfDefault() {
            assertMacro {
                """
                @Table
                struct Foo {
                  var bar = ID<Self>()
                }
                """
            } expansion: {
                #"""
                struct Foo {
                  var bar = ID<Self>()

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                    public typealias QueryValue = Foo
                    public let bar = SQLQueryExpression(_TableColumn<QueryValue, _>.for("bar", keyPath: \QueryValue.bar, default: ID<Foo>())
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.bar._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.bar._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.bar)"
                    }
                  }

                  public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = Foo
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public init(
                      bar: some SQLQueryExpression(QueryExpression
                    ) {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: bar._allColumns)
                      self.allColumns = allColumns
                    }
                  }
                }

                nonisolated extension Foo: SQLQueryExpression(Table, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    var columnWidth = 0
                    columnWidth += ._columnWidth
                    return columnWidth
                  }
                  public nonisolated static var tableName: String {
                    "foos"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    self.bar = try decoder.decode() ?? ID<Foo>()
                  }
                }
                """#
            }
        }

        @Test func capitalSelfPrimaryKey() {
            assertMacro {
                """
                @Table
                struct User {
                  @Column(as: ID<Self, UUID.BytesRepresentation>.self)
                  let id: ID<Self, UUID>
                  @Column(as: ID<Self, UUID.BytesRepresentation>?.self)
                  var referrerID: ID<Self, UUID>?
                }
                """
            } expansion: {
                #"""
                struct User {
                  let id: ID<Self, UUID>
                  var referrerID: ID<Self, UUID>?

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition, SQLQueryExpression(PrimaryKeyedTableDefinition {
                    public typealias QueryValue = User
                    public typealias PrimaryKey = ID<User, UUID.BytesRepresentation>
                    public let id = SQLQueryExpression(TableColumn<QueryValue, ID<User, UUID.BytesRepresentation>>("id", keyPath: \QueryValue.id)
                    public let primaryKey = SQLQueryExpression(TableColumn<QueryValue, ID<User, UUID.BytesRepresentation>>("id", keyPath: \QueryValue.id)
                    public let referrerID = SQLQueryExpression(TableColumn<QueryValue, ID<User, UUID.BytesRepresentation>?>("referrerID", keyPath: \QueryValue.referrerID, default: nil)
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                      allColumns.append(contentsOf: QueryValue.columns.referrerID._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                      writableColumns.append(contentsOf: QueryValue.columns.referrerID._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.id), \(self.referrerID)"
                    }
                  }

                  public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = User
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public init(
                      id: some SQLQueryExpression(QueryExpression<ID<User, UUID.BytesRepresentation>>,
                      referrerID: some SQLQueryExpression(QueryExpression<ID<User, UUID.BytesRepresentation>?> = ID<User, UUID.BytesRepresentation>?(queryOutput: nil)
                    ) {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: id._allColumns)
                      allColumns.append(contentsOf: referrerID._allColumns)
                      self.allColumns = allColumns
                    }
                  }

                  public struct Draft: SQLQueryExpression(TableDraft {
                    public typealias PrimaryTable = User
                    let id: ID<User, UUID>?
                    var referrerID: ID<User, UUID>?
                    public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                      public typealias QueryValue = Draft
                      public let id = SQLQueryExpression(TableColumn<QueryValue, ID<User, UUID.BytesRepresentation>?>("id", keyPath: \QueryValue.id, default: nil)
                      public let referrerID = SQLQueryExpression(TableColumn<QueryValue, ID<User, UUID.BytesRepresentation>?>("referrerID", keyPath: \QueryValue.referrerID, default: nil)
                      public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                        var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                        allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                        allColumns.append(contentsOf: QueryValue.columns.referrerID._allColumns)
                        return allColumns
                      }
                      public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                        var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                        writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                        writableColumns.append(contentsOf: QueryValue.columns.referrerID._writableColumns)
                        return writableColumns
                      }
                      public var queryFragment: QueryFragment {
                        "\(self.id), \(self.referrerID)"
                      }
                    }
                    public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                      public typealias QueryValue = Draft
                      public let allColumns: [any SQLQueryExpression(QueryExpression]
                      public init(
                        id: some SQLQueryExpression(QueryExpression<ID<User, UUID.BytesRepresentation>?> = ID<User, UUID.BytesRepresentation>?(queryOutput: nil),
                        referrerID: some SQLQueryExpression(QueryExpression<ID<User, UUID.BytesRepresentation>?> = ID<User, UUID.BytesRepresentation>?(queryOutput: nil)
                      ) {
                        var allColumns: [any SQLQueryExpression(QueryExpression] = []
                        allColumns.append(contentsOf: id._allColumns)
                        allColumns.append(contentsOf: referrerID._allColumns)
                        self.allColumns = allColumns
                      }
                    }
                    public typealias QueryValue = Self

                    public typealias From = Swift.Never

                    public nonisolated static var columns: TableColumns {
                      TableColumns()
                    }

                    public nonisolated static var _columnWidth: Int {
                      var columnWidth = 0
                      columnWidth += ID<User, UUID.BytesRepresentation>?._columnWidth
                      columnWidth += ID<User, UUID.BytesRepresentation>?._columnWidth
                      return columnWidth
                    }

                    public nonisolated static var tableName: String {
                      User.tableName
                    }

                    public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                      self.id = try decoder.decode(ID<User, UUID.BytesRepresentation>.self) ?? nil
                      self.referrerID = try decoder.decode(ID<User, UUID.BytesRepresentation>.self) ?? nil
                    }

                    public nonisolated init(_ other: User) {
                      self.id = other.id
                      self.referrerID = other.referrerID
                    }
                    public init(
                      id: ID<User, UUID>? = nil,
                      referrerID: ID<User, UUID>? = nil
                    ) {
                      self.id = id
                      self.referrerID = referrerID
                    }
                  }
                }

                nonisolated extension User: SQLQueryExpression(Table, SQLQueryExpression(PrimaryKeyedTable, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    var columnWidth = 0
                    columnWidth += ID<User, UUID.BytesRepresentation>._columnWidth
                    columnWidth += ID<User, UUID.BytesRepresentation>?._columnWidth
                    return columnWidth
                  }
                  public nonisolated static var tableName: String {
                    "users"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    let id = try decoder.decode(ID<User, UUID.BytesRepresentation>.self)
                    self.referrerID = try decoder.decode(ID<User, UUID.BytesRepresentation>.self) ?? nil
                    guard let id else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    self.id = id
                  }
                }
                """#
            }
        }

        @Test func ephemeralField() {
            assertMacro {
                """
                @Table struct SyncUp {
                  var name: String
                  @Ephemeral
                  var computed: Int
                }
                """
            } expansion: {
                #"""
                struct SyncUp {
                  var name: String
                  var computed: Int

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                    public typealias QueryValue = SyncUp
                    public let name = SQLQueryExpression(_TableColumn<QueryValue, String>.for("name", keyPath: \QueryValue.name)
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.name)"
                    }
                  }

                  public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = SyncUp
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public init(
                      name: some SQLQueryExpression(QueryExpression<String>
                    ) {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: name._allColumns)
                      self.allColumns = allColumns
                    }
                  }
                }

                nonisolated extension SyncUp: SQLQueryExpression(Table, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    var columnWidth = 0
                    columnWidth += String._columnWidth
                    return columnWidth
                  }
                  public nonisolated static var tableName: String {
                    "syncUps"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    let name = try decoder.decode(String.self)
                    guard let name else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    self.name = name
                  }
                }
                """#
            }
        }

        @Test func ephemeralFieldPrimaryKeyedTable() {
            assertMacro {
                """
                @Table struct SyncUp {
                  let id: Int
                  var name: String
                  @Ephemeral
                  var computed: Int
                }
                """
            } expansion: {
                #"""
                struct SyncUp {
                  let id: Int
                  var name: String
                  var computed: Int

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition, SQLQueryExpression(PrimaryKeyedTableDefinition {
                    public typealias QueryValue = SyncUp
                    public typealias PrimaryKey = Int
                    public let id = SQLQueryExpression(_TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
                    public let primaryKey = SQLQueryExpression(_TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
                    public let name = SQLQueryExpression(_TableColumn<QueryValue, String>.for("name", keyPath: \QueryValue.name)
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                      allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                      writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.id), \(self.name)"
                    }
                  }

                  public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = SyncUp
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public init(
                      id: some SQLQueryExpression(QueryExpression<Int>,
                      name: some SQLQueryExpression(QueryExpression<String>
                    ) {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: id._allColumns)
                      allColumns.append(contentsOf: name._allColumns)
                      self.allColumns = allColumns
                    }
                  }

                  public struct Draft: SQLQueryExpression(TableDraft {
                    public typealias PrimaryTable = SyncUp
                    let id: Int?
                    var name: String
                    public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                      public typealias QueryValue = Draft
                      public let id = SQLQueryExpression(_TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
                      public let name = SQLQueryExpression(_TableColumn<QueryValue, String>.for("name", keyPath: \QueryValue.name)
                      public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                        var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                        allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                        allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
                        return allColumns
                      }
                      public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                        var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                        writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                        writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
                        return writableColumns
                      }
                      public var queryFragment: QueryFragment {
                        "\(self.id), \(self.name)"
                      }
                    }
                    public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                      public typealias QueryValue = Draft
                      public let allColumns: [any SQLQueryExpression(QueryExpression]
                      public init(
                        id: some SQLQueryExpression(QueryExpression<Int?> = Int?(queryOutput: nil),
                        name: some SQLQueryExpression(QueryExpression<String>
                      ) {
                        var allColumns: [any SQLQueryExpression(QueryExpression] = []
                        allColumns.append(contentsOf: id._allColumns)
                        allColumns.append(contentsOf: name._allColumns)
                        self.allColumns = allColumns
                      }
                    }
                    public typealias QueryValue = Self

                    public typealias From = Swift.Never

                    public nonisolated static var columns: TableColumns {
                      TableColumns()
                    }

                    public nonisolated static var _columnWidth: Int {
                      var columnWidth = 0
                      columnWidth += Int?._columnWidth
                      columnWidth += String._columnWidth
                      return columnWidth
                    }

                    public nonisolated static var tableName: String {
                      SyncUp.tableName
                    }

                    public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                      self.id = try decoder.decode(Int.self) ?? nil
                      let name = try decoder.decode(String.self)
                      guard let name else {
                        throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                      }
                      self.name = name
                    }

                    public nonisolated init(_ other: SyncUp) {
                      self.id = other.id
                      self.name = other.name
                    }
                    public init(
                      id: Int? = nil,
                      name: String
                    ) {
                      self.id = id
                      self.name = name
                    }
                  }
                }

                nonisolated extension SyncUp: SQLQueryExpression(Table, SQLQueryExpression(PrimaryKeyedTable, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    var columnWidth = 0
                    columnWidth += Int._columnWidth
                    columnWidth += String._columnWidth
                    return columnWidth
                  }
                  public nonisolated static var tableName: String {
                    "syncUps"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    let id = try decoder.decode(Int.self)
                    let name = try decoder.decode(String.self)
                    guard let id else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    guard let name else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    self.id = id
                    self.name = name
                  }
                }
                """#
            }
        }

        @Test func noType() {
            assertMacro {
                """
                @Table struct SyncUp {
                  let id: Int
                  var seconds = 60 * 5
                }
                """
            } diagnostics: {
                """
                @Table struct SyncUp {
                  let id: Int
                  var seconds = 60 * 5
                      ┬───────────────
                      ╰─ 🛑 '@Table' requires 'seconds' to have a type annotation in order to generate a memberwise initializer
                         ✏️ Insert ': <#Type#>'
                }
                """
            } fixes: {
                """
                @Table struct SyncUp {
                  let id: Int
                  var seconds: <#Type#> = 60 * 5
                }
                """
            } expansion: {
                #"""
                struct SyncUp {
                  let id: Int
                  var seconds: <#Type#> = 60 * 5

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition, SQLQueryExpression(PrimaryKeyedTableDefinition {
                    public typealias QueryValue = SyncUp
                    public typealias PrimaryKey = Int
                    public let id = SQLQueryExpression(_TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
                    public let primaryKey = SQLQueryExpression(_TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
                    public let seconds = SQLQueryExpression(_TableColumn<QueryValue, <#Type#>>.for("seconds", keyPath: \QueryValue.seconds, default: 60 * 5)
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                      allColumns.append(contentsOf: QueryValue.columns.seconds._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                      writableColumns.append(contentsOf: QueryValue.columns.seconds._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.id), \(self.seconds)"
                    }
                  }

                  public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = SyncUp
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public init(
                      id: some SQLQueryExpression(QueryExpression<Int>,
                      seconds: some SQLQueryExpression(QueryExpression<<#Type#>> = <#Type#>(queryOutput: 60 * 5)
                    ) {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: id._allColumns)
                      allColumns.append(contentsOf: seconds._allColumns)
                      self.allColumns = allColumns
                    }
                  }

                  public struct Draft: SQLQueryExpression(TableDraft {
                    public typealias PrimaryTable = SyncUp
                    let id: Int?
                    var seconds: <#Type#> = 60 * 5
                    public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                      public typealias QueryValue = Draft
                      public let id = SQLQueryExpression(_TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
                      public let seconds = SQLQueryExpression(_TableColumn<QueryValue, <#Type#>>.for("seconds", keyPath: \QueryValue.seconds, default: 60 * 5)
                      public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                        var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                        allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                        allColumns.append(contentsOf: QueryValue.columns.seconds._allColumns)
                        return allColumns
                      }
                      public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                        var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                        writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                        writableColumns.append(contentsOf: QueryValue.columns.seconds._writableColumns)
                        return writableColumns
                      }
                      public var queryFragment: QueryFragment {
                        "\(self.id), \(self.seconds)"
                      }
                    }
                    public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                      public typealias QueryValue = Draft
                      public let allColumns: [any SQLQueryExpression(QueryExpression]
                      public init(
                        id: some SQLQueryExpression(QueryExpression<Int?> = Int?(queryOutput: nil),
                        seconds: some SQLQueryExpression(QueryExpression<<#Type#>> = <#Type#>(queryOutput: 60 * 5)
                      ) {
                        var allColumns: [any SQLQueryExpression(QueryExpression] = []
                        allColumns.append(contentsOf: id._allColumns)
                        allColumns.append(contentsOf: seconds._allColumns)
                        self.allColumns = allColumns
                      }
                    }
                    public typealias QueryValue = Self

                    public typealias From = Swift.Never

                    public nonisolated static var columns: TableColumns {
                      TableColumns()
                    }

                    public nonisolated static var _columnWidth: Int {
                      var columnWidth = 0
                      columnWidth += Int?._columnWidth
                      columnWidth += <#Type#>._columnWidth
                      return columnWidth
                    }

                    public nonisolated static var tableName: String {
                      SyncUp.tableName
                    }

                    public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                      self.id = try decoder.decode(Int.self) ?? nil
                      self.seconds = try decoder.decode(<#Type#>.self) ?? 60 * 5
                    }

                    public nonisolated init(_ other: SyncUp) {
                      self.id = other.id
                      self.seconds = other.seconds
                    }
                    public init(
                      id: Int? = nil,
                      seconds: <#Type#> = 60 * 5
                    ) {
                      self.id = id
                      self.seconds = seconds
                    }
                  }
                }

                nonisolated extension SyncUp: SQLQueryExpression(Table, SQLQueryExpression(PrimaryKeyedTable, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    var columnWidth = 0
                    columnWidth += Int._columnWidth
                    columnWidth += <#Type#>._columnWidth
                    return columnWidth
                  }
                  public nonisolated static var tableName: String {
                    "syncUps"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    let id = try decoder.decode(Int.self)
                    self.seconds = try decoder.decode(<#Type#>.self) ?? 60 * 5
                    guard let id else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    self.id = id
                  }
                }
                """#
            }
        }

        @Test func noTypeWithAs() {
            assertMacro {
                """
                @Table
                struct RemindersList: Hashable, Identifiable {
                  var id: Int
                  @Column(as: Color.HexRepresentation.self)
                  var color = Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255)
                  var name = ""
                }
                """
            } expansion: {
                #"""
                struct RemindersList: Hashable, Identifiable {
                  var id: Int
                  var color = Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255)
                  var name = ""

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition, SQLQueryExpression(PrimaryKeyedTableDefinition {
                    public typealias QueryValue = RemindersList
                    public typealias PrimaryKey = Int
                    public let id = SQLQueryExpression(_TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
                    public let primaryKey = SQLQueryExpression(_TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
                    public let color = SQLQueryExpression(TableColumn<QueryValue, Color.HexRepresentation>("color", keyPath: \QueryValue.color, default: Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255))
                    public let name = SQLQueryExpression(_TableColumn<QueryValue, Swift.String>.for("name", keyPath: \QueryValue.name, default: "")
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                      allColumns.append(contentsOf: QueryValue.columns.color._allColumns)
                      allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                      writableColumns.append(contentsOf: QueryValue.columns.color._writableColumns)
                      writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.id), \(self.color), \(self.name)"
                    }
                  }

                  public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = RemindersList
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public init(
                      id: some SQLQueryExpression(QueryExpression<Int>,
                      color: some SQLQueryExpression(QueryExpression<Color.HexRepresentation> = Color.HexRepresentation(queryOutput: Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255)),
                      name: some SQLQueryExpression(QueryExpression<Swift.String> = Swift.String(queryOutput: "")
                    ) {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: id._allColumns)
                      allColumns.append(contentsOf: color._allColumns)
                      allColumns.append(contentsOf: name._allColumns)
                      self.allColumns = allColumns
                    }
                  }

                  public struct Draft: SQLQueryExpression(TableDraft {
                    public typealias PrimaryTable = RemindersList
                    var id: Int?
                    var color = Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255)
                    var name = ""
                    public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                      public typealias QueryValue = Draft
                      public let id = SQLQueryExpression(_TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
                      public let color = SQLQueryExpression(TableColumn<QueryValue, Color.HexRepresentation>("color", keyPath: \QueryValue.color, default: Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255))
                      public let name = SQLQueryExpression(_TableColumn<QueryValue, Swift.String>.for("name", keyPath: \QueryValue.name, default: "")
                      public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                        var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                        allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                        allColumns.append(contentsOf: QueryValue.columns.color._allColumns)
                        allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
                        return allColumns
                      }
                      public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                        var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                        writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                        writableColumns.append(contentsOf: QueryValue.columns.color._writableColumns)
                        writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
                        return writableColumns
                      }
                      public var queryFragment: QueryFragment {
                        "\(self.id), \(self.color), \(self.name)"
                      }
                    }
                    public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                      public typealias QueryValue = Draft
                      public let allColumns: [any SQLQueryExpression(QueryExpression]
                      public init(
                        id: some SQLQueryExpression(QueryExpression<Int?> = Int?(queryOutput: nil),
                        color: some SQLQueryExpression(QueryExpression<Color.HexRepresentation> = Color.HexRepresentation(queryOutput: Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255)),
                        name: some SQLQueryExpression(QueryExpression<Swift.String> = Swift.String(queryOutput: "")
                      ) {
                        var allColumns: [any SQLQueryExpression(QueryExpression] = []
                        allColumns.append(contentsOf: id._allColumns)
                        allColumns.append(contentsOf: color._allColumns)
                        allColumns.append(contentsOf: name._allColumns)
                        self.allColumns = allColumns
                      }
                    }
                    public typealias QueryValue = Self

                    public typealias From = Swift.Never

                    public nonisolated static var columns: TableColumns {
                      TableColumns()
                    }

                    public nonisolated static var _columnWidth: Int {
                      var columnWidth = 0
                      columnWidth += Int?._columnWidth
                      columnWidth += Color.HexRepresentation._columnWidth
                      columnWidth += Swift.String._columnWidth
                      return columnWidth
                    }

                    public nonisolated static var tableName: String {
                      RemindersList.tableName
                    }

                    public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                      self.id = try decoder.decode(Int.self) ?? nil
                      self.color = try decoder.decode(Color.HexRepresentation.self) ?? Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255)
                      self.name = try decoder.decode(Swift.String.self) ?? ""
                    }

                    public nonisolated init(_ other: RemindersList) {
                      self.id = other.id
                      self.color = other.color
                      self.name = other.name
                    }
                    public init(
                      id: Int? = nil,
                      color: Color.HexRepresentation.QueryOutput = Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255),
                      name: Swift.String = ""
                    ) {
                      self.id = id
                      self.color = color
                      self.name = name
                    }
                  }
                }

                nonisolated extension RemindersList: SQLQueryExpression(Table, SQLQueryExpression(PrimaryKeyedTable, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    var columnWidth = 0
                    columnWidth += Int._columnWidth
                    columnWidth += Color.HexRepresentation._columnWidth
                    columnWidth += Swift.String._columnWidth
                    return columnWidth
                  }
                  public nonisolated static var tableName: String {
                    "remindersLists"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    let id = try decoder.decode(Int.self)
                    self.color = try decoder.decode(Color.HexRepresentation.self) ?? Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255)
                    self.name = try decoder.decode(Swift.String.self) ?? ""
                    guard let id else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    self.id = id
                  }
                }
                """#
            }
        }

        @Test func emptyStruct() {
            assertMacro {
                """
                @Table
                struct Foo {
                }
                """
            } diagnostics: {
                """
                @Table
                ┬─────
                ╰─ 🛑 '@Table' requires at least one stored column property to be defined on 'Foo'
                struct Foo {
                }
                """
            }
        }
    }

    @Test func willSet() {
        assertMacro {
            """
            @Table
            struct Foo {
              var name: String {
                willSet { print(newValue) }
              }
            }
            """
        } expansion: {
            #"""
            struct Foo {
              var name: String {
                willSet { print(newValue) }
              }

              public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                public typealias QueryValue = Foo
                public let name = SQLQueryExpression(_TableColumn<QueryValue, String>.for("name", keyPath: \QueryValue.name)
                public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                  var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                  allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
                  return allColumns
                }
                public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                  var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                  writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
                  return writableColumns
                }
                public var queryFragment: QueryFragment {
                  "\(self.name)"
                }
              }

              public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                public typealias QueryValue = Foo
                public let allColumns: [any SQLQueryExpression(QueryExpression]
                public init(
                  name: some SQLQueryExpression(QueryExpression<String>
                ) {
                  var allColumns: [any SQLQueryExpression(QueryExpression] = []
                  allColumns.append(contentsOf: name._allColumns)
                  self.allColumns = allColumns
                }
              }
            }

            nonisolated extension Foo: SQLQueryExpression(Table, SQLQueryExpression(PartialSelectStatement {
              public typealias QueryValue = Self
              public typealias From = Swift.Never
              public nonisolated static var columns: TableColumns {
                TableColumns()
              }
              public nonisolated static var _columnWidth: Int {
                var columnWidth = 0
                columnWidth += String._columnWidth
                return columnWidth
              }
              public nonisolated static var tableName: String {
                "foos"
              }
              public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                let name = try decoder.decode(String.self)
                guard let name else {
                  throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                }
                self.name = name
              }
            }
            """#
        }
    }

    #if StructuredQueriesPostgresCasePaths
        @Test func enumBasics() {
            assertMacro {
                """
                @CasePathable @Table
                enum Post {
                  @Columns
                  case photo(Photo)
                  case note(String = "")
                }
                """
            } expansion: {
                #"""
                @CasePathable
                enum Post {
                  case photo(Photo)
                  case note(String = "")

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                    public typealias QueryValue = Post
                    public let photo = SQLQueryExpression(ColumnGroup<QueryValue, Photo?>(keyPath: \QueryValue.photo)
                    public let note = SQLQueryExpression(_TableColumn<QueryValue, String?>.for("note", keyPath: \QueryValue.note, default: "")
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.photo._allColumns)
                      allColumns.append(contentsOf: QueryValue.columns.note._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.photo._writableColumns)
                      writableColumns.append(contentsOf: QueryValue.columns.note._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.photo), \(self.note)"
                    }
                  }

                  public struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = Post
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public static func photo(
                      _ photo: some SQLQueryExpression(QueryExpression<Photo>
                    ) -> Self {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: photo._allColumns)
                      allColumns.append(contentsOf: Photo?(queryOutput: nil)._allColumns)
                      return Self(allColumns: allColumns)
                    }
                    public static func note(
                      _ note: some SQLQueryExpression(QueryExpression<String>
                    ) -> Self {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: String?(queryOutput: nil)._allColumns)
                      allColumns.append(contentsOf: note._allColumns)
                      return Self(allColumns: allColumns)
                    }
                  }
                }

                nonisolated extension Post: SQLQueryExpression(Table, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    [Photo._columnWidth, String._columnWidth].reduce(0, +)
                  }
                  public nonisolated static var tableName: String {
                    "posts"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    if let photo = try decoder.decode(Photo.self) {
                      self = .photo(photo)
                    } else if let note = try decoder.decode(String.self) {
                      self = .note(note)
                    } else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                  }
                }
                """#
            }
        }

        @Test func enumDiagnostic() {
            assertMacro {
                """
                @Table
                enum Post {
                  case photo(Photo)
                  case note(String = "")
                }
                """
            } diagnostics: {
                """
                @Table
                ┬─────
                ╰─ 🛑 '@Table' enum type missing required '@CasePathable' macro application
                   ✏️ Insert '@CasePathable'
                enum Post {
                  case photo(Photo)
                  case note(String = "")
                }
                """
            } fixes: {
                """
                @CasePathable @Table
                enum Post {
                  case photo(Photo)
                  case note(String = "")
                }
                """
            } expansion: {
                #"""
                @CasePathable
                enum Post {
                  case photo(Photo)
                  case note(String = "")

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                    public typealias QueryValue = Post
                    public let photo = SQLQueryExpression(_TableColumn<QueryValue, Photo?>.for("photo", keyPath: \QueryValue.photo)
                    public let note = SQLQueryExpression(_TableColumn<QueryValue, String?>.for("note", keyPath: \QueryValue.note, default: "")
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.photo._allColumns)
                      allColumns.append(contentsOf: QueryValue.columns.note._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.photo._writableColumns)
                      writableColumns.append(contentsOf: QueryValue.columns.note._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.photo), \(self.note)"
                    }
                  }

                  public struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = Post
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public static func photo(
                      _ photo: some SQLQueryExpression(QueryExpression<Photo>
                    ) -> Self {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: photo._allColumns)
                      allColumns.append(contentsOf: Photo?(queryOutput: nil)._allColumns)
                      return Self(allColumns: allColumns)
                    }
                    public static func note(
                      _ note: some SQLQueryExpression(QueryExpression<String>
                    ) -> Self {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: String?(queryOutput: nil)._allColumns)
                      allColumns.append(contentsOf: note._allColumns)
                      return Self(allColumns: allColumns)
                    }
                  }
                }

                nonisolated extension Post: SQLQueryExpression(Table, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    [Photo._columnWidth, String._columnWidth].reduce(0, +)
                  }
                  public nonisolated static var tableName: String {
                    "posts"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    if let photo = try decoder.decode(Photo.self) {
                      self = .photo(photo)
                    } else if let note = try decoder.decode(String.self) {
                      self = .note(note)
                    } else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                  }
                }
                """#
            }
        }

        @Test func enumDiagnostic_SingleLine() {
            assertMacro {
                """
                @Table enum Post {
                  case photo(Photo)
                  case note(String = "")
                }
                """
            } diagnostics: {
                """
                @Table enum Post {
                ┬─────
                ╰─ 🛑 '@Table' enum type missing required '@CasePathable' macro application
                   ✏️ Insert '@CasePathable'
                  case photo(Photo)
                  case note(String = "")
                }
                """
            } fixes: {
                """
                @CasePathable @Table enum Post {
                  case photo(Photo)
                  case note(String = "")
                }
                """
            } expansion: {
                #"""
                @CasePathable enum Post {
                  case photo(Photo)
                  case note(String = "")

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                    public typealias QueryValue = Post
                    public let photo = SQLQueryExpression(_TableColumn<QueryValue, Photo?>.for("photo", keyPath: \QueryValue.photo)
                    public let note = SQLQueryExpression(_TableColumn<QueryValue, String?>.for("note", keyPath: \QueryValue.note, default: "")
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.photo._allColumns)
                      allColumns.append(contentsOf: QueryValue.columns.note._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.photo._writableColumns)
                      writableColumns.append(contentsOf: QueryValue.columns.note._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.photo), \(self.note)"
                    }
                  }

                  public struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = Post
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public static func photo(
                      _ photo: some SQLQueryExpression(QueryExpression<Photo>
                    ) -> Self {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: photo._allColumns)
                      allColumns.append(contentsOf: Photo?(queryOutput: nil)._allColumns)
                      return Self(allColumns: allColumns)
                    }
                    public static func note(
                      _ note: some SQLQueryExpression(QueryExpression<String>
                    ) -> Self {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: String?(queryOutput: nil)._allColumns)
                      allColumns.append(contentsOf: note._allColumns)
                      return Self(allColumns: allColumns)
                    }
                  }
                }

                nonisolated extension Post: SQLQueryExpression(Table, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    [Photo._columnWidth, String._columnWidth].reduce(0, +)
                  }
                  public nonisolated static var tableName: String {
                    "posts"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    if let photo = try decoder.decode(Photo.self) {
                      self = .photo(photo)
                    } else if let note = try decoder.decode(String.self) {
                      self = .note(note)
                    } else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                  }
                }
                """#
            }
        }

        @Test func enumFirstNames() {
            assertMacro {
                """
                @CasePathable @Table
                enum Post {
                  case photo(Photo)
                  case note(text: String = "")
                }
                """
            } expansion: {
                #"""
                @CasePathable
                enum Post {
                  case photo(Photo)
                  case note(text: String = "")

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                    public typealias QueryValue = Post
                    public let photo = SQLQueryExpression(_TableColumn<QueryValue, Photo?>.for("photo", keyPath: \QueryValue.photo)
                    public let note = SQLQueryExpression(_TableColumn<QueryValue, String?>.for("note", keyPath: \QueryValue.note, default: "")
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.photo._allColumns)
                      allColumns.append(contentsOf: QueryValue.columns.note._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.photo._writableColumns)
                      writableColumns.append(contentsOf: QueryValue.columns.note._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.photo), \(self.note)"
                    }
                  }

                  public struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = Post
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public static func photo(
                      _ photo: some SQLQueryExpression(QueryExpression<Photo>
                    ) -> Self {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: photo._allColumns)
                      allColumns.append(contentsOf: Photo?(queryOutput: nil)._allColumns)
                      return Self(allColumns: allColumns)
                    }
                    public static func note(
                      text note: some SQLQueryExpression(QueryExpression<String>
                    ) -> Self {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: String?(queryOutput: nil)._allColumns)
                      allColumns.append(contentsOf: note._allColumns)
                      return Self(allColumns: allColumns)
                    }
                  }
                }

                nonisolated extension Post: SQLQueryExpression(Table, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    [Photo._columnWidth, String._columnWidth].reduce(0, +)
                  }
                  public nonisolated static var tableName: String {
                    "posts"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    if let photo = try decoder.decode(Photo.self) {
                      self = .photo(photo)
                    } else if let note = try decoder.decode(String.self) {
                      self = .note(note)
                    } else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                  }
                }
                """#
            }
        }

        @Test func enumCustomColumn() {
            assertMacro {
                """
                @CasePathable @Table
                enum Post {
                  @Column("note_text")
                  case note(text: String = "")
                }
                """
            } expansion: {
                #"""
                @CasePathable
                enum Post {
                  case note(text: String = "")

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                    public typealias QueryValue = Post
                    public let note = SQLQueryExpression(TableColumn<QueryValue, String?>("note_text", keyPath: \QueryValue.note, default: "")
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.note._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.note._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.note)"
                    }
                  }

                  public struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = Post
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public static func note(
                      text note: some SQLQueryExpression(QueryExpression<String>
                    ) -> Self {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: note._allColumns)
                      return Self(allColumns: allColumns)
                    }
                  }
                }

                nonisolated extension Post: SQLQueryExpression(Table, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    [String._columnWidth].reduce(0, +)
                  }
                  public nonisolated static var tableName: String {
                    "posts"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    if let note = try decoder.decode(String.self) {
                      self = .note(note)
                    } else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                  }
                }
                """#
            }
        }

        @Test func enumCustomRepresentation() {
            assertMacro {
                """
                @CasePathable @Table
                enum Post {
                  @Column(as: Date.UnixTimeRepresentation.self)
                  case timestamp(Date)
                }
                """
            } expansion: {
                #"""
                @CasePathable
                enum Post {
                  case timestamp(Date)

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                    public typealias QueryValue = Post
                    public let timestamp = SQLQueryExpression(TableColumn<QueryValue, Date.UnixTimeRepresentation?>("timestamp", keyPath: \QueryValue.timestamp)
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.timestamp._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.timestamp._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.timestamp)"
                    }
                  }

                  public struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = Post
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public static func timestamp(
                      _ timestamp: some SQLQueryExpression(QueryExpression<Date.UnixTimeRepresentation>
                    ) -> Self {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: timestamp._allColumns)
                      return Self(allColumns: allColumns)
                    }
                  }
                }

                nonisolated extension Post: SQLQueryExpression(Table, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    [Date.UnixTimeRepresentation._columnWidth].reduce(0, +)
                  }
                  public nonisolated static var tableName: String {
                    "posts"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    if let timestamp = try decoder.decode(Date.UnixTimeRepresentation.self) {
                      self = .timestamp(timestamp)
                    } else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                  }
                }
                """#
            }
        }
    #endif

    @MainActor
    @Suite struct PrimaryKeyTests {
        @Test func basics() {
            assertMacro {
                """
                @Table
                struct Foo {
                  let id: Int
                }
                """
            } expansion: {
                #"""
                struct Foo {
                  let id: Int

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition, SQLQueryExpression(PrimaryKeyedTableDefinition {
                    public typealias QueryValue = Foo
                    public typealias PrimaryKey = Int
                    public let id = SQLQueryExpression(_TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
                    public let primaryKey = SQLQueryExpression(_TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.id)"
                    }
                  }

                  public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = Foo
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public init(
                      id: some SQLQueryExpression(QueryExpression<Int>
                    ) {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: id._allColumns)
                      self.allColumns = allColumns
                    }
                  }

                  public struct Draft: SQLQueryExpression(TableDraft {
                    public typealias PrimaryTable = Foo
                    let id: Int?
                    public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                      public typealias QueryValue = Draft
                      public let id = SQLQueryExpression(_TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
                      public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                        var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                        allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                        return allColumns
                      }
                      public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                        var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                        writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                        return writableColumns
                      }
                      public var queryFragment: QueryFragment {
                        "\(self.id)"
                      }
                    }
                    public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                      public typealias QueryValue = Draft
                      public let allColumns: [any SQLQueryExpression(QueryExpression]
                      public init(
                        id: some SQLQueryExpression(QueryExpression<Int?> = Int?(queryOutput: nil)
                      ) {
                        var allColumns: [any SQLQueryExpression(QueryExpression] = []
                        allColumns.append(contentsOf: id._allColumns)
                        self.allColumns = allColumns
                      }
                    }
                    public typealias QueryValue = Self

                    public typealias From = Swift.Never

                    public nonisolated static var columns: TableColumns {
                      TableColumns()
                    }

                    public nonisolated static var _columnWidth: Int {
                      var columnWidth = 0
                      columnWidth += Int?._columnWidth
                      return columnWidth
                    }

                    public nonisolated static var tableName: String {
                      Foo.tableName
                    }

                    public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                      self.id = try decoder.decode(Int.self) ?? nil
                    }

                    public nonisolated init(_ other: Foo) {
                      self.id = other.id
                    }
                    public init(
                      id: Int? = nil
                    ) {
                      self.id = id
                    }
                  }
                }

                nonisolated extension Foo: SQLQueryExpression(Table, SQLQueryExpression(PrimaryKeyedTable, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    var columnWidth = 0
                    columnWidth += Int._columnWidth
                    return columnWidth
                  }
                  public nonisolated static var tableName: String {
                    "foos"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    let id = try decoder.decode(Int.self)
                    guard let id else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    self.id = id
                  }
                }
                """#
            }

            assertMacro {
                #"""
                struct Foo {
                  @Column("id", primaryKey: true)
                  let id: Int
                }

                extension Foo: StructuredQueries.Table {
                  public struct Columns: StructuredQueries.TableDefinition {
                    public typealias QueryValue = Foo
                    public let id = StructuredQueries.Column<QueryValue, Int>("id", keyPath: \QueryValue.id)
                    public var allColumns: [any StructuredQueries.ColumnExpression] {
                      [self.id]
                    }
                  }
                  @_Draft(Foo.self)
                  public struct Draft {
                    @Column(primaryKey: false)
                    let id: Int
                  }
                  public static let columns = Columns()
                  public static let tableName = "foos"
                  public init(decoder: some StructuredQueries.QueryDecoder) throws {
                    self.id = try decoder.decode(Int.self)
                  }
                }
                """#
            } expansion: {
                #"""
                struct Foo {
                  let id: Int
                }

                extension Foo: StructuredQueries.Table {
                  public struct Columns: StructuredQueries.TableDefinition {
                    public typealias QueryValue = Foo
                    public let id = StructuredQueries.Column<QueryValue, Int>("id", keyPath: \QueryValue.id)
                    public var allColumns: [any StructuredQueries.ColumnExpression] {
                      [self.id]
                    }
                  }
                  public struct Draft {
                    let id: Int

                    public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                      public typealias QueryValue = Draft
                      public let id = SQLQueryExpression(TableColumn<QueryValue, Int>("id", keyPath: \QueryValue.id)
                      public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                        var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                        allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                        return allColumns
                      }
                      public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                        var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                        writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                        return writableColumns
                      }
                      public var queryFragment: QueryFragment {
                        "\(self.id)"
                      }
                    }

                    public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                      public typealias QueryValue = Draft
                      public let allColumns: [any SQLQueryExpression(QueryExpression]
                      public init(
                        id: some SQLQueryExpression(QueryExpression<Int>
                      ) {
                        var allColumns: [any SQLQueryExpression(QueryExpression] = []
                        allColumns.append(contentsOf: id._allColumns)
                        self.allColumns = allColumns
                      }
                    }
                  }
                  public static let columns = Columns()
                  public static let tableName = "foos"
                  public init(decoder: some StructuredQueries.QueryDecoder) throws {
                    self.id = try decoder.decode(Int.self)
                  }
                }

                nonisolated extension Foo.Draft: SQLQueryExpression(Table, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    var columnWidth = 0
                    columnWidth += Int._columnWidth
                    return columnWidth
                  }
                  public nonisolated static var tableName: String {
                    Foo.tableName
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    let id = try decoder.decode(Int.self)
                    guard let id else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    self.id = id
                  }
                  public nonisolated init(_ other: Foo) {
                    self.id = other.id
                  }
                }
                """#
            }
        }

        @Test func willSet() {
            assertMacro {
                """
                @Table
                struct Foo {
                  var id: Int {
                    willSet { print(newValue) }
                  }
                  var name: String {
                    willSet { print(newValue) }
                  }
                }
                """
            } expansion: {
                #"""
                struct Foo {
                  var id: Int {
                    willSet { print(newValue) }
                  }
                  var name: String {
                    willSet { print(newValue) }
                  }

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition, SQLQueryExpression(PrimaryKeyedTableDefinition {
                    public typealias QueryValue = Foo
                    public typealias PrimaryKey = Int
                    public let id = SQLQueryExpression(_TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
                    public let primaryKey = SQLQueryExpression(_TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
                    public let name = SQLQueryExpression(_TableColumn<QueryValue, String>.for("name", keyPath: \QueryValue.name)
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                      allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                      writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.id), \(self.name)"
                    }
                  }

                  public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = Foo
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public init(
                      id: some SQLQueryExpression(QueryExpression<Int>,
                      name: some SQLQueryExpression(QueryExpression<String>
                    ) {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: id._allColumns)
                      allColumns.append(contentsOf: name._allColumns)
                      self.allColumns = allColumns
                    }
                  }

                  public struct Draft: SQLQueryExpression(TableDraft {
                    public typealias PrimaryTable = Foo
                    var id: Int?
                    var name: String
                    public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                      public typealias QueryValue = Draft
                      public let id = SQLQueryExpression(_TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
                      public let name = SQLQueryExpression(_TableColumn<QueryValue, String>.for("name", keyPath: \QueryValue.name)
                      public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                        var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                        allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                        allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
                        return allColumns
                      }
                      public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                        var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                        writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                        writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
                        return writableColumns
                      }
                      public var queryFragment: QueryFragment {
                        "\(self.id), \(self.name)"
                      }
                    }
                    public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                      public typealias QueryValue = Draft
                      public let allColumns: [any SQLQueryExpression(QueryExpression]
                      public init(
                        id: some SQLQueryExpression(QueryExpression<Int?> = Int?(queryOutput: nil),
                        name: some SQLQueryExpression(QueryExpression<String>
                      ) {
                        var allColumns: [any SQLQueryExpression(QueryExpression] = []
                        allColumns.append(contentsOf: id._allColumns)
                        allColumns.append(contentsOf: name._allColumns)
                        self.allColumns = allColumns
                      }
                    }
                    public typealias QueryValue = Self

                    public typealias From = Swift.Never

                    public nonisolated static var columns: TableColumns {
                      TableColumns()
                    }

                    public nonisolated static var _columnWidth: Int {
                      var columnWidth = 0
                      columnWidth += Int?._columnWidth
                      columnWidth += String._columnWidth
                      return columnWidth
                    }

                    public nonisolated static var tableName: String {
                      Foo.tableName
                    }

                    public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                      self.id = try decoder.decode(Int.self) ?? nil
                      let name = try decoder.decode(String.self)
                      guard let name else {
                        throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                      }
                      self.name = name
                    }

                    public nonisolated init(_ other: Foo) {
                      self.id = other.id
                      self.name = other.name
                    }
                    public init(
                      id: Int? = nil,
                      name: String
                    ) {
                      self.id = id
                      self.name = name
                    }
                  }
                }

                nonisolated extension Foo: SQLQueryExpression(Table, SQLQueryExpression(PrimaryKeyedTable, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    var columnWidth = 0
                    columnWidth += Int._columnWidth
                    columnWidth += String._columnWidth
                    return columnWidth
                  }
                  public nonisolated static var tableName: String {
                    "foos"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    let id = try decoder.decode(Int.self)
                    let name = try decoder.decode(String.self)
                    guard let id else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    guard let name else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    self.id = id
                    self.name = name
                  }
                }
                """#
            }
        }

        @Test func advanced() {
            assertMacro {
                """
                @Table
                struct Reminder {
                  let id: Int
                  var title = ""
                  @Column(as: Date.UnixTimeRepresentation?.self)
                  var date: Date?
                  var priority: Priority?
                }
                """
            } expansion: {
                #"""
                struct Reminder {
                  let id: Int
                  var title = ""
                  var date: Date?
                  var priority: Priority?

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition, SQLQueryExpression(PrimaryKeyedTableDefinition {
                    public typealias QueryValue = Reminder
                    public typealias PrimaryKey = Int
                    public let id = SQLQueryExpression(_TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
                    public let primaryKey = SQLQueryExpression(_TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
                    public let title = SQLQueryExpression(_TableColumn<QueryValue, Swift.String>.for("title", keyPath: \QueryValue.title, default: "")
                    public let date = SQLQueryExpression(TableColumn<QueryValue, Date.UnixTimeRepresentation?>("date", keyPath: \QueryValue.date, default: nil)
                    public let priority = SQLQueryExpression(_TableColumn<QueryValue, Priority?>.for("priority", keyPath: \QueryValue.priority, default: nil)
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                      allColumns.append(contentsOf: QueryValue.columns.title._allColumns)
                      allColumns.append(contentsOf: QueryValue.columns.date._allColumns)
                      allColumns.append(contentsOf: QueryValue.columns.priority._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                      writableColumns.append(contentsOf: QueryValue.columns.title._writableColumns)
                      writableColumns.append(contentsOf: QueryValue.columns.date._writableColumns)
                      writableColumns.append(contentsOf: QueryValue.columns.priority._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.id), \(self.title), \(self.date), \(self.priority)"
                    }
                  }

                  public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = Reminder
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public init(
                      id: some SQLQueryExpression(QueryExpression<Int>,
                      title: some SQLQueryExpression(QueryExpression<Swift.String> = Swift.String(queryOutput: ""),
                      date: some SQLQueryExpression(QueryExpression<Date.UnixTimeRepresentation?> = Date.UnixTimeRepresentation?(queryOutput: nil),
                      priority: some SQLQueryExpression(QueryExpression<Priority?> = Priority?(queryOutput: nil)
                    ) {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: id._allColumns)
                      allColumns.append(contentsOf: title._allColumns)
                      allColumns.append(contentsOf: date._allColumns)
                      allColumns.append(contentsOf: priority._allColumns)
                      self.allColumns = allColumns
                    }
                  }

                  public struct Draft: SQLQueryExpression(TableDraft {
                    public typealias PrimaryTable = Reminder
                    let id: Int?
                    var title = ""
                    var date: Date?
                    var priority: Priority?
                    public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                      public typealias QueryValue = Draft
                      public let id = SQLQueryExpression(_TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
                      public let title = SQLQueryExpression(_TableColumn<QueryValue, Swift.String>.for("title", keyPath: \QueryValue.title, default: "")
                      public let date = SQLQueryExpression(TableColumn<QueryValue, Date.UnixTimeRepresentation?>("date", keyPath: \QueryValue.date, default: nil)
                      public let priority = SQLQueryExpression(_TableColumn<QueryValue, Priority?>.for("priority", keyPath: \QueryValue.priority, default: nil)
                      public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                        var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                        allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                        allColumns.append(contentsOf: QueryValue.columns.title._allColumns)
                        allColumns.append(contentsOf: QueryValue.columns.date._allColumns)
                        allColumns.append(contentsOf: QueryValue.columns.priority._allColumns)
                        return allColumns
                      }
                      public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                        var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                        writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                        writableColumns.append(contentsOf: QueryValue.columns.title._writableColumns)
                        writableColumns.append(contentsOf: QueryValue.columns.date._writableColumns)
                        writableColumns.append(contentsOf: QueryValue.columns.priority._writableColumns)
                        return writableColumns
                      }
                      public var queryFragment: QueryFragment {
                        "\(self.id), \(self.title), \(self.date), \(self.priority)"
                      }
                    }
                    public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                      public typealias QueryValue = Draft
                      public let allColumns: [any SQLQueryExpression(QueryExpression]
                      public init(
                        id: some SQLQueryExpression(QueryExpression<Int?> = Int?(queryOutput: nil),
                        title: some SQLQueryExpression(QueryExpression<Swift.String> = Swift.String(queryOutput: ""),
                        date: some SQLQueryExpression(QueryExpression<Date.UnixTimeRepresentation?> = Date.UnixTimeRepresentation?(queryOutput: nil),
                        priority: some SQLQueryExpression(QueryExpression<Priority?> = Priority?(queryOutput: nil)
                      ) {
                        var allColumns: [any SQLQueryExpression(QueryExpression] = []
                        allColumns.append(contentsOf: id._allColumns)
                        allColumns.append(contentsOf: title._allColumns)
                        allColumns.append(contentsOf: date._allColumns)
                        allColumns.append(contentsOf: priority._allColumns)
                        self.allColumns = allColumns
                      }
                    }
                    public typealias QueryValue = Self

                    public typealias From = Swift.Never

                    public nonisolated static var columns: TableColumns {
                      TableColumns()
                    }

                    public nonisolated static var _columnWidth: Int {
                      var columnWidth = 0
                      columnWidth += Int?._columnWidth
                      columnWidth += Swift.String._columnWidth
                      columnWidth += Date.UnixTimeRepresentation?._columnWidth
                      columnWidth += Priority?._columnWidth
                      return columnWidth
                    }

                    public nonisolated static var tableName: String {
                      Reminder.tableName
                    }

                    public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                      self.id = try decoder.decode(Int.self) ?? nil
                      self.title = try decoder.decode(Swift.String.self) ?? ""
                      self.date = try decoder.decode(Date.UnixTimeRepresentation.self) ?? nil
                      self.priority = try decoder.decode(Priority.self) ?? nil
                    }

                    public nonisolated init(_ other: Reminder) {
                      self.id = other.id
                      self.title = other.title
                      self.date = other.date
                      self.priority = other.priority
                    }
                    public init(
                      id: Int? = nil,
                      title: Swift.String = "",
                      date: Date? = nil,
                      priority: Priority? = nil
                    ) {
                      self.id = id
                      self.title = title
                      self.date = date
                      self.priority = priority
                    }
                  }
                }

                nonisolated extension Reminder: SQLQueryExpression(Table, SQLQueryExpression(PrimaryKeyedTable, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    var columnWidth = 0
                    columnWidth += Int._columnWidth
                    columnWidth += Swift.String._columnWidth
                    columnWidth += Date.UnixTimeRepresentation?._columnWidth
                    columnWidth += Priority?._columnWidth
                    return columnWidth
                  }
                  public nonisolated static var tableName: String {
                    "reminders"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    let id = try decoder.decode(Int.self)
                    self.title = try decoder.decode(Swift.String.self) ?? ""
                    self.date = try decoder.decode(Date.UnixTimeRepresentation.self) ?? nil
                    self.priority = try decoder.decode(Priority.self) ?? nil
                    guard let id else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    self.id = id
                  }
                }
                """#
            }
        }

        @Test func uuid() {
            assertMacro {
                """
                @Table
                struct Reminder {
                  @Column(as: UUID.BytesRepresentation.self)
                  let id: UUID
                }
                """
            } expansion: {
                #"""
                struct Reminder {
                  let id: UUID

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition, SQLQueryExpression(PrimaryKeyedTableDefinition {
                    public typealias QueryValue = Reminder
                    public typealias PrimaryKey = UUID.BytesRepresentation
                    public let id = SQLQueryExpression(TableColumn<QueryValue, UUID.BytesRepresentation>("id", keyPath: \QueryValue.id)
                    public let primaryKey = SQLQueryExpression(TableColumn<QueryValue, UUID.BytesRepresentation>("id", keyPath: \QueryValue.id)
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.id)"
                    }
                  }

                  public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = Reminder
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public init(
                      id: some SQLQueryExpression(QueryExpression<UUID.BytesRepresentation>
                    ) {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: id._allColumns)
                      self.allColumns = allColumns
                    }
                  }

                  public struct Draft: SQLQueryExpression(TableDraft {
                    public typealias PrimaryTable = Reminder
                    let id: UUID?
                    public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                      public typealias QueryValue = Draft
                      public let id = SQLQueryExpression(TableColumn<QueryValue, UUID.BytesRepresentation?>("id", keyPath: \QueryValue.id, default: nil)
                      public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                        var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                        allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                        return allColumns
                      }
                      public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                        var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                        writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                        return writableColumns
                      }
                      public var queryFragment: QueryFragment {
                        "\(self.id)"
                      }
                    }
                    public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                      public typealias QueryValue = Draft
                      public let allColumns: [any SQLQueryExpression(QueryExpression]
                      public init(
                        id: some SQLQueryExpression(QueryExpression<UUID.BytesRepresentation?> = UUID.BytesRepresentation?(queryOutput: nil)
                      ) {
                        var allColumns: [any SQLQueryExpression(QueryExpression] = []
                        allColumns.append(contentsOf: id._allColumns)
                        self.allColumns = allColumns
                      }
                    }
                    public typealias QueryValue = Self

                    public typealias From = Swift.Never

                    public nonisolated static var columns: TableColumns {
                      TableColumns()
                    }

                    public nonisolated static var _columnWidth: Int {
                      var columnWidth = 0
                      columnWidth += UUID.BytesRepresentation?._columnWidth
                      return columnWidth
                    }

                    public nonisolated static var tableName: String {
                      Reminder.tableName
                    }

                    public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                      self.id = try decoder.decode(UUID.BytesRepresentation.self) ?? nil
                    }

                    public nonisolated init(_ other: Reminder) {
                      self.id = other.id
                    }
                    public init(
                      id: UUID? = nil
                    ) {
                      self.id = id
                    }
                  }
                }

                nonisolated extension Reminder: SQLQueryExpression(Table, SQLQueryExpression(PrimaryKeyedTable, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    var columnWidth = 0
                    columnWidth += UUID.BytesRepresentation._columnWidth
                    return columnWidth
                  }
                  public nonisolated static var tableName: String {
                    "reminders"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    let id = try decoder.decode(UUID.BytesRepresentation.self)
                    guard let id else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    self.id = id
                  }
                }
                """#
            }
        }

        @Test func turnOffPrimaryKey() {
            assertMacro {
                """
                @Table
                struct Reminder {
                  @Column(primaryKey: false)
                  let id: Int
                }
                """
            } expansion: {
                #"""
                struct Reminder {
                  let id: Int

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                    public typealias QueryValue = Reminder
                    public let id = SQLQueryExpression(TableColumn<QueryValue, Int>("id", keyPath: \QueryValue.id)
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.id)"
                    }
                  }

                  public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = Reminder
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public init(
                      id: some SQLQueryExpression(QueryExpression<Int>
                    ) {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: id._allColumns)
                      self.allColumns = allColumns
                    }
                  }
                }

                nonisolated extension Reminder: SQLQueryExpression(Table, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    var columnWidth = 0
                    columnWidth += Int._columnWidth
                    return columnWidth
                  }
                  public nonisolated static var tableName: String {
                    "reminders"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    let id = try decoder.decode(Int.self)
                    guard let id else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    self.id = id
                  }
                }
                """#
            }
        }

        @Test func commentAfterOptionalID() {
            assertMacro {
                """
                @Table
                struct Reminder {
                  let id: Int?  // TODO: Migrate to UUID
                  var title = ""
                }
                """
            } expansion: {
                #"""
                struct Reminder {
                  let id: Int?  // TODO: Migrate to UUID
                  var title = ""

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition, SQLQueryExpression(PrimaryKeyedTableDefinition {
                    public typealias QueryValue = Reminder
                    public typealias PrimaryKey = Int?
                    public let id = SQLQueryExpression(_TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
                    public let primaryKey = SQLQueryExpression(_TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
                    public let title = SQLQueryExpression(_TableColumn<QueryValue, Swift.String>.for("title", keyPath: \QueryValue.title, default: "")
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                      allColumns.append(contentsOf: QueryValue.columns.title._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                      writableColumns.append(contentsOf: QueryValue.columns.title._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.id), \(self.title)"
                    }
                  }

                  public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = Reminder
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public init(
                      id: some SQLQueryExpression(QueryExpression<Int?> = Int?(queryOutput: nil),
                      title: some SQLQueryExpression(QueryExpression<Swift.String> = Swift.String(queryOutput: "")
                    ) {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: id._allColumns)
                      allColumns.append(contentsOf: title._allColumns)
                      self.allColumns = allColumns
                    }
                  }

                  public struct Draft: SQLQueryExpression(TableDraft {
                    public typealias PrimaryTable = Reminder
                    let id: Int?  // TODO: Migrate to UUID
                    var title = ""
                    public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                      public typealias QueryValue = Draft
                      public let id = SQLQueryExpression(_TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
                      public let title = SQLQueryExpression(_TableColumn<QueryValue, Swift.String>.for("title", keyPath: \QueryValue.title, default: "")
                      public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                        var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                        allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                        allColumns.append(contentsOf: QueryValue.columns.title._allColumns)
                        return allColumns
                      }
                      public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                        var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                        writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                        writableColumns.append(contentsOf: QueryValue.columns.title._writableColumns)
                        return writableColumns
                      }
                      public var queryFragment: QueryFragment {
                        "\(self.id), \(self.title)"
                      }
                    }
                    public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                      public typealias QueryValue = Draft
                      public let allColumns: [any SQLQueryExpression(QueryExpression]
                      public init(
                        id: some SQLQueryExpression(QueryExpression<Int?> = Int?(queryOutput: nil),
                        title: some SQLQueryExpression(QueryExpression<Swift.String> = Swift.String(queryOutput: "")
                      ) {
                        var allColumns: [any SQLQueryExpression(QueryExpression] = []
                        allColumns.append(contentsOf: id._allColumns)
                        allColumns.append(contentsOf: title._allColumns)
                        self.allColumns = allColumns
                      }
                    }
                    public typealias QueryValue = Self

                    public typealias From = Swift.Never

                    public nonisolated static var columns: TableColumns {
                      TableColumns()
                    }

                    public nonisolated static var _columnWidth: Int {
                      var columnWidth = 0
                      columnWidth += Int?._columnWidth
                      columnWidth += Swift.String._columnWidth
                      return columnWidth
                    }

                    public nonisolated static var tableName: String {
                      Reminder.tableName
                    }

                    public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                      self.id = try decoder.decode(Int.self) ?? nil
                      self.title = try decoder.decode(Swift.String.self) ?? ""
                    }

                    public nonisolated init(_ other: Reminder) {
                      self.id = other.id
                      self.title = other.title
                    }
                    public init(
                      id: Int? = nil,
                      title: Swift.String = ""
                    ) {
                      self.id = id
                      self.title = title
                    }
                  }
                }

                nonisolated extension Reminder: SQLQueryExpression(Table, SQLQueryExpression(PrimaryKeyedTable, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    var columnWidth = 0
                    columnWidth += Int?._columnWidth
                    columnWidth += Swift.String._columnWidth
                    return columnWidth
                  }
                  public nonisolated static var tableName: String {
                    "reminders"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    self.id = try decoder.decode(Int.self) ?? nil
                    self.title = try decoder.decode(Swift.String.self) ?? ""
                  }
                }
                """#
            }
        }

        @Test func nested() {
            assertMacro {
                """
                @Table
                private struct Row {
                  let id: UUID
                  @Columns
                  var timestamps: Timestamps
                }
                """
            } expansion: {
                #"""
                private struct Row {
                  let id: UUID
                  var timestamps: Timestamps

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition, SQLQueryExpression(PrimaryKeyedTableDefinition {
                    public typealias QueryValue = Row
                    public typealias PrimaryKey = UUID
                    public let id = SQLQueryExpression(_TableColumn<QueryValue, UUID>.for("id", keyPath: \QueryValue.id)
                    public let primaryKey = SQLQueryExpression(_TableColumn<QueryValue, UUID>.for("id", keyPath: \QueryValue.id)
                    public let timestamps = SQLQueryExpression(ColumnGroup<QueryValue, Timestamps>(keyPath: \QueryValue.timestamps)
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                      allColumns.append(contentsOf: QueryValue.columns.timestamps._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                      writableColumns.append(contentsOf: QueryValue.columns.timestamps._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.id), \(self.timestamps)"
                    }
                  }

                  public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = Row
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public init(
                      id: some SQLQueryExpression(QueryExpression<UUID>,
                      timestamps: some SQLQueryExpression(QueryExpression<Timestamps>
                    ) {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: id._allColumns)
                      allColumns.append(contentsOf: timestamps._allColumns)
                      self.allColumns = allColumns
                    }
                  }

                  public struct Draft: SQLQueryExpression(TableDraft {
                    public typealias PrimaryTable = Row
                    let id: UUID?
                    var timestamps: Timestamps
                    public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                      public typealias QueryValue = Draft
                      public let id = SQLQueryExpression(_TableColumn<QueryValue, UUID?>.for("id", keyPath: \QueryValue.id, default: nil)
                      public let timestamps = SQLQueryExpression(ColumnGroup<QueryValue, Timestamps>(keyPath: \QueryValue.timestamps)
                      public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                        var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                        allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                        allColumns.append(contentsOf: QueryValue.columns.timestamps._allColumns)
                        return allColumns
                      }
                      public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                        var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                        writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                        writableColumns.append(contentsOf: QueryValue.columns.timestamps._writableColumns)
                        return writableColumns
                      }
                      public var queryFragment: QueryFragment {
                        "\(self.id), \(self.timestamps)"
                      }
                    }
                    public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                      public typealias QueryValue = Draft
                      public let allColumns: [any SQLQueryExpression(QueryExpression]
                      public init(
                        id: some SQLQueryExpression(QueryExpression<UUID?> = UUID?(queryOutput: nil),
                        timestamps: some SQLQueryExpression(QueryExpression<Timestamps>
                      ) {
                        var allColumns: [any SQLQueryExpression(QueryExpression] = []
                        allColumns.append(contentsOf: id._allColumns)
                        allColumns.append(contentsOf: timestamps._allColumns)
                        self.allColumns = allColumns
                      }
                    }
                    public typealias QueryValue = Self

                    public typealias From = Swift.Never

                    public nonisolated static var columns: TableColumns {
                      TableColumns()
                    }

                    public nonisolated static var _columnWidth: Int {
                      var columnWidth = 0
                      columnWidth += UUID?._columnWidth
                      columnWidth += Timestamps._columnWidth
                      return columnWidth
                    }

                    public nonisolated static var tableName: String {
                      Row.tableName
                    }

                    public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                      self.id = try decoder.decode(UUID.self) ?? nil
                      let timestamps = try decoder.decode(Timestamps.self)
                      guard let timestamps else {
                        throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                      }
                      self.timestamps = timestamps
                    }

                    public nonisolated init(_ other: Row) {
                      self.id = other.id
                      self.timestamps = other.timestamps
                    }
                    public init(
                      id: UUID? = nil,
                      timestamps: Timestamps
                    ) {
                      self.id = id
                      self.timestamps = timestamps
                    }
                  }
                }

                nonisolated extension Row: SQLQueryExpression(Table, SQLQueryExpression(PrimaryKeyedTable, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    var columnWidth = 0
                    columnWidth += UUID._columnWidth
                    columnWidth += Timestamps._columnWidth
                    return columnWidth
                  }
                  public nonisolated static var tableName: String {
                    "rows"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    let id = try decoder.decode(UUID.self)
                    let timestamps = try decoder.decode(Timestamps.self)
                    guard let id else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    guard let timestamps else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    self.id = id
                    self.timestamps = timestamps
                  }
                }
                """#
            }
        }

        @Test func nestedLet() {
            assertMacro {
                """
                @Table("remindersTags")
                struct ReminderTag: Identifiable {
                  @Columns
                  let id: ReminderTagID
                }
                """
            } expansion: {
                #"""
                struct ReminderTag: Identifiable {
                  let id: ReminderTagID

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition, SQLQueryExpression(PrimaryKeyedTableDefinition {
                    public typealias QueryValue = ReminderTag
                    public typealias PrimaryKey = ReminderTagID
                    public let id = SQLQueryExpression(ColumnGroup<QueryValue, ReminderTagID>(keyPath: \QueryValue.id)
                    public let primaryKey = SQLQueryExpression(ColumnGroup<QueryValue, ReminderTagID>(keyPath: \QueryValue.id)
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.id)"
                    }
                  }

                  public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = ReminderTag
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public init(
                      id: some SQLQueryExpression(QueryExpression<ReminderTagID>
                    ) {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: id._allColumns)
                      self.allColumns = allColumns
                    }
                  }

                  public struct Draft: SQLQueryExpression(TableDraft {
                    public typealias PrimaryTable = ReminderTag
                    let id: ReminderTagID?
                    public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                      public typealias QueryValue = Draft
                      public let id = SQLQueryExpression(ColumnGroup<QueryValue, ReminderTagID?>(keyPath: \QueryValue.id)
                      public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                        var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                        allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                        return allColumns
                      }
                      public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                        var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                        writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                        return writableColumns
                      }
                      public var queryFragment: QueryFragment {
                        "\(self.id)"
                      }
                    }
                    public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                      public typealias QueryValue = Draft
                      public let allColumns: [any SQLQueryExpression(QueryExpression]
                      public init(
                        id: some SQLQueryExpression(QueryExpression<ReminderTagID?> = ReminderTagID?(queryOutput: nil)
                      ) {
                        var allColumns: [any SQLQueryExpression(QueryExpression] = []
                        allColumns.append(contentsOf: id._allColumns)
                        self.allColumns = allColumns
                      }
                    }
                    public typealias QueryValue = Self

                    public typealias From = Swift.Never

                    public nonisolated static var columns: TableColumns {
                      TableColumns()
                    }

                    public nonisolated static var _columnWidth: Int {
                      var columnWidth = 0
                      columnWidth += ReminderTagID?._columnWidth
                      return columnWidth
                    }

                    public nonisolated static var tableName: String {
                      ReminderTag.tableName
                    }

                    public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                      self.id = try decoder.decode(ReminderTagID.self) ?? nil
                    }

                    public nonisolated init(_ other: ReminderTag) {
                      self.id = other.id
                    }
                    public init(
                      id: ReminderTagID? = nil
                    ) {
                      self.id = id
                    }
                  }
                }

                nonisolated extension ReminderTag: SQLQueryExpression(Table, SQLQueryExpression(PrimaryKeyedTable, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    var columnWidth = 0
                    columnWidth += ReminderTagID._columnWidth
                    return columnWidth
                  }
                  public nonisolated static var tableName: String {
                    "remindersTags"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    let id = try decoder.decode(ReminderTagID.self)
                    guard let id else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    self.id = id
                  }
                }
                """#
            }
        }

        @Test func customPrimaryKey() {
            assertMacro {
                """
                @Table
                private struct ReminderWithList {
                  @Column(primaryKey: true)
                  let reminderID: Reminder.ID
                  let reminderTitle: String
                  let remindersListTitle: String
                }
                """
            } expansion: {
                #"""
                private struct ReminderWithList {
                  let reminderID: Reminder.ID
                  let reminderTitle: String
                  let remindersListTitle: String

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition, SQLQueryExpression(PrimaryKeyedTableDefinition {
                    public typealias QueryValue = ReminderWithList
                    public typealias PrimaryKey = Reminder.ID
                    public let reminderID = SQLQueryExpression(TableColumn<QueryValue, Reminder.ID>("reminderID", keyPath: \QueryValue.reminderID)
                    public let primaryKey = SQLQueryExpression(TableColumn<QueryValue, Reminder.ID>("reminderID", keyPath: \QueryValue.reminderID)
                    public let reminderTitle = SQLQueryExpression(_TableColumn<QueryValue, String>.for("reminderTitle", keyPath: \QueryValue.reminderTitle)
                    public let remindersListTitle = SQLQueryExpression(_TableColumn<QueryValue, String>.for("remindersListTitle", keyPath: \QueryValue.remindersListTitle)
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.reminderID._allColumns)
                      allColumns.append(contentsOf: QueryValue.columns.reminderTitle._allColumns)
                      allColumns.append(contentsOf: QueryValue.columns.remindersListTitle._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.reminderID._writableColumns)
                      writableColumns.append(contentsOf: QueryValue.columns.reminderTitle._writableColumns)
                      writableColumns.append(contentsOf: QueryValue.columns.remindersListTitle._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.reminderID), \(self.reminderTitle), \(self.remindersListTitle)"
                    }
                  }

                  public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = ReminderWithList
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public init(
                      reminderID: some SQLQueryExpression(QueryExpression<Reminder.ID>,
                      reminderTitle: some SQLQueryExpression(QueryExpression<String>,
                      remindersListTitle: some SQLQueryExpression(QueryExpression<String>
                    ) {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: reminderID._allColumns)
                      allColumns.append(contentsOf: reminderTitle._allColumns)
                      allColumns.append(contentsOf: remindersListTitle._allColumns)
                      self.allColumns = allColumns
                    }
                  }

                  public struct Draft: SQLQueryExpression(TableDraft {
                    public typealias PrimaryTable = ReminderWithList
                    let reminderID: Reminder.ID?
                    let reminderTitle: String
                    let remindersListTitle: String
                    public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                      public typealias QueryValue = Draft
                      public let reminderID = SQLQueryExpression(TableColumn<QueryValue, Reminder.ID?>("reminderID", keyPath: \QueryValue.reminderID, default: nil)
                      public let reminderTitle = SQLQueryExpression(_TableColumn<QueryValue, String>.for("reminderTitle", keyPath: \QueryValue.reminderTitle)
                      public let remindersListTitle = SQLQueryExpression(_TableColumn<QueryValue, String>.for("remindersListTitle", keyPath: \QueryValue.remindersListTitle)
                      public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                        var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                        allColumns.append(contentsOf: QueryValue.columns.reminderID._allColumns)
                        allColumns.append(contentsOf: QueryValue.columns.reminderTitle._allColumns)
                        allColumns.append(contentsOf: QueryValue.columns.remindersListTitle._allColumns)
                        return allColumns
                      }
                      public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                        var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                        writableColumns.append(contentsOf: QueryValue.columns.reminderID._writableColumns)
                        writableColumns.append(contentsOf: QueryValue.columns.reminderTitle._writableColumns)
                        writableColumns.append(contentsOf: QueryValue.columns.remindersListTitle._writableColumns)
                        return writableColumns
                      }
                      public var queryFragment: QueryFragment {
                        "\(self.reminderID), \(self.reminderTitle), \(self.remindersListTitle)"
                      }
                    }
                    public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                      public typealias QueryValue = Draft
                      public let allColumns: [any SQLQueryExpression(QueryExpression]
                      public init(
                        reminderID: some SQLQueryExpression(QueryExpression<Reminder.ID?> = Reminder.ID?(queryOutput: nil),
                        reminderTitle: some SQLQueryExpression(QueryExpression<String>,
                        remindersListTitle: some SQLQueryExpression(QueryExpression<String>
                      ) {
                        var allColumns: [any SQLQueryExpression(QueryExpression] = []
                        allColumns.append(contentsOf: reminderID._allColumns)
                        allColumns.append(contentsOf: reminderTitle._allColumns)
                        allColumns.append(contentsOf: remindersListTitle._allColumns)
                        self.allColumns = allColumns
                      }
                    }
                    public typealias QueryValue = Self

                    public typealias From = Swift.Never

                    public nonisolated static var columns: TableColumns {
                      TableColumns()
                    }

                    public nonisolated static var _columnWidth: Int {
                      var columnWidth = 0
                      columnWidth += Reminder.ID?._columnWidth
                      columnWidth += String._columnWidth
                      columnWidth += String._columnWidth
                      return columnWidth
                    }

                    public nonisolated static var tableName: String {
                      ReminderWithList.tableName
                    }

                    public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                      self.reminderID = try decoder.decode(Reminder.ID.self) ?? nil
                      let reminderTitle = try decoder.decode(String.self)
                      let remindersListTitle = try decoder.decode(String.self)
                      guard let reminderTitle else {
                        throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                      }
                      guard let remindersListTitle else {
                        throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                      }
                      self.reminderTitle = reminderTitle
                      self.remindersListTitle = remindersListTitle
                    }

                    public nonisolated init(_ other: ReminderWithList) {
                      self.reminderID = other.reminderID
                      self.reminderTitle = other.reminderTitle
                      self.remindersListTitle = other.remindersListTitle
                    }
                    public init(
                      reminderID: Reminder.ID? = nil,
                      reminderTitle: String,
                      remindersListTitle: String
                    ) {
                      self.reminderID = reminderID
                      self.reminderTitle = reminderTitle
                      self.remindersListTitle = remindersListTitle
                    }
                  }
                }

                nonisolated extension ReminderWithList: SQLQueryExpression(Table, SQLQueryExpression(PrimaryKeyedTable, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    var columnWidth = 0
                    columnWidth += Reminder.ID._columnWidth
                    columnWidth += String._columnWidth
                    columnWidth += String._columnWidth
                    return columnWidth
                  }
                  public nonisolated static var tableName: String {
                    "reminderWithLists"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    let reminderID = try decoder.decode(Reminder.ID.self)
                    let reminderTitle = try decoder.decode(String.self)
                    let remindersListTitle = try decoder.decode(String.self)
                    guard let reminderID else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    guard let reminderTitle else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    guard let remindersListTitle else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    self.reminderID = reminderID
                    self.reminderTitle = reminderTitle
                    self.remindersListTitle = remindersListTitle
                  }
                }
                """#
            }
        }

        @Test func composite() {
            assertMacro {
                """
                @Table
                private struct Metadata: Identifiable {
                  let id: MetadataID
                  var userModificationDate: Date
                }
                """
            } expansion: {
                #"""
                private struct Metadata: Identifiable {
                  let id: MetadataID
                  var userModificationDate: Date

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition, SQLQueryExpression(PrimaryKeyedTableDefinition {
                    public typealias QueryValue = Metadata
                    public typealias PrimaryKey = MetadataID
                    public let id = SQLQueryExpression(_TableColumn<QueryValue, MetadataID>.for("id", keyPath: \QueryValue.id)
                    public let primaryKey = SQLQueryExpression(_TableColumn<QueryValue, MetadataID>.for("id", keyPath: \QueryValue.id)
                    public let userModificationDate = SQLQueryExpression(_TableColumn<QueryValue, Date>.for("userModificationDate", keyPath: \QueryValue.userModificationDate)
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                      allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                      allColumns.append(contentsOf: QueryValue.columns.userModificationDate._allColumns)
                      return allColumns
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                      writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                      writableColumns.append(contentsOf: QueryValue.columns.userModificationDate._writableColumns)
                      return writableColumns
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.id), \(self.userModificationDate)"
                    }
                  }

                  public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                    public typealias QueryValue = Metadata
                    public let allColumns: [any SQLQueryExpression(QueryExpression]
                    public init(
                      id: some SQLQueryExpression(QueryExpression<MetadataID>,
                      userModificationDate: some SQLQueryExpression(QueryExpression<Date>
                    ) {
                      var allColumns: [any SQLQueryExpression(QueryExpression] = []
                      allColumns.append(contentsOf: id._allColumns)
                      allColumns.append(contentsOf: userModificationDate._allColumns)
                      self.allColumns = allColumns
                    }
                  }

                  public struct Draft: SQLQueryExpression(TableDraft {
                    public typealias PrimaryTable = Metadata
                    let id: MetadataID?
                    var userModificationDate: Date
                    public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                      public typealias QueryValue = Draft
                      public let id = SQLQueryExpression(_TableColumn<QueryValue, MetadataID?>.for("id", keyPath: \QueryValue.id, default: nil)
                      public let userModificationDate = SQLQueryExpression(_TableColumn<QueryValue, Date>.for("userModificationDate", keyPath: \QueryValue.userModificationDate)
                      public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                        var allColumns: [any SQLQueryExpression(TableColumnExpression] = []
                        allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                        allColumns.append(contentsOf: QueryValue.columns.userModificationDate._allColumns)
                        return allColumns
                      }
                      public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                        var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] = []
                        writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                        writableColumns.append(contentsOf: QueryValue.columns.userModificationDate._writableColumns)
                        return writableColumns
                      }
                      public var queryFragment: QueryFragment {
                        "\(self.id), \(self.userModificationDate)"
                      }
                    }
                    public nonisolated struct Selection: SQLQueryExpression(TableExpression {
                      public typealias QueryValue = Draft
                      public let allColumns: [any SQLQueryExpression(QueryExpression]
                      public init(
                        id: some SQLQueryExpression(QueryExpression<MetadataID?> = MetadataID?(queryOutput: nil),
                        userModificationDate: some SQLQueryExpression(QueryExpression<Date>
                      ) {
                        var allColumns: [any SQLQueryExpression(QueryExpression] = []
                        allColumns.append(contentsOf: id._allColumns)
                        allColumns.append(contentsOf: userModificationDate._allColumns)
                        self.allColumns = allColumns
                      }
                    }
                    public typealias QueryValue = Self

                    public typealias From = Swift.Never

                    public nonisolated static var columns: TableColumns {
                      TableColumns()
                    }

                    public nonisolated static var _columnWidth: Int {
                      var columnWidth = 0
                      columnWidth += MetadataID?._columnWidth
                      columnWidth += Date._columnWidth
                      return columnWidth
                    }

                    public nonisolated static var tableName: String {
                      Metadata.tableName
                    }

                    public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                      self.id = try decoder.decode(MetadataID.self) ?? nil
                      let userModificationDate = try decoder.decode(Date.self)
                      guard let userModificationDate else {
                        throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                      }
                      self.userModificationDate = userModificationDate
                    }

                    public nonisolated init(_ other: Metadata) {
                      self.id = other.id
                      self.userModificationDate = other.userModificationDate
                    }
                    public init(
                      id: MetadataID? = nil,
                      userModificationDate: Date
                    ) {
                      self.id = id
                      self.userModificationDate = userModificationDate
                    }
                  }
                }

                nonisolated extension Metadata: SQLQueryExpression(Table, SQLQueryExpression(PrimaryKeyedTable, SQLQueryExpression(PartialSelectStatement {
                  public typealias QueryValue = Self
                  public typealias From = Swift.Never
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var _columnWidth: Int {
                    var columnWidth = 0
                    columnWidth += MetadataID._columnWidth
                    columnWidth += Date._columnWidth
                    return columnWidth
                  }
                  public nonisolated static var tableName: String {
                    "metadatas"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    let id = try decoder.decode(MetadataID.self)
                    let userModificationDate = try decoder.decode(Date.self)
                    guard let id else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    guard let userModificationDate else {
                      throw SQLQueryExpression(QueryDecodingError.missingRequiredColumn
                    }
                    self.id = id
                    self.userModificationDate = userModificationDate
                  }
                }
                """#
            }
        }
    }
}
