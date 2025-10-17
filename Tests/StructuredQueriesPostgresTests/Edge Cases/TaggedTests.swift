import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Tagged
import Testing

extension SnapshotTests {
    @Suite struct TaggedTests {
        @Test func basicTaggedInt() async {
            await assertSQL(
                of: Reminder.insert {
                    Reminder(
                        id: 11 as Reminder.ID,
                        remindersListID: 1
                    )
                }
            ) {
                """
                INSERT INTO "reminders"
                ("id", "remindersListID")
                VALUES
                (11, 1)
                """
            }
        }

        @Test func taggedUUID() async {
            let userId = User.ID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!
            await assertSQL(
                of: User.insert {
                    User(id: userId, name: "Alice")
                }
            ) {
                """
                INSERT INTO "users"
                ("id", "name")
                VALUES
                ('550e8400-e29b-41d4-a716-446655440000', 'Alice')
                """
            }
        }

        @Test func taggedUUIDWhereClause() async {
            let userId = User.ID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!
            await assertSQL(of: User.where { $0.id == userId }) {
                """
                SELECT "users"."id", "users"."name"
                FROM "users"
                WHERE ("users"."id") = ('550e8400-e29b-41d4-a716-446655440000')
                """
            }
        }

        @Test func taggedInClause() async {
            let reminderIds: [Reminder.ID] = [
                Reminder.ID(rawValue: 1),
                Reminder.ID(rawValue: 2),
                Reminder.ID(rawValue: 3)
            ]

            await assertSQL(of: Reminder.where { reminderIds.contains($0.id) }) {
                """
                SELECT "reminders"."id", "reminders"."remindersListID"
                FROM "reminders"
                WHERE ("reminders"."id") IN (1, 2, 3)
                """
            }
        }

        @Test func taggedUpdate() async {
            let userId = User.ID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!
            await assertSQL(
                of: User.where { $0.id == userId }.update { $0.name = "Bob" }
            ) {
                """
                UPDATE "users"
                SET "name" = 'Bob'
                WHERE ("users"."id") = ('550e8400-e29b-41d4-a716-446655440000')
                """
            }
        }

        @Test func taggedDelete() async {
            let reminderIds: [Reminder.ID] = [
                Reminder.ID(rawValue: 1),
                Reminder.ID(rawValue: 2)
            ]
            await assertSQL(of: Reminder.where { reminderIds.contains($0.id) }.delete()) {
                """
                DELETE FROM "reminders"
                WHERE ("reminders"."id") IN (1, 2)
                """
            }
        }

        @Test func taggedJoin() async {
            await assertSQL(
                of: Reminder.join(RemindersList.all) { $0.remindersListID == $1.id }
                    .select { ($0.id, $1.name) }
            ) {
                """
                SELECT "reminders"."id", "remindersLists"."name"
                FROM "reminders"
                JOIN "remindersLists" ON ("reminders"."remindersListID") = ("remindersLists"."id")
                """
            }
        }

        @Test func taggedSelectPreservesType() {
            // Compile-time test: verify that selecting Tagged columns preserves the Tagged wrapper
            let _: Select<Reminder.ID, Reminder, ()> = Reminder.select { $0.id }
            let _: Select<User.ID, User, ()> = User.select { $0.id }

            // Verify tuple selections preserve Tagged types
            let _: Select<(Reminder.ID, Int), Reminder, ()> = Reminder.select { ($0.id, $0.remindersListID) }
            let _: Select<(User.ID, String), User, ()> = User.select { ($0.id, $0.name) }
        }

        @Table
        fileprivate struct Reminder {
            typealias ID = Tagged<Self, Int>

            let id: ID
            let remindersListID: Int
        }

        @Table
        fileprivate struct User {
            typealias ID = Tagged<Self, UUID>

            let id: ID
            let name: String
        }

        @Table
        fileprivate struct RemindersList {
            typealias ID = Int

            let id: ID
            let name: String
        }
    }
}
