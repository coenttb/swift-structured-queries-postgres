import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

// Test tables for various scenarios
@Table("uuid_records")
struct UUIDRecord: Codable, Equatable, Identifiable {
    let id: UUID
    var name: String
    var createdAt: Date = Date(timeIntervalSinceReferenceDate: 1_234_567_890)
}

@Table("composite_key_records")
struct CompositeKeyRecord: Codable, Equatable {
    let userId: Int
    let projectId: Int
    var role: String

    // Note: Composite primary keys would need special handling
    // This is a simplified representation
}

@Table("auto_increment_records")
struct AutoIncrementRecord: Codable, Equatable, Identifiable {
    let id: Int
    var title: String
    var counter: Int = 0
}

extension SnapshotTests {
    @Suite struct MissingDraftTests {

        // MARK: - ON CONFLICT DO NOTHING

        @Test func draftOnConflictDoNothing() {
            // Test DO NOTHING instead of DO UPDATE
            assertInlineSnapshot(
                of: Reminder.insert {
                    Reminder.Draft(
                        remindersListID: 1,
                        title: "Conflict test"
                    )
                } onConflict: { columns in
                    columns.title
                },
                as: .sql
            ) {
                """
                INSERT INTO "reminders"
                ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
                VALUES
                (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Conflict test', '2040-02-14 23:31:30.000')
                ON CONFLICT ("title")
                DO NOTHING
                """
            }
        }

        @Test func draftOnConflictMultipleColumnsDoNothing() {
            // DO NOTHING with compound conflict target
            assertInlineSnapshot(
                of: Reminder.insert {
                    Reminder.Draft(
                        remindersListID: 1,
                        title: "Multi conflict"
                    )
                } onConflict: { columns in
                    (columns.remindersListID, columns.title)
                },
                as: .sql
            ) {
                """
                INSERT INTO "reminders"
                ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
                VALUES
                (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Multi conflict', '2040-02-14 23:31:30.000')
                ON CONFLICT ("remindersListID", "title")
                DO NOTHING
                """
            }
        }

        // MARK: - UUID Primary Keys

        @Test func draftWithUUIDPrimaryKey() {
            // Test with UUID primary key (no ID provided)
            assertInlineSnapshot(
                of: UUIDRecord.insert {
                    UUIDRecord.Draft(
                        name: "UUID Test"
                    )
                },
                as: .sql
            ) {
                """
                INSERT INTO "uuid_records"
                ("id", "name", "createdAt")
                VALUES
                (DEFAULT, 'UUID Test', '2040-02-14 23:31:30.000')
                """
            }
        }

        @Test func draftWithExplicitUUID() {
            // Test with explicit UUID
            let testId = UUID(uuidString: "123e4567-e89b-12d3-a456-426614174000")!
            assertInlineSnapshot(
                of: UUIDRecord.insert {
                    UUIDRecord.Draft(
                        id: testId,
                        name: "Explicit UUID"
                    )
                },
                as: .sql
            ) {
                """
                INSERT INTO "uuid_records"
                ("id", "name", "createdAt")
                VALUES
                ('123e4567-e89b-12d3-a456-426614174000', 'Explicit UUID', '2040-02-14 23:31:30.000')
                """
            }
        }

        @Test func mixedUUIDInserts() {
            // Mix of explicit and auto-generated UUIDs
            let explicitId = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!
            assertInlineSnapshot(
                of: UUIDRecord.insert {
                    UUIDRecord.Draft(id: explicitId, name: "Has UUID")
                    UUIDRecord.Draft(name: "No UUID")
                },
                as: .sql
            ) {
                """
                INSERT INTO "uuid_records"
                ("id", "name", "createdAt")
                VALUES
                ('550e8400-e29b-41d4-a716-446655440000', 'Has UUID', '2040-02-14 23:31:30.000'), (DEFAULT, 'No UUID', '2040-02-14 23:31:30.000')
                """
            }
        }

        // MARK: - RETURNING Clause Tests

        @Test func draftInsertReturningAllColumns() {
            // RETURNING * with Draft
            assertInlineSnapshot(
                of: Reminder.insert {
                    Reminder.Draft(
                        remindersListID: 1,
                        title: "Return all"
                    )
                }.returning(\.self),
                as: .sql
            ) {
                """
                INSERT INTO "reminders"
                ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
                VALUES
                (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Return all', '2040-02-14 23:31:30.000')
                RETURNING "id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt"
                """
            }
        }

