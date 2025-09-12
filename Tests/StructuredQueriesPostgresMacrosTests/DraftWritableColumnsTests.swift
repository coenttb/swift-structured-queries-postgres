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

          public nonisolated struct TableColumns: StructuredQueriesPostgresCore.TableDefinition, StructuredQueriesPostgresCore.PrimaryKeyedTableDefinition {
            public typealias QueryValue = User
            public let id = StructuredQueriesPostgresCore.TableColumn<QueryValue, Int>("id", keyPath: \QueryValue.id)
            public let name = StructuredQueriesPostgresCore.TableColumn<QueryValue, String>("name", keyPath: \QueryValue.name)
            public let email = StructuredQueriesPostgresCore.TableColumn<QueryValue, String>("email", keyPath: \QueryValue.email)
            public var primaryKey: StructuredQueriesPostgresCore.TableColumn<QueryValue, Int> {
              self.id
            }
            public static var allColumns: [any StructuredQueriesPostgresCore.TableColumnExpression] {
              [QueryValue.columns.id, QueryValue.columns.name, QueryValue.columns.email]
            }
            public static var writableColumns: [any StructuredQueriesPostgresCore.WritableTableColumnExpression] {
              [QueryValue.columns.id, QueryValue.columns.name, QueryValue.columns.email]
            }
            public var queryFragment: QueryFragment {
              "\(self.id), \(self.name), \(self.email)"
            }
          }

          public struct Draft: StructuredQueriesPostgresCore.TableDraft {
            public typealias PrimaryTable = User
            let id: Int?
            var name: String
            var email: String
            public nonisolated struct TableColumns: StructuredQueriesPostgresCore.TableDefinition {
              public typealias QueryValue = Draft
              public let id = StructuredQueriesPostgresCore.TableColumn<QueryValue, Int?>("id", keyPath: \QueryValue.id)
              public let name = StructuredQueriesPostgresCore.TableColumn<QueryValue, String>("name", keyPath: \QueryValue.name)
              public let email = StructuredQueriesPostgresCore.TableColumn<QueryValue, String>("email", keyPath: \QueryValue.email)
              public static var allColumns: [any StructuredQueriesPostgresCore.TableColumnExpression] {
                [QueryValue.columns.id, QueryValue.columns.name, QueryValue.columns.email]
              }
              public static var writableColumns: [any StructuredQueriesPostgresCore.WritableTableColumnExpression] {
                [QueryValue.columns.name, QueryValue.columns.email]
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.name), \(self.email)"
              }
            }
            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var tableName: String {
              User.tableName
            }

            public nonisolated init(decoder: inout some StructuredQueriesPostgresCore.QueryDecoder) throws {
              self.id = try decoder.decode(Int.self)
              let name = try decoder.decode(String.self)
              let email = try decoder.decode(String.self)
              guard let name else {
                throw QueryDecodingError.missingRequiredColumn
              }
              guard let email else {
                throw QueryDecodingError.missingRequiredColumn
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

        nonisolated extension User: StructuredQueriesPostgresCore.Table, StructuredQueriesPostgresCore.PrimaryKeyedTable {
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var tableName: String {
            "users"
          }
          public nonisolated init(decoder: inout some StructuredQueriesPostgresCore.QueryDecoder) throws {
            let id = try decoder.decode(Int.self)
            let name = try decoder.decode(String.self)
            let email = try decoder.decode(String.self)
            guard let id else {
              throw QueryDecodingError.missingRequiredColumn
            }
            guard let name else {
              throw QueryDecodingError.missingRequiredColumn
            }
            guard let email else {
              throw QueryDecodingError.missingRequiredColumn
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
