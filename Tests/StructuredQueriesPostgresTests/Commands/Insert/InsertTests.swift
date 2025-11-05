import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests {
    @Suite struct InsertTests {
        @Test func basics() async {
            await assertSQL(
                of: Reminder.insert {
                    ($0.remindersListID, $0.title, $0.isCompleted, $0.dueDate, $0.priority)
                } values: {
                    (1, "Groceries", true, Date(timeIntervalSinceReferenceDate: 0), .high)
                    (2, "Haircut", false, Date(timeIntervalSince1970: 0), .low)
                    (
                        #sql("3"), #sql("'Schedule doctor appointment'"), #sql("0"), #sql("NULL"),
                        #sql("2")
                    )
                } onConflictDoUpdate: {
                    $0.title += " Copy"
                }
                .returning(\.id)
            ) {
                """
                INSERT INTO "reminders"
                ("remindersListID", "title", "isCompleted", "dueDate", "priority")
                VALUES
                (1, 'Groceries', true, '2001-01-01 00:00:00.000', 3), (2, 'Haircut', false, '1970-01-01 00:00:00.000', 1), (3, 'Schedule doctor appointment', 0, NULL, 2)
                ON CONFLICT DO UPDATE SET "title" = ("reminders"."title") || (' Copy')
                RETURNING "reminders"."id"
                """
            }
        }
        @Test func singleColumn() async {
            await assertSQL(
                of:
                    Reminder
                    .insert(\.remindersListID) { 1 }
                    .returning(\.id)
            ) {
                """
                INSERT INTO "reminders"
                ("remindersListID")
                VALUES
                (1)
                RETURNING "reminders"."id"
                """
            }
        }
        @Test
        func emptyValues() {
            assertInlineSnapshot(
                of: Reminder.insert { [] },
                as: .sql
            ) {
                """

                """
            }
            assertInlineSnapshot(
                of: Reminder.insert(\.id) { return [] },
                as: .sql
            ) {
                """

                """
            }
        }
        @Test
        func records() async {
            await assertSQL(
                of: Reminder.insert {
                    $0
                } values: {
                    Reminder(id: 100, remindersListID: 1, title: "Check email")
                }
                .returning(\.id)
            ) {
                """
                INSERT INTO "reminders"
                ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
                VALUES
                (100, NULL, NULL, false, false, '', NULL, 1, 'Check email', '2040-02-14 23:31:30.000')
                RETURNING "reminders"."id"
                """
            }
        }
        @Test func singleRecordWithId() async {
            await assertSQL(
                of: Reminder.insert {
                    Reminder(id: 101, remindersListID: 1, title: "Check voicemail")
                }
                .returning(\.id)
            ) {
                """
                INSERT INTO "reminders"
                ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
                VALUES
                (101, NULL, NULL, false, false, '', NULL, 1, 'Check voicemail', '2040-02-14 23:31:30.000')
                RETURNING "reminders"."id"
                """
            }
        }
        @Test func multipleRecordsWithIds() async {
            await assertSQL(
                of: Reminder.insert {
                    Reminder(id: 102, remindersListID: 1, title: "Check mailbox")
                    Reminder(id: 103, remindersListID: 1, title: "Check Slack")
                }
                .returning(\.id)
            ) {
                """
                INSERT INTO "reminders"
                ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
                VALUES
                (102, NULL, NULL, false, false, '', NULL, 1, 'Check mailbox', '2040-02-14 23:31:30.000'), (103, NULL, NULL, false, false, '', NULL, 1, 'Check Slack', '2040-02-14 23:31:30.000')
                RETURNING "reminders"."id"
                """
            }
        }
        @Test func anotherSingleRecordWithId() async {
            await assertSQL(
                of: Reminder.insert {
                    Reminder(id: 104, remindersListID: 1, title: "Check pager")
                }
                .returning(\.id)
            ) {
                """
                INSERT INTO "reminders"
                ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
                VALUES
                (104, NULL, NULL, false, false, '', NULL, 1, 'Check pager', '2040-02-14 23:31:30.000')
                RETURNING "reminders"."id"
                """
            }
        }

        @Test func draft() async {
            await assertSQL(
                of: Reminder.insert {
                    Reminder.Draft(remindersListID: 1, title: "Check email")
                }
                .returning(\.id)
            ) {
                """
                INSERT INTO "reminders"
                ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
                VALUES
                (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Check email', '2040-02-14 23:31:30.000')
                RETURNING "reminders"."id"
                """
            }

            await assertSQL(
                of: Reminder.insert {
                    Reminder(id: 12, remindersListID: 1, title: "Check voicemail")
                    Reminder.Draft(remindersListID: 1, title: "Check pager")
                }
                .returning(\.id)
            ) {
                """
                INSERT INTO "reminders"
                ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
                VALUES
                (12, NULL, NULL, false, false, '', NULL, 1, 'Check voicemail', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Check pager', '2040-02-14 23:31:30.000')
                RETURNING "reminders"."id"
                """
            }

            await assertSQL(
                of: Reminder.insert {
                    [
                        Reminder.Draft(remindersListID: 1, title: "Check mailbox"),
                        Reminder.Draft(remindersListID: 1, title: "Check Slack"),
                    ]
                }
                .returning(\.id)
            ) {
                """
                INSERT INTO "reminders"
                ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
                VALUES
                (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Check mailbox', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Check Slack', '2040-02-14 23:31:30.000')
                RETURNING "reminders"."id"
                """
            }
        }
        @Test func upsertWithID() async {
            await assertSQL(
                of: Reminder.where { $0.id == 1 }
            ) {
                """
                SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt"
                FROM "reminders"
                WHERE ("reminders"."id") = (1)
                """
            }

            await assertSQL(
                of:
                    Reminder
                    .upsert { Reminder.Draft(id: 1, remindersListID: 1, title: "Cash check") }
                    .returning(\.self)
            ) {
                """
                INSERT INTO "reminders"
                ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
                VALUES
                (1, NULL, NULL, false, false, '', NULL, 1, 'Cash check', '2040-02-14 23:31:30.000')
                ON CONFLICT ("id")
                DO UPDATE SET "assignedUserID" = "excluded"."assignedUserID", "dueDate" = "excluded"."dueDate", "isCompleted" = "excluded"."isCompleted", "isFlagged" = "excluded"."isFlagged", "notes" = "excluded"."notes", "priority" = "excluded"."priority", "remindersListID" = "excluded"."remindersListID", "title" = "excluded"."title", "updatedAt" = "excluded"."updatedAt"
                RETURNING "id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt"
                """
            }
        }

        @Test func upsertWithoutID_OtherConflict() async {
            await assertSQL(
                of: RemindersList.upsert {
                    RemindersList.Draft(title: "Personal")
                }
                .returning(\.self)
            ) {
                """
                INSERT INTO "remindersLists"
                ("id", "color", "title", "position")
                VALUES
                (DEFAULT, 4889071, 'Personal', 0)
                ON CONFLICT ("id")
                DO UPDATE SET "color" = "excluded"."color", "title" = "excluded"."title", "position" = "excluded"."position"
                RETURNING "id", "color", "title", "position"
                """
            }
        }
        @Test func upsertWithoutID_onConflictDoUpdate() async {
            await assertSQL(
                of: RemindersList.insert {
                    RemindersList.Draft(title: "Personal")
                } onConflict: {
                    $0.title
                } doUpdate: {
                    $0.color = 0x00ff00
                }.returning(\.self)
            ) {
                """
                INSERT INTO "remindersLists"
                ("color", "title", "position")
                VALUES
                (4889071, 'Personal', 0)
                ON CONFLICT ("title")
                DO UPDATE SET "color" = 65280
                RETURNING "id", "color", "title", "position"
                """
            }
        }
        @Test func upsertNonPrimaryKey_onConflictDoUpdate() async {
            await assertSQL(
                of: ReminderTag.insert {
                    ReminderTag(reminderID: 1, tagID: 3)
                } onConflict: {
                    ($0.reminderID, $0.tagID)
                }
                .returning(\.self)
            ) {
                """
                INSERT INTO "remindersTags"
                ("reminderID", "tagID")
                VALUES
                (1, 3)
                ON CONFLICT ("reminderID", "tagID")
                DO NOTHING
                RETURNING "reminderID", "tagID"
                """
            }
        }
        @Test func upsertRepresentation() async {
            await assertSQL(
                of: Item.insert {
                    $0.notes
                } values: {
                    ["Hello", "World"]
                } onConflictDoUpdate: {
                    $0.notes = ["Goodnight", "Moon"]
                }
            ) {
                """
                INSERT INTO "items"
                ("notes")
                VALUES
                ('["Hello","World"]')
                ON CONFLICT DO UPDATE SET "notes" = '["Goodnight","Moon"]'
                """
            }
        }
        @Test func sql() async {
            await assertSQL(
                of: #sql(
                    """
                    INSERT INTO \(Tag.self) ("name")
                    VALUES (\(bind: "office"))
                    RETURNING \(Tag.columns)
                    """,
                    as: Tag.self
                )
            ) {
                """
                INSERT INTO "tags" ("name")
                VALUES ('office')
                RETURNING "tags"."id", "tags"."title"
                """
            }
        }
        @Test func aliasName() async {
            enum R: AliasName {}
            await assertSQL(
                of: RemindersList.as(R.self).insert {
                    $0.title
                } values: {
                    "cruise"
                }
                .returning(\.self)
            ) {
                """
                INSERT INTO "remindersLists" AS "rs"
                ("title")
                VALUES
                ('cruise')
                RETURNING "id", "color", "title", "position"
                """
            }
        }
        @Test func noPrimaryKey() async {
            await assertSQL(
                of: Item.insert { Item() }
            ) {
                """
                INSERT INTO "items"
                ("title", "quantity", "notes")
                VALUES
                ('', 0, '[]')
                """
            }
        }
        @Test func selectedColumns() async {
            await assertSQL(
                of: Item.insert {
                    Item.Columns(
                        title: #sql("'Foo'"),
                        quantity: #sql("42"),
                        notes: #sql("'[]'")
                    )
                }
            ) {
                """
                INSERT INTO "items"
                ("title", "quantity", "notes")
                VALUES
                ('Foo', 42, '[]')
                """
            }
        }
        @Test func onConflictWhereDoUpdateWhere() async {
            await assertSQL(
                of: Reminder.insert {
                    Reminder.Draft(remindersListID: 1)
                } onConflict: {
                    $0.id
                } where: {
                    !$0.isCompleted
                } doUpdate: {
                    $0.isCompleted = $1.isCompleted
                } where: {
                    $0.isFlagged
                }
            ) {
                """
                INSERT INTO "reminders"
                ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
                VALUES
                (DEFAULT, NULL, NULL, false, false, '', NULL, 1, '', '2040-02-14 23:31:30.000')
                ON CONFLICT ("id")
                WHERE NOT ("reminders"."isCompleted")
                DO UPDATE SET "isCompleted" = "excluded"."isCompleted"
                WHERE "reminders"."isFlagged"
                """
            }
        }
        // NB: This currently crashes in Xcode 26.
        @Test func onConflict_invalidUpdateFilters() async {
            await withKnownIssue {
                await assertSQL(
                    of: Reminder.insert {
                        Reminder.Draft(remindersListID: 1)
                    } where: {
                        $0.isFlagged
                    }
                ) {
                    """
                    INSERT INTO "reminders"
                    ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
                    VALUES
                    (DEFAULT, NULL, NULL, false, false, '', NULL, 1, '', '2040-02-14 23:31:30.000')
                    """
                }
            }
        }
        @Test func onConflict_conditionalWhere() async {
            let condition = false
            await assertSQL(
                of: Reminder.insert {
                    Reminder.Draft(remindersListID: 1)
                } where: {
                    if condition {
                        $0.isFlagged
                    }
                }
            ) {
                """
                INSERT INTO "reminders"
                ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
                VALUES
                (DEFAULT, NULL, NULL, false, false, '', NULL, 1, '', '2040-02-14 23:31:30.000')
                """
            }
        }
        @Test func insertSelectSQL() async {
            await assertSQL(
                of: RemindersList.insert {
                    $0.title
                } select: {
                    Values(#sql("'Groceries'"))
                }
                .returning(\.id)
            ) {
                """
                INSERT INTO "remindersLists"
                ("title")
                SELECT 'Groceries'
                RETURNING "remindersLists"."id"
                """
            }
        }
    }
}

@Table private struct Item {
    var title = ""
    var quantity = 0
    @Column(as: [String].JSONB.self)
    var notes: [String] = []
}
