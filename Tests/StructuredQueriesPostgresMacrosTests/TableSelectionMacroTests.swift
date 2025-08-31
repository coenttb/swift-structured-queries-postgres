import MacroTesting
import StructuredQueriesPostgresMacros
import Testing

extension SnapshotTests {
  @Suite
  struct TableSelectionMacroTests {
    @Test func basics() {
      assertMacro {
        """
        @Table @Selection
        struct ReminderListWithCount {
          let reminderList: ReminderList 
          let remindersCount: Int
        }
        """
      } expansion: {
        #"""
        struct ReminderListWithCount {
          let reminderList: ReminderList 
          let remindersCount: Int

          public nonisolated struct TableColumns: StructuredQueriesPostgresCore.TableDefinition {
            public typealias QueryValue = ReminderListWithCount
            public let reminderList = StructuredQueriesPostgresCore.TableColumn<QueryValue, ReminderList>("reminderList", keyPath: \QueryValue.reminderList)
            public let remindersCount = StructuredQueriesPostgresCore.TableColumn<QueryValue, Int>("remindersCount", keyPath: \QueryValue.remindersCount)
            public static var allColumns: [any StructuredQueriesPostgresCore.TableColumnExpression] {
              [QueryValue.columns.reminderList, QueryValue.columns.remindersCount]
            }
            public static var writableColumns: [any StructuredQueriesPostgresCore.WritableTableColumnExpression] {
              [QueryValue.columns.reminderList, QueryValue.columns.remindersCount]
            }
            public var queryFragment: QueryFragment {
              "\(self.reminderList), \(self.remindersCount)"
            }
          }

          public struct Columns: StructuredQueriesPostgresCore._SelectedColumns {
            public typealias QueryValue = ReminderListWithCount
            public let selection: [(aliasName: String, expression: StructuredQueriesPostgresCore.QueryFragment)]
            public init(
              reminderList: some StructuredQueriesPostgresCore.QueryExpression<ReminderList>,
              remindersCount: some StructuredQueriesPostgresCore.QueryExpression<Int>
            ) {
              self.selection = [("reminderList", reminderList.queryFragment), ("remindersCount", remindersCount.queryFragment)]
            }
          }
        }

        nonisolated extension ReminderListWithCount: StructuredQueriesPostgresCore.Table, StructuredQueriesPostgresCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var tableName: String {
            "reminderListWithCounts"
          }
        }

        extension ReminderListWithCount: StructuredQueriesPostgresCore._Selection {
          public init(decoder: inout some StructuredQueriesPostgresCore.QueryDecoder) throws {
            let reminderList = try decoder.decode(ReminderList.self)
            let remindersCount = try decoder.decode(Int.self)
            guard let reminderList else {
              throw QueryDecodingError.missingRequiredColumn
            }
            guard let remindersCount else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.reminderList = reminderList
            self.remindersCount = remindersCount
          }
        }
        """#
      }
    }
  }
}
