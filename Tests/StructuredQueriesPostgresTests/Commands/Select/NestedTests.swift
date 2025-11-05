import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests.Commands.Select {
    @Suite("Nested") struct NestedTests {

        @Test func basicColumnGroupSelect() async {
            await assertSQL(of: Item.all) {
                """
                SELECT "items"."title", "items"."quantity", "items"."isOutOfStock", "items"."isOnBackOrder"
                FROM "items"
                """
            }
        }

        @Test func columnGroupInsert() async {
            await assertSQL(
                of:
                    Item
                    .insert {
                        Item(title: "Phone", quantity: 1, status: Status())
                    }
                    .returning(\.self)
            ) {
                """
                INSERT INTO "items"
                ("title", "quantity", "isOutOfStock", "isOnBackOrder")
                VALUES
                ('Phone', 1, false, false)
                RETURNING "title", "quantity", "isOutOfStock", "isOnBackOrder"
                """
            }
        }

        @Test func columnGroupUpdateNestedField() async {
            await assertSQL(
                of: Item.update {
                    $0.status.isOutOfStock = true
                }
            ) {
                """
                UPDATE "items"
                SET "isOutOfStock" = true
                """
            }
        }

        @Test func columnGroupUpdateFullGroup() async {
            await assertSQL(
                of: Item.update {
                    $0.status = Status(isOutOfStock: true, isOnBackOrder: true)
                }
            ) {
                """
                UPDATE "items"
                SET "isOutOfStock" = true, "isOnBackOrder" = true
                """
            }
        }

        @Test func generatedColumnInGroup() async {
            // Test INSERT excludes generated column
            await assertSQL(
                of:
                    RowWithTimestamps
                    .insert {
                        RowWithTimestamps(
                            id: UUID(0),
                            timestamps: Timestamps(
                                createdAt: Date(timeIntervalSinceReferenceDate: 0),
                                updatedAt: Date(timeIntervalSinceReferenceDate: 0),
                                isDeleted: false
                            )
                        )
                    }
                    .returning(\.self)
            ) {
                """
                INSERT INTO "rows"
                ("id", "createdAt", "updatedAt", "deletedAt")
                VALUES
                ('00000000-0000-0000-0000-000000000000', '2001-01-01 00:00:00.000', '2001-01-01 00:00:00.000', NULL)
                RETURNING "id", "createdAt", "updatedAt", "deletedAt", "isDeleted"
                """
            }

            // Test SELECT includes generated column
            await assertSQL(of: RowWithTimestamps.all) {
                """
                SELECT "rows"."id", "rows"."createdAt", "rows"."updatedAt", "rows"."deletedAt", "rows"."isDeleted"
                FROM "rows"
                """
            }
        }

        @Test func doubleNested() async {
            await assertSQL(of: A.select { _ in A.Columns(b: B.Columns(c: C.Columns(d: 42))) }) {
                """
                SELECT 42 AS "d"
                FROM "as"
                """
            }

            await assertSQL(of: Values(A.Columns(b: B.Columns(c: C.Columns(d: 42))))) {
                """
                SELECT 42 AS "d"
                """
            }
        }

        @Test func optionalNestedSelect() async {
            await assertSQL(
                of: ItemWithTimestamp(item: nil, timestamp: Date(timeIntervalSinceReferenceDate: 0))
            ) {
                """
                SELECT NULL AS "title", NULL AS "quantity", NULL AS "isOutOfStock", NULL AS "isOnBackOrder", '2001-01-01 00:00:00.000' AS "timestamp"
                """
            }
        }

        @Test func optionalNestedInsert() async {
            await assertSQL(
                of: ItemWithTimestamp.insert {
                    ItemWithTimestamp(item: nil, timestamp: Date(timeIntervalSinceReferenceDate: 0))
                }
            ) {
                """
                INSERT INTO "itemWithTimestamps"
                ("title", "quantity", "isOutOfStock", "isOnBackOrder", "timestamp")
                VALUES
                (NULL, NULL, NULL, NULL, '2001-01-01 00:00:00.000')
                """
            }

            await assertSQL(
                of: ItemWithTimestamp.insert {
                    ItemWithTimestamp(
                        item: Item(
                            title: "Pencil",
                            quantity: 0,
                            status: Status(isOutOfStock: true, isOnBackOrder: true)
                        ),
                        timestamp: Date(timeIntervalSinceReferenceDate: 0)
                    )
                }
            ) {
                """
                INSERT INTO "itemWithTimestamps"
                ("title", "quantity", "isOutOfStock", "isOnBackOrder", "timestamp")
                VALUES
                ('Pencil', 0, true, true, '2001-01-01 00:00:00.000')
                """
            }
        }

        @Test func nestedPayload() async {
            let baseQuery =
                RemindersList
                .where { _ in #sql("color > 0") }
                .join(Reminder.all) { $0.id.eq($1.remindersListID) }

            await assertSQL(
                of:
                    baseQuery
                    .select {
                        RemindersListAndReminderCountPayload.Columns(
                            payload: RemindersListAndReminderCount.Columns(
                                remindersList: $0,
                                remindersCount: $1.id.count()
                            )
                        )
                    }
            ) {
                """
                SELECT "remindersLists"."id" AS "id", "remindersLists"."color" AS "color", "remindersLists"."title" AS "title", "remindersLists"."position" AS "position", count("reminders"."id") AS "remindersCount"
                FROM "remindersLists"
                JOIN "reminders" ON ("remindersLists"."id") = ("reminders"."remindersListID")
                WHERE color > 0
                """
            }
        }

        @Test func columnGroupWhereClause() async {
            await assertSQL(of: Item.where { $0.status.eq(Status()) }) {
                """
                SELECT "items"."title", "items"."quantity", "items"."isOutOfStock", "items"."isOnBackOrder"
                FROM "items"
                WHERE ("items"."isOutOfStock", "items"."isOnBackOrder") = (false, false)
                """
            }
        }

        @Test func partialInsertWithColumnGroup() async {
            await assertSQL(
                of: Item.insert {
                    $0.status
                } values: {
                    Status(isOutOfStock: true, isOnBackOrder: true)
                }
            ) {
                """
                INSERT INTO "items"
                ("isOutOfStock", "isOnBackOrder")
                VALUES
                (true, true)
                """
            }
        }

        @Test func partialInsertWithNestedColumn() async {
            await assertSQL(
                of: Item.insert {
                    $0.status.isOutOfStock
                } values: {
                    true
                }
            ) {
                """
                INSERT INTO "items"
                ("isOutOfStock")
                VALUES
                (true)
                """
            }
        }

        @Test func compositePrimaryKey() async {
            let now = Date(timeIntervalSinceReferenceDate: 0)

            // Test INSERT
            await assertSQL(
                of:
                    Metadata
                    .insert {
                        Metadata.Draft(userModificationDate: now)
                    }
                    .returning(\.self)
            ) {
                """
                INSERT INTO "metadatas"
                ("recordID", "recordType", "userModificationDate")
                VALUES
                (NULL, NULL, '2001-01-01 00:00:00.000')
                RETURNING "recordID", "recordType", "userModificationDate"
                """
            }

            // Test find with composite PK
            await assertSQL(
                of: Metadata.find(MetadataID(recordID: UUID(0), recordType: "reminders"))
            ) {
                """
                SELECT "metadatas"."recordID", "metadatas"."recordType", "metadatas"."userModificationDate"
                FROM "metadatas"
                WHERE ("metadatas"."recordID", "metadatas"."recordType") IN ('00000000-0000-0000-0000-000000000000', 'reminders')
                """
            }
        }
    }
}

// MARK: - Test Support Types

@Table
private struct Item {
    var title: String
    var quantity = 0
    var status: Status = Status()
}

@Selection
private struct Status {
    var isOutOfStock = false
    var isOnBackOrder = false
}

@Table
private struct ItemWithTimestamp {
    var item: Item?
    var timestamp: Date
}

@Selection
struct RemindersListAndReminderCountPayload {
    let payload: RemindersListAndReminderCount
}

@Selection struct C {
    var d: Int
}

@Selection struct B {
    var c: C
}

@Table struct A {
    var b: B
}

@Selection
private struct Timestamps {
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    @Column(generated: .virtual)
    let isDeleted: Bool
}

@Table("rows")
private struct RowWithTimestamps {
    let id: UUID
    var timestamps: Timestamps
}

@Table
private struct Metadata: Identifiable {
    let id: MetadataID
    var userModificationDate: Date
}

@Selection
private struct MetadataID: Hashable {
    let recordID: UUID
    let recordType: String
}