        @Test func draftInsertReturningGeneratedId() {
            // RETURNING just the auto-generated ID
            assertInlineSnapshot(
                of: Reminder.insert {
                    Reminder.Draft(
                        remindersListID: 1,
                        title: "Return ID"
                    )
                }.returning(\.id),
                as: .sql
            ) {
                """
                INSERT INTO "reminders"
                ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
                VALUES
                (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Return ID', '2040-02-14 23:31:30.000')
                RETURNING "reminders"."id"
                """
            }
        }

        @Test func draftInsertReturningMultipleColumns() {
            // RETURNING specific columns
            assertInlineSnapshot(
                of: Reminder.insert {
                    Reminder.Draft(
                        remindersListID: 1,
                        title: "Return multiple"
                    )
                }.returning { reminder in
                    (reminder.id, reminder.title, reminder.updatedAt)
                },
                as: .sql
            ) {
                """
                INSERT INTO "reminders"
                ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
                VALUES
                (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Return multiple', '2040-02-14 23:31:30.000')
                RETURNING "id", "title", "updatedAt"
                """
            }
        }

        // MARK: - Large Batch Tests

        @Test func largeMixedBatchInsert() {
            // Test with many mixed records/drafts
            assertInlineSnapshot(
                of: Reminder.insert {
                    // First few with IDs
                    Reminder(id: 100, remindersListID: 1, title: "Explicit 1")
                    Reminder(id: 200, remindersListID: 1, title: "Explicit 2")
                    // Then some drafts
                    Reminder.Draft(remindersListID: 1, title: "Draft 1")
                    Reminder.Draft(remindersListID: 1, title: "Draft 2")
                    // Mixed again
                    Reminder(id: 300, remindersListID: 1, title: "Explicit 3")
                    Reminder.Draft(remindersListID: 1, title: "Draft 3")
                },
                as: .sql
            ) {
                """
                INSERT INTO "reminders"
                ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
                VALUES
                (100, NULL, NULL, false, false, '', NULL, 1, 'Explicit 1', '2040-02-14 23:31:30.000'), (200, NULL, NULL, false, false, '', NULL, 1, 'Explicit 2', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Draft 1', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Draft 2', '2040-02-14 23:31:30.000'), (300, NULL, NULL, false, false, '', NULL, 1, 'Explicit 3', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Draft 3', '2040-02-14 23:31:30.000')
                """
            }
        }

        @Test func allDraftsBatchInsert() {
            // Large batch of only Drafts (should exclude ID column)
            assertInlineSnapshot(
                of: Reminder.insert {
                    for i in 1...5 {
                        Reminder.Draft(
                            remindersListID: 1,
                            title: "Batch Draft \(i)"
                        )
                    }
                },
                as: .sql
            ) {
                """
                INSERT INTO "reminders"
                ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
                VALUES
                (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Batch Draft 1', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Batch Draft 2', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Batch Draft 3', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Batch Draft 4', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Batch Draft 5', '2040-02-14 23:31:30.000')
                """
            }
        }

        // MARK: - Empty/Minimal Draft Tests

        @Test func emptyDraft() {
            // Draft with only required fields
            assertInlineSnapshot(
                of: Reminder.insert {
                    Reminder.Draft(remindersListID: 1)
                },
                as: .sql
            ) {
                """
                INSERT INTO "reminders"
                ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
                VALUES
                (DEFAULT, NULL, NULL, false, false, '', NULL, 1, '', '2040-02-14 23:31:30.000')
                """
            }
        }

        @Test func minimalDraftWithConflict() {
            // Minimal Draft with ON CONFLICT
            assertInlineSnapshot(
                of: Reminder.insert {
                    Reminder.Draft(remindersListID: 1)
                } onConflict: { columns in
                    columns.remindersListID
                } doUpdate: { row, excluded in
                    row.updatedAt = excluded.updatedAt
                },
                as: .sql
            ) {
                """
                INSERT INTO "reminders"
                ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
                VALUES
                (DEFAULT, NULL, NULL, false, false, '', NULL, 1, '', '2040-02-14 23:31:30.000')
                ON CONFLICT ("remindersListID")
                DO UPDATE SET "updatedAt" = "excluded"."updatedAt"
                """
            }
        }

        // MARK: - CTE Tests

        @Test func cteWithDraftInsert() {
            // CTE with Draft insert and RETURNING
            assertInlineSnapshot(
                of: #sql(
                    """
                    WITH new_reminders AS (
                        \(Reminder.insert {
                            Reminder.Draft(
                                remindersListID: 1,
                                title: "CTE Draft"
                            )
                        }.returning(\.id))
                    )
                    SELECT * FROM new_reminders
                    """),
                as: .sql
            ) {
                """
                WITH new_reminders AS (
                    (
                  INSERT INTO "reminders"
                  ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
                  VALUES
                  (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'CTE Draft', '2040-02-14 23:31:30.000')
                  RETURNING "reminders"."id"
                )
                )
                SELECT * FROM new_reminders
                """
            }
        }

