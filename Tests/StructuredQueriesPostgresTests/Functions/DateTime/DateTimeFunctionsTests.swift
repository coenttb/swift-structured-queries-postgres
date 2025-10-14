import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests.DateTime {
    @Suite("Date/Time Functions") struct DateTimeFunctionsTests {

        // MARK: - EXTRACT Function Tests

        @Test func extractYear() async {
            await assertSQL(
                of: Event.where { $0.timestamp.extract(.year) == 2024 }
            ) {
                """
                SELECT "events"."id", "events"."title", "events"."timestamp"
                FROM "events"
                WHERE (EXTRACT(YEAR FROM "events"."timestamp")) = (2024)
                """
            }
        }

        @Test func extractMonth() async {
            await assertSQL(
                of: Event.where { $0.timestamp.extract(.month) == 10 }
            ) {
                """
                SELECT "events"."id", "events"."title", "events"."timestamp"
                FROM "events"
                WHERE (EXTRACT(MONTH FROM "events"."timestamp")) = (10)
                """
            }
        }

        @Test func extractDay() async {
            await assertSQL(
                of: Event.where { $0.timestamp.extract(.day) == 13 }
            ) {
                """
                SELECT "events"."id", "events"."title", "events"."timestamp"
                FROM "events"
                WHERE (EXTRACT(DAY FROM "events"."timestamp")) = (13)
                """
            }
        }

        @Test func extractHour() async {
            await assertSQL(
                of: Event.where { $0.timestamp.extract(.hour) >= 9 }
            ) {
                """
                SELECT "events"."id", "events"."title", "events"."timestamp"
                FROM "events"
                WHERE (EXTRACT(HOUR FROM "events"."timestamp")) >= (9)
                """
            }
        }

        @Test func extractMinute() async {
            await assertSQL(
                of: Event.where { $0.timestamp.extract(.minute) < 30 }
            ) {
                """
                SELECT "events"."id", "events"."title", "events"."timestamp"
                FROM "events"
                WHERE (EXTRACT(MINUTE FROM "events"."timestamp")) < (30)
                """
            }
        }

        @Test func extractSecond() async {
            await assertSQL(
                of: Event.select { $0.timestamp.extract(.second) }
            ) {
                """
                SELECT EXTRACT(SECOND FROM "events"."timestamp")
                FROM "events"
                """
            }
        }

        @Test func extractDayOfWeek() async {
            await assertSQL(
                of: Event.where { $0.timestamp.extract(.dow) == 0 }
            ) {
                """
                SELECT "events"."id", "events"."title", "events"."timestamp"
                FROM "events"
                WHERE (EXTRACT(DOW FROM "events"."timestamp")) = (0)
                """
            }
        }

        @Test func extractDayOfYear() async {
            await assertSQL(
                of: Event.where { $0.timestamp.extract(.doy) > 100 }
            ) {
                """
                SELECT "events"."id", "events"."title", "events"."timestamp"
                FROM "events"
                WHERE (EXTRACT(DOY FROM "events"."timestamp")) > (100)
                """
            }
        }

        @Test func extractEpoch() async {
            await assertSQL(
                of: Event.select { $0.timestamp.extract(.epoch) }
            ) {
                """
                SELECT EXTRACT(EPOCH FROM "events"."timestamp")
                FROM "events"
                """
            }
        }

        // MARK: - DATE_TRUNC Function Tests

        @Test func dateTruncYear() async {
            await assertSQL(
                of: Event.select { $0.timestamp.dateTrunc(.year) }
            ) {
                """
                SELECT DATE_TRUNC('year', "events"."timestamp")
                FROM "events"
                """
            }
        }

        @Test func dateTruncMonth() async {
            await assertSQL(
                of: Event.select { $0.timestamp.dateTrunc(.month) }
            ) {
                """
                SELECT DATE_TRUNC('month', "events"."timestamp")
                FROM "events"
                """
            }
        }

        @Test func dateTruncDay() async {
            await assertSQL(
                of: Event.select { $0.timestamp.dateTrunc(.day) }
            ) {
                """
                SELECT DATE_TRUNC('day', "events"."timestamp")
                FROM "events"
                """
            }
        }

        @Test func dateTruncHour() async {
            await assertSQL(
                of: Event.select { $0.timestamp.dateTrunc(.hour) }
            ) {
                """
                SELECT DATE_TRUNC('hour', "events"."timestamp")
                FROM "events"
                """
            }
        }

        @Test func dateTruncMinute() async {
            await assertSQL(
                of: Event.select { $0.timestamp.dateTrunc(.minute) }
            ) {
                """
                SELECT DATE_TRUNC('minute', "events"."timestamp")
                FROM "events"
                """
            }
        }

        @Test func dateTruncSecond() async {
            await assertSQL(
                of: Event.select { $0.timestamp.dateTrunc(.second) }
            ) {
                """
                SELECT DATE_TRUNC('second', "events"."timestamp")
                FROM "events"
                """
            }
        }

        // MARK: - Current Time Functions Tests

        @Test func currentTimestamp() async {
            await assertSQL(
                of: Event.where { $0.timestamp < Date.currentTimestamp }
            ) {
                """
                SELECT "events"."id", "events"."title", "events"."timestamp"
                FROM "events"
                WHERE ("events"."timestamp") < (CURRENT_TIMESTAMP)
                """
            }
        }

        @Test func currentDate() async {
            await assertSQL(
                of: Event.where { $0.timestamp >= Date.currentDate }
            ) {
                """
                SELECT "events"."id", "events"."title", "events"."timestamp"
                FROM "events"
                WHERE ("events"."timestamp") >= (CURRENT_DATE)
                """
            }
        }

        // MARK: - Real-World Use Cases Tests

        @Test func groupByMonth() async {
            await assertSQL(
                of: Event.select {
                    ($0.timestamp.dateTrunc(.month), $0.id.count())
                }
            ) {
                """
                SELECT DATE_TRUNC('month', "events"."timestamp"), count("events"."id")
                FROM "events"
                """
            }
        }

        @Test func filterByYearAndMonth() async {
            await assertSQL(
                of: Event.where {
                    $0.timestamp.extract(.year) == 2024 && $0.timestamp.extract(.month) == 10
                }
            ) {
                """
                SELECT "events"."id", "events"."title", "events"."timestamp"
                FROM "events"
                WHERE ((EXTRACT(YEAR FROM "events"."timestamp")) = (2024)) AND (EXTRACT(MONTH FROM "events"."timestamp")) = (10)
                """
            }
        }
    }
}

// MARK: - Test Model

@Table
private struct Event {
    let id: Int
    let title: String
    let timestamp: Date
}

// MARK: - SnapshotTests.DateTime Namespace

extension SnapshotTests {
    enum DateTime {}
}
