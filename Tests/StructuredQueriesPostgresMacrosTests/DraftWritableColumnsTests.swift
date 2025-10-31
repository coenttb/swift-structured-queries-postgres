import MacroTesting
import StructuredQueriesPostgresMacros
import Testing

extension SnapshotTests {
  @MainActor
  @Suite struct DraftWritableColumnsTests {
    @Test func draftExcludesPrimaryKeyFromWritableColumns() {
      assertMacro {
        """
        @Table
        struct User {
          let id: Int
          var name: String
          var email: String
        }
        """
      } expansion: {
        #"""
        struct User {
          let id: Int
          var name: String
          var email: String

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
            public typealias QueryValue = User
            public typealias PrimaryKey = Int
            public let id = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
            public let primaryKey = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
            public let name = StructuredQueriesCore._TableColumn<QueryValue, String>.for("name", keyPath: \QueryValue.name)
            public let email = StructuredQueriesCore._TableColumn<QueryValue, String>.for("email", keyPath: \QueryValue.email)
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.email._allColumns)
              return allColumns
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.email._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.id), \(self.name), \(self.email)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = User
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              id: some StructuredQueriesCore.QueryExpression<Int>,
              name: some StructuredQueriesCore.QueryExpression<String>,
              email: some StructuredQueriesCore.QueryExpression<String>
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: id._allColumns)
              allColumns.append(contentsOf: name._allColumns)
              allColumns.append(contentsOf: email._allColumns)
              self.allColumns = allColumns
            }
          }

          public struct Draft: StructuredQueriesCore.TableDraft {
            public typealias PrimaryTable = User
            let id: Int?
            var name: String
            var email: String
            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
              public typealias QueryValue = Draft
              public let id = StructuredQueriesCore._TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
              public let name = StructuredQueriesCore._TableColumn<QueryValue, String>.for("name", keyPath: \QueryValue.name)
              public let email = StructuredQueriesCore._TableColumn<QueryValue, String>.for("email", keyPath: \QueryValue.email)
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.email._allColumns)
                return allColumns
              }
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.email._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.name), \(self.email)"
              }
            }
            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Draft
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
                name: some StructuredQueriesCore.QueryExpression<String>,
                email: some StructuredQueriesCore.QueryExpression<String>
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: id._allColumns)
                allColumns.append(contentsOf: name._allColumns)
                allColumns.append(contentsOf: email._allColumns)
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
              columnWidth += String._columnWidth
              return columnWidth
            }

            public nonisolated static var tableName: String {
              User.tableName
            }

            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.id = try decoder.decode(Int.self) ?? nil
              let name = try decoder.decode(String.self)
              let email = try decoder.decode(String.self)
              guard let name else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              guard let email else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              self.name = name
              self.email = email
            }

            public nonisolated init(_ other: User) {
              self.id = other.id
              self.name = other.name
              self.email = other.email
            }
            public init(
              id: Int? = nil,
              name: String,
              email: String
            ) {
              self.id = id
              self.name = name
              self.email = email
            }
          }
        }

        nonisolated extension User: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var _columnWidth: Int {
            var columnWidth = 0
            columnWidth += Int._columnWidth
            columnWidth += String._columnWidth
            columnWidth += String._columnWidth
            return columnWidth
          }
          public nonisolated static var tableName: String {
            "users"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let id = try decoder.decode(Int.self)
            let name = try decoder.decode(String.self)
            let email = try decoder.decode(String.self)
            guard let id else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            guard let name else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            guard let email else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            self.id = id
            self.name = name
            self.email = email
          }
        }
        """#
      }
    }
  }
}