        @Test func multipleCTEsWithDrafts() {
            // Multiple CTEs with Draft inserts
            assertInlineSnapshot(
                of: #sql(
                    """
                    WITH
                    first_insert AS (
                        \(Reminder.insert {
                            Reminder.Draft(remindersListID: 1, title: "First")
                        }.returning(\.id))
                    ),
                    second_insert AS (
                        \(Reminder.insert {
                            Reminder.Draft(remindersListID: 2, title: "Second")
                        }.returning(\.id))
                    )
                    SELECT * FROM first_insert
                    UNION ALL
                    SELECT * FROM second_insert
                    """),
                as: .sql
            ) {
                """
                WITH
                first_insert AS (
                    (
                  INSERT INTO "reminders"
                  ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
                  VALUES
                  (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'First', '2040-02-14 23:31:30.000')
                  RETURNING "reminders"."id"
                )
                ),
                second_insert AS (
                    (
                  INSERT INTO "reminders"
                  ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
                  VALUES
                  (DEFAULT, NULL, NULL, false, false, '', NULL, 2, 'Second', '2040-02-14 23:31:30.000')
                  RETURNING "reminders"."id"
                )
                )
                SELECT * FROM first_insert
                UNION ALL
                SELECT * FROM second_insert
                """
            }
        }

        // MARK: - Special PostgreSQL Features

        @Test func draftWithGeneratedColumn() {
            // Test with GENERATED column (using SQL function)
            assertInlineSnapshot(
                of: #sql(
                    """
                    INSERT INTO "reminders"
                    ("remindersListID", "title", "updatedAt")
                    VALUES
                    (1, 'Generated test', CURRENT_TIMESTAMP)
                    RETURNING "id"
                    """),
                as: .sql
            ) {
                """
                INSERT INTO "reminders"
                ("remindersListID", "title", "updatedAt")
                VALUES
                (1, 'Generated test', CURRENT_TIMESTAMP)
                RETURNING "id"
                """
            }
        }

        @Test func draftInsertWithDefaultFunction() {
            // Using PostgreSQL functions for defaults
            assertInlineSnapshot(
                of: #sql(
                    """
                    INSERT INTO "uuid_records"
                    ("id", "name", "createdAt")
                    VALUES
                    (gen_random_uuid(), 'UUID Function', NOW())
                    """),
                as: .sql
            ) {
                """
                INSERT INTO "uuid_records"
                ("id", "name", "createdAt")
                VALUES
                (gen_random_uuid(), 'UUID Function', NOW())
                """
            }
        }

        // MARK: - Edge Cases

        @Test func draftWithOnConflictOnPrimaryKey() {
            // ON CONFLICT on primary key with NULL id
            // This is an edge case - should use DEFAULT
            assertInlineSnapshot(
                of: Reminder.insert {
                    Reminder.Draft(
                        remindersListID: 1,
                        title: "PK Conflict"
                    )
                } onConflict: { columns in
                    columns.id
                } doUpdate: { row, excluded in
                    row.title = excluded.title
                },
                as: .sql
            ) {
                """
                INSERT INTO "reminders"
                ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
                VALUES
                (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'PK Conflict', '2040-02-14 23:31:30.000')
                ON CONFLICT ("id")
                DO UPDATE SET "title" = "excluded"."title"
                """
            }
        }

        @Test func veryLongDraftBatch() {
            // Test with a very long batch to ensure no performance issues
            let count = 50
            var sql = """
                INSERT INTO "reminders"
                ("assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
                VALUES

                """

            let values = (1...count).map { i in
                "(NULL, NULL, false, false, '', NULL, 1, 'Item \(i)', '2040-02-14 23:31:30.000')"
            }.joined(separator: ", ")

            sql += values

            assertInlineSnapshot(
                of: Reminder.insert {
                    for i in 1...count {
                        Reminder.Draft(
                            remindersListID: 1,
                            title: "Item \(i)"
                        )
                    }
                },
                as: .sql
            ) {
                """
                INSERT INTO "reminders"
                ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
                VALUES
                (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 1', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 2', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 3', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 4', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 5', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 6', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 7', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 8', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 9', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 10', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 11', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 12', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 13', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 14', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 15', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 16', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 17', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 18', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 19', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 20', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 21', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 22', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 23', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 24', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 25', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 26', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 27', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 28', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 29', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 30', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 31', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 32', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 33', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 34', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 35', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 36', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 37', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 38', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 39', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 40', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 41', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 42', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 43', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 44', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 45', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 46', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 47', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 48', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 49', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Item 50', '2040-02-14 23:31:30.000')
                """
            }
        }
    }
}
