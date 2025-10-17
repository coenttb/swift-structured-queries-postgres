import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests.UUIDFunctions {
    @Suite("UUID Functions") struct UUIDFunctionsTests {

        // MARK: - Generation Tests

        @Test("UUID.random generates gen_random_uuid()")
        func randomGeneration() async {
            await assertSQL(
                of: UUIDUser.insert {
                    UUIDUser.Columns(id: UUID.random, name: #sql("'Alice'"), email: #sql("NULL"))
                }
            ) {
                """
                INSERT INTO "uuidUsers"
                ("id", "name", "email")
                VALUES
                (gen_random_uuid(), 'Alice', NULL)
                """
            }
        }

        @Test("UUID.v4 generates uuidv4()")
        func v4Generation() async {
            await assertSQL(
                of: UUIDUser.insert {
                    UUIDUser.Columns(id: UUID.v4, name: #sql("'Bob'"), email: #sql("NULL"))
                }
            ) {
                """
                INSERT INTO "uuidUsers"
                ("id", "name", "email")
                VALUES
                (uuidv4(), 'Bob', NULL)
                """
            }
        }

        @Test("UUID.timeOrdered generates uuidv7()")
        func timeOrderedGeneration() async {
            await assertSQL(
                of: UUIDEvent.insert {
                    UUIDEvent.Columns(id: UUID.timeOrdered, title: #sql("'Login'"), userId: #sql("NULL"), timestamp: #sql("NULL"))
                }
            ) {
                """
                INSERT INTO "uuidEvents"
                ("id", "title", "userId", "timestamp")
                VALUES
                (uuidv7(), 'Login', NULL, NULL)
                """
            }
        }

        @Test("UUID.v7 generates uuidv7()")
        func v7Generation() async {
            await assertSQL(
                of: UUIDEvent.insert {
                    UUIDEvent.Columns(id: UUID.v7, title: #sql("'Logout'"), userId: #sql("NULL"), timestamp: #sql("NULL"))
                }
            ) {
                """
                INSERT INTO "uuidEvents"
                ("id", "title", "userId", "timestamp")
                VALUES
                (uuidv7(), 'Logout', NULL, NULL)
                """
            }
        }

        @Test("UUID.timeOrdered(shift:) generates uuidv7(interval)")
        func timeOrderedWithShift() async {
            await assertSQL(
                of: UUIDEvent.insert {
                    UUIDEvent.Columns(id: UUID.timeOrdered(shift: "-1 hour"), title: #sql("'Historical Event'"), userId: #sql("NULL"), timestamp: #sql("NULL"))
                }
            ) {
                """
                INSERT INTO "uuidEvents"
                ("id", "title", "userId", "timestamp")
                VALUES
                (uuidv7('-1 hour'::interval), 'Historical Event', NULL, NULL)
                """
            }
        }

        // MARK: - Extraction - Version Tests

        @Test("extractVersion() from UUID column")
        func extractVersionFromColumn() async {
            await assertSQL(
                of: UUIDUser.select { $0.id.extractVersion() }
            ) {
                """
                SELECT uuid_extract_version("uuidUsers"."id")
                FROM "uuidUsers"
                """
            }
        }

        @Test("Filter by extractVersion() in WHERE clause")
        func filterByVersion() async {
            await assertSQL(
                of: UUIDEvent.where { $0.id.extractVersion() == 7 }
            ) {
                """
                SELECT "uuidEvents"."id", "uuidEvents"."title", "uuidEvents"."userId", "uuidEvents"."timestamp"
                FROM "uuidEvents"
                WHERE (uuid_extract_version("uuidEvents"."id")) = (7)
                """
            }
        }

        // MARK: - Extraction - Timestamp Tests

        @Test("extractTimestamp() from UUIDv7")
        func extractTimestampFromV7() async {
            await assertSQL(
                of: UUIDEvent.select { $0.id.extractTimestamp() }
            ) {
                """
                SELECT uuid_extract_timestamp("uuidEvents"."id")
                FROM "uuidEvents"
                """
            }
        }

        @Test("extractTimestamp() returns NULL for UUIDv4")
        func extractTimestampNullHandling() async {
            // UUIDv4 doesn't have timestamp, so this would return NULL
            await assertSQL(
                of: UUIDUser.select { $0.id.extractTimestamp() }
            ) {
                """
                SELECT uuid_extract_timestamp("uuidUsers"."id")
                FROM "uuidUsers"
                """
            }
        }

        @Test("Filter by extractTimestamp() with NULL check")
        func filterByTimestampWithNullCheck() async {
            await assertSQL(
                of: UUIDEvent.where {
                    $0.id.extractTimestamp() != nil
                }
            ) {
                """
                SELECT "uuidEvents"."id", "uuidEvents"."title", "uuidEvents"."userId", "uuidEvents"."timestamp"
                FROM "uuidEvents"
                WHERE (uuid_extract_timestamp("uuidEvents"."id")) IS DISTINCT FROM (NULL)
                """
            }
        }

        // MARK: - Composition Tests

        @Test("Use UUID.random in INSERT with RETURNING")
        func insertWithReturning() async {
            await assertSQL(
                of: UUIDUser.insert {
                    UUIDUser.Columns(id: UUID.random, name: #sql("'Charlie'"), email: #sql("NULL"))
                }
            ) {
                """
                INSERT INTO "uuidUsers"
                ("id", "name", "email")
                VALUES
                (gen_random_uuid(), 'Charlie', NULL)
                """
            }
        }

        @Test("Filter by extractVersion() in WHERE clause")
        func whereClauseWithVersion() async {
            await assertSQL(
                of: UUIDEvent.where { $0.id.extractVersion() == 7 }
            ) {
                """
                SELECT "uuidEvents"."id", "uuidEvents"."title", "uuidEvents"."userId", "uuidEvents"."timestamp"
                FROM "uuidEvents"
                WHERE (uuid_extract_version("uuidEvents"."id")) = (7)
                """
            }
        }

        @Test("Order by extractTimestamp() in ORDER BY")
        func orderByTimestamp() async {
            // Order events by extracted timestamp from UUID
            await assertSQL(
                of: UUIDEvent.order(by: { $0.id.extractTimestamp() })
            ) {
                """
                SELECT "uuidEvents"."id", "uuidEvents"."title", "uuidEvents"."userId", "uuidEvents"."timestamp"
                FROM "uuidEvents"
                ORDER BY uuid_extract_timestamp("uuidEvents"."id")
                """
            }
        }

        // MARK: - Real-World Use Cases

        @Test("INSERT multiple rows with UUID.timeOrdered")
        func insertMultipleTimeOrdered() async {
            await assertSQL(
                of: UUIDEvent.insert {
                    UUIDEvent.Columns(id: UUID.timeOrdered, title: #sql("'Event 1'"), userId: #sql("NULL"), timestamp: #sql("NULL"))
                    UUIDEvent.Columns(id: UUID.timeOrdered, title: #sql("'Event 2'"), userId: #sql("NULL"), timestamp: #sql("NULL"))
                    UUIDEvent.Columns(id: UUID.timeOrdered, title: #sql("'Event 3'"), userId: #sql("NULL"), timestamp: #sql("NULL"))
                }
            ) {
                """
                INSERT INTO "uuidEvents"
                ("id", "title", "userId", "timestamp")
                VALUES
                (uuidv7(), 'Event 1', NULL, NULL), (uuidv7(), 'Event 2', NULL, NULL), (uuidv7(), 'Event 3', NULL, NULL)
                """
            }
        }

        @Test("Complex query: Filter v7 UUIDs created after specific date")
        func complexFilterByVersionAndTimestamp() async {
            // Real-world: Find all events with v7 UUIDs created in the last hour
            await assertSQL(
                of: UUIDEvent.where {
                    $0.id.extractVersion() == 7 &&
                    $0.id.extractTimestamp() != nil
                }
            ) {
                """
                SELECT "uuidEvents"."id", "uuidEvents"."title", "uuidEvents"."userId", "uuidEvents"."timestamp"
                FROM "uuidEvents"
                WHERE ((uuid_extract_version("uuidEvents"."id")) = (7)) AND (uuid_extract_timestamp("uuidEvents"."id")) IS DISTINCT FROM (NULL)
                """
            }
        }

        // MARK: - Edge Cases & Advanced Patterns

        @Test("Extract timestamp and compare with table timestamp column")
        func compareExtractedTimestampWithColumn() async {
            // Edge case: Compare UUID embedded timestamp with actual timestamp column
            await assertSQL(
                of: UUIDEvent.where {
                    $0.id.extractTimestamp() != nil
                }
            ) {
                """
                SELECT "uuidEvents"."id", "uuidEvents"."title", "uuidEvents"."userId", "uuidEvents"."timestamp"
                FROM "uuidEvents"
                WHERE (uuid_extract_timestamp("uuidEvents"."id")) IS DISTINCT FROM (NULL)
                """
            }
        }

        @Test("SELECT UUID generation in query")
        func generationInSelect() async {
            // Advanced: Generate UUID in SELECT clause
            await assertSQL(
                of: UUIDEvent.select { _ in PostgreSQL.UUID.timeOrdered() }
            ) {
                """
                SELECT uuidv7()
                FROM "uuidEvents"
                """
            }
        }

        @Test("Filter events using time shift for backdating")
        func backdatingWithTimeShift() async {
            // Real-world: Create historical records with adjusted timestamps
            await assertSQL(
                of: UUIDEvent.insert {
                    ($0.id, $0.title)
                } values: {
                    (PostgreSQL.UUID.timeOrdered(shift: "-1 day"), SQLQueryExpression("'Yesterday\\'s Event'"))
                    (PostgreSQL.UUID.timeOrdered(shift: "-2 days"), SQLQueryExpression("'Event from 2 days ago'"))
                }
            ) {
                """
                INSERT INTO "uuidEvents"
                ("id", "title")
                VALUES
                (uuidv7('-1 day'::interval), 'Yesterday\\'s Event'), (uuidv7('-2 days'::interval), 'Event from 2 days ago')
                """
            }
        }

        @Test("Select version distribution across events")
        func versionDistribution() async {
            // Analytics: Count events by UUID version
            await assertSQL(
                of: UUIDEvent.select {
                    ($0.id.extractVersion(), $0.id.count())
                }
            ) {
                """
                SELECT uuid_extract_version("uuidEvents"."id"), count("uuidEvents"."id")
                FROM "uuidEvents"
                """
            }
        }

        @Test("Optional UUID extraction")
        func optionalUUIDExtraction() async {
            // Edge case: Extract from optional UUID column
            await assertSQL(
                of: UUIDEvent.select { $0.userId.extractVersion() }
            ) {
                """
                SELECT uuid_extract_version("uuidEvents"."userId")
                FROM "uuidEvents"
                """
            }
        }
    }
}

// MARK: - Test Models

@Table
private struct UUIDUser {
    let id: UUID
    let name: String
    let email: String?
}

@Table
private struct UUIDEvent {
    let id: UUID
    let title: String
    let userId: UUID?
    let timestamp: Date?
}

// MARK: - SnapshotTests.UUIDFunctions Namespace

extension SnapshotTests {
    enum UUIDFunctions {}
}
