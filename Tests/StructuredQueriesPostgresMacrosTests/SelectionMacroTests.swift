import MacroTesting
import StructuredQueriesPostgresMacros
import Testing

extension SnapshotTests {
  @Suite struct SelectionMacroTests {
    @Test func basics() {
      assertMacro {
        """
        @Selection
        struct PlayerAndTeam {
          let player: Player
          let team: Team
        }
        """
      } expansion: {
        """
        struct PlayerAndTeam {
          let player: Player
          let team: Team

          public struct Columns: StructuredQueriesPostgresCore._SelectedColumns {
            public typealias QueryValue = PlayerAndTeam
            public let selection: [(aliasName: String, expression: StructuredQueriesPostgresCore.QueryFragment)]
            public init(
              player: some StructuredQueriesPostgresCore.QueryExpression<Player>,
              team: some StructuredQueriesPostgresCore.QueryExpression<Team>
            ) {
              self.selection = [("player", player.queryFragment), ("team", team.queryFragment)]
            }
          }
        }

        extension PlayerAndTeam: StructuredQueriesPostgresCore._Selection {
          public init(decoder: inout some StructuredQueriesPostgresCore.QueryDecoder) throws {
            let player = try decoder.decode(Player.self)
            let team = try decoder.decode(Team.self)
            guard let player else {
              throw QueryDecodingError.missingRequiredColumn
            }
            guard let team else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.player = player
            self.team = team
          }
        }
        """
      }
    }

    @Test func `enum`() {
      assertMacro {
        """
        @Selection
        public enum S {}
        """
      } diagnostics: {
        """
        @Selection
        public enum S {}
               ┬───
               ╰─ 🛑 '@Selection' can only be applied to struct types
        """
      }
    }

    @Test func optionalField() {
      assertMacro {
        """
        @Selection
        struct ReminderTitleAndListTitle {
          var reminderTitle: String
          var listTitle: String?
        }
        """
      } expansion: {
        """
        struct ReminderTitleAndListTitle {
          var reminderTitle: String
          var listTitle: String?

          public struct Columns: StructuredQueriesPostgresCore._SelectedColumns {
            public typealias QueryValue = ReminderTitleAndListTitle
            public let selection: [(aliasName: String, expression: StructuredQueriesPostgresCore.QueryFragment)]
            public init(
              reminderTitle: some StructuredQueriesPostgresCore.QueryExpression<String>,
              listTitle: some StructuredQueriesPostgresCore.QueryExpression<String?>
            ) {
              self.selection = [("reminderTitle", reminderTitle.queryFragment), ("listTitle", listTitle.queryFragment)]
            }
          }
        }

        extension ReminderTitleAndListTitle: StructuredQueriesPostgresCore._Selection {
          public init(decoder: inout some StructuredQueriesPostgresCore.QueryDecoder) throws {
            let reminderTitle = try decoder.decode(String.self)
            let listTitle = try decoder.decode(String.self)
            guard let reminderTitle else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.reminderTitle = reminderTitle
            self.listTitle = listTitle
          }
        }
        """
      }
    }

    @Test func date() {
      assertMacro {
        """
        @Selection struct ReminderDate {
          @Column(as: Date.UnixTimeRepresentation.self)
          var date: Date
        }
        """
      } expansion: {
        """
        struct ReminderDate {
          var date: Date

          public struct Columns: StructuredQueriesPostgresCore._SelectedColumns {
            public typealias QueryValue = ReminderDate
            public let selection: [(aliasName: String, expression: StructuredQueriesPostgresCore.QueryFragment)]
            public init(
              date: some StructuredQueriesPostgresCore.QueryExpression<Date.UnixTimeRepresentation>
            ) {
              self.selection = [("date", date.queryFragment)]
            }
          }
        }

        extension ReminderDate: StructuredQueriesPostgresCore._Selection {
          public init(decoder: inout some StructuredQueriesPostgresCore.QueryDecoder) throws {
            let date = try decoder.decode(Date.UnixTimeRepresentation.self)
            guard let date else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.date = date
          }
        }
        """
      }
    }
  }
}
