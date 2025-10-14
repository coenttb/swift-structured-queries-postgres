import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests.Commands.Select {
    @Suite struct UnionTests {
        @Test func basics() async {
            await assertSQL(
                of: Reminder.select { ("reminder", $0.title) }
                    .union(RemindersList.select { ("list", $0.title) })
                    .union(Tag.select { ("tag", $0.title) })
            ) {
                """
                SELECT 'reminder', "reminders"."title"
                FROM "reminders"
                  UNION
                SELECT 'list', "remindersLists"."title"
                FROM "remindersLists"
                  UNION
                SELECT 'tag', "tags"."title"
                FROM "tags"
                """
            }
        }

        @Test func empty() async {
            await assertSQL(
                of: Reminder.none.select { ("reminder", $0.title) }
                    .union(RemindersList.select { ("list", $0.title) })
                    .union(Tag.none.select { ("tag", $0.title) })
            ) {
                """
                SELECT 'list', "remindersLists"."title"
                FROM "remindersLists"
                """
            }
        }
        @Test func commonTableExpression() async {
            await assertSQL(
                of: With {
                    Reminder.select { Name.Columns(type: "reminder", value: $0.title) }
                        .union(RemindersList.select { Name.Columns(type: "list", value: $0.title) })
                        .union(Tag.select { Name.Columns(type: "tag", value: $0.title) })
                } query: {
                    Name.order { ($0.type.desc(), $0.value.asc()) }
                }
            ) {
                """
                WITH "names" AS (
                  SELECT 'reminder' AS "type", "reminders"."title" AS "value"
                  FROM "reminders"
                    UNION
                  SELECT 'list' AS "type", "remindersLists"."title" AS "value"
                  FROM "remindersLists"
                    UNION
                  SELECT 'tag' AS "type", "tags"."title" AS "value"
                  FROM "tags"
                )
                SELECT "names"."type", "names"."value"
                FROM "names"
                ORDER BY "names"."type" DESC, "names"."value" ASC
                """
            }
        }
    }
}
@Selection
private struct Name {
    let type: String
    let value: String
}
