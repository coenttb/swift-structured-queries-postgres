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

    // MARK: - Type Safety Tests

    @Test("EXTRACT returns correct types - epoch returns Double")
    func extractEpochReturnsDouble() async {
      // Demonstrates that epoch returns Double, not Int
      await assertSQL(
        of: Event.where { $0.timestamp.extract(.epoch) > 1700000000.0 }
      ) {
        """
        SELECT "events"."id", "events"."title", "events"."timestamp"
        FROM "events"
        WHERE (EXTRACT(EPOCH FROM "events"."timestamp")) > (1700000000.0)
        """
      }
    }

    @Test("EXTRACT returns correct types - second returns Double with fractional parts")
    func extractSecondReturnsDouble() async {
      // Demonstrates that second can have fractional parts (milliseconds)
      await assertSQL(
        of: Event.where { $0.timestamp.extract(.second) >= 30.5 }
      ) {
        """
        SELECT "events"."id", "events"."title", "events"."timestamp"
        FROM "events"
        WHERE (EXTRACT(SECOND FROM "events"."timestamp")) >= (30.5)
        """
      }
    }

    @Test("EXTRACT returns correct types - year returns Int")
    func extractYearReturnsInt() async {
      // Demonstrates that year returns Int (whole number)
      await assertSQL(
        of: Event.where { $0.timestamp.extract(.year) + 1 == 2025 }
      ) {
        """
        SELECT "events"."id", "events"."title", "events"."timestamp"
        FROM "events"
        WHERE ((EXTRACT(YEAR FROM "events"."timestamp")) + (1)) = (2025)
        """
      }
    }

    // MARK: - Business Hours & Time-Based Filtering

    @Test("Filter events during business hours (9 AM - 5 PM)")
    func businessHoursFiltering() async {
      // Real-world: Find events scheduled during business hours
      await assertSQL(
        of: Event.where {
          $0.timestamp.extract(.hour) >= 9 && $0.timestamp.extract(.hour) < 17
        }
      ) {
        """
        SELECT "events"."id", "events"."title", "events"."timestamp"
        FROM "events"
        WHERE ((EXTRACT(HOUR FROM "events"."timestamp")) >= (9)) AND (EXTRACT(HOUR FROM "events"."timestamp")) < (17)
        """
      }
    }

    @Test("Find weekend events (Saturday and Sunday)")
    func weekendEvents() async {
      // Real-world: Filter events on weekends (dow: 0 = Sunday, 6 = Saturday)
      await assertSQL(
        of: Event.where {
          $0.timestamp.extract(.dow) == 0 || $0.timestamp.extract(.dow) == 6
        }
      ) {
        """
        SELECT "events"."id", "events"."title", "events"."timestamp"
        FROM "events"
        WHERE ((EXTRACT(DOW FROM "events"."timestamp")) = (0)) OR (EXTRACT(DOW FROM "events"."timestamp")) = (6)
        """
      }
    }

    @Test("Find events in first quarter of the year")
    func firstQuarterEvents() async {
      // Real-world: Q1 reporting (January, February, March)
      await assertSQL(
        of: Event.where {
          $0.timestamp.extract(.month) >= 1 && $0.timestamp.extract(.month) <= 3
        }
      ) {
        """
        SELECT "events"."id", "events"."title", "events"."timestamp"
        FROM "events"
        WHERE ((EXTRACT(MONTH FROM "events"."timestamp")) >= (1)) AND (EXTRACT(MONTH FROM "events"."timestamp")) <= (3)
        """
      }
    }

    // MARK: - Time-Based Grouping & Analytics

    @Test("Group events by day for daily analytics")
    func dailyAnalytics() async {
      // Real-world: Daily event counts
      await assertSQL(
        of: Event.select {
          ($0.timestamp.dateTrunc(.day), $0.id.count())
        }
      ) {
        """
        SELECT DATE_TRUNC('day', "events"."timestamp"), count("events"."id")
        FROM "events"
        """
      }
    }

    @Test("Group events by hour for hourly analytics")
    func hourlyAnalytics() async {
      // Real-world: Hourly traffic patterns
      await assertSQL(
        of: Event.select {
          ($0.timestamp.dateTrunc(.hour), $0.id.count())
        }
      ) {
        """
        SELECT DATE_TRUNC('hour', "events"."timestamp"), count("events"."id")
        FROM "events"
        """
      }
    }

    @Test("Get start of current month for comparison")
    func startOfCurrentMonth() async {
      // Real-world: Compare against start of current month
      await assertSQL(
        of: Event.where { $0.timestamp >= Date.currentDate.dateTrunc(.month) }
      ) {
        """
        SELECT "events"."id", "events"."title", "events"."timestamp"
        FROM "events"
        WHERE ("events"."timestamp") >= (DATE_TRUNC('month', CURRENT_DATE))
        """
      }
    }

    // MARK: - Time Duration & Comparison

    @Test("Calculate seconds since epoch for time comparison")
    func epochComparison() async {
      // Real-world: Compare timestamps using Unix epoch
      await assertSQL(
        of: Event.select {
          $0.timestamp.extract(.epoch)
        }
      ) {
        """
        SELECT EXTRACT(EPOCH FROM "events"."timestamp")
        FROM "events"
        """
      }
    }

    @Test("Filter events from last 7 days using epoch")
    func recentEventsUsingEpoch() async {
      // Real-world: Recent events using epoch arithmetic
      let sevenDaysAgo = Date.currentTimestamp.extract(.epoch) - (7 * 24 * 60 * 60)
      await assertSQL(
        of: Event.where { $0.timestamp.extract(.epoch) > sevenDaysAgo }
      ) {
        """
        SELECT "events"."id", "events"."title", "events"."timestamp"
        FROM "events"
        WHERE (EXTRACT(EPOCH FROM "events"."timestamp")) > (EXTRACT(EPOCH FROM CURRENT_TIMESTAMP)) - (604800.0)
        """
      }
    }

    // MARK: - Edge Cases & Special Scenarios

    @Test("Handle events at midnight (hour = 0)")
    func midnightEvents() async {
      // Edge case: Midnight is hour 0
      await assertSQL(
        of: Event.where { $0.timestamp.extract(.hour) == 0 }
      ) {
        """
        SELECT "events"."id", "events"."title", "events"."timestamp"
        FROM "events"
        WHERE (EXTRACT(HOUR FROM "events"."timestamp")) = (0)
        """
      }
    }

    @Test("Handle events on first day of year (doy = 1)")
    func newYearsDayEvents() async {
      // Edge case: January 1st
      await assertSQL(
        of: Event.where { $0.timestamp.extract(.doy) == 1 }
      ) {
        """
        SELECT "events"."id", "events"."title", "events"."timestamp"
        FROM "events"
        WHERE (EXTRACT(DOY FROM "events"."timestamp")) = (1)
        """
      }
    }

    @Test("Handle events on last day of year (doy = 365 or 366)")
    func newYearsEveEvents() async {
      // Edge case: December 31st (365 or 366 for leap years)
      await assertSQL(
        of: Event.where { $0.timestamp.extract(.doy) >= 365 }
      ) {
        """
        SELECT "events"."id", "events"."title", "events"."timestamp"
        FROM "events"
        WHERE (EXTRACT(DOY FROM "events"."timestamp")) >= (365)
        """
      }
    }

    @Test("Find events with fractional seconds (millisecond precision)")
    func fractionalSeconds() async {
      // Edge case: Millisecond precision in timestamps
      await assertSQL(
        of: Event.where { $0.timestamp.extract(.second) > 45.123 }
      ) {
        """
        SELECT "events"."id", "events"."title", "events"."timestamp"
        FROM "events"
        WHERE (EXTRACT(SECOND FROM "events"."timestamp")) > (45.123)
        """
      }
    }

    // MARK: - Complex Real-World Queries

    @Test("Monthly event summary with date truncation")
    func monthlyEventSummary() async {
      // Real-world: Aggregate events by month with @Selection macro for type-safe results
      await assertSQL(
        of: Event.select {
          MonthlyEventSummary.Columns(
            monthStart: $0.timestamp.dateTrunc(.month),
            eventCount: $0.id.count(),
            year: $0.timestamp.extract(.year),
            month: $0.timestamp.extract(.month)
          )
        }
      ) {
        """
        SELECT DATE_TRUNC('month', "events"."timestamp") AS "monthStart", count("events"."id") AS "eventCount", EXTRACT(YEAR FROM "events"."timestamp") AS "year", EXTRACT(MONTH FROM "events"."timestamp") AS "month"
        FROM "events"
        """
      }
    }

    @Test("Find events in current year")
    func currentYearEvents() async {
      // Real-world: Year-to-date reporting
      await assertSQL(
        of: Event.where { $0.timestamp.extract(.year) == Date.currentDate.extract(.year) }
      ) {
        """
        SELECT "events"."id", "events"."title", "events"."timestamp"
        FROM "events"
        WHERE (EXTRACT(YEAR FROM "events"."timestamp")) = (EXTRACT(YEAR FROM CURRENT_DATE))
        """
      }
    }

    @Test("Find events happening today")
    func todayEvents() async {
      // Real-world: Today's schedule
      await assertSQL(
        of: Event.where { $0.timestamp.dateTrunc(.day) == Date.currentDate }
      ) {
        """
        SELECT "events"."id", "events"."title", "events"."timestamp"
        FROM "events"
        WHERE (DATE_TRUNC('day', "events"."timestamp")) = (CURRENT_DATE)
        """
      }
    }

    @Test("Find events in current hour")
    func currentHourEvents() async {
      // Real-world: Real-time event tracking
      await assertSQL(
        of: Event.where { $0.timestamp.dateTrunc(.hour) == Date.currentTimestamp.dateTrunc(.hour) }
      ) {
        """
        SELECT "events"."id", "events"."title", "events"."timestamp"
        FROM "events"
        WHERE (DATE_TRUNC('hour', "events"."timestamp")) = (DATE_TRUNC('hour', CURRENT_TIMESTAMP))
        """
      }
    }

    @Test("Calculate event age in seconds")
    func eventAgeInSeconds() async {
      // Real-world: How long ago did this event occur?
      await assertSQL(
        of: Event.select {
          Date.currentTimestamp.extract(.epoch) - $0.timestamp.extract(.epoch)
        }
      ) {
        """
        SELECT (EXTRACT(EPOCH FROM CURRENT_TIMESTAMP)) - (EXTRACT(EPOCH FROM "events"."timestamp"))
        FROM "events"
        """
      }
    }

    @Test("Filter events by multiple time criteria")
    func complexTimeFiltering() async {
      // Real-world: Complex business logic - weekday business hours in Q1
      await assertSQL(
        of: Event.where {
          // Q1 (Jan-Mar)
          ($0.timestamp.extract(.month) >= 1 && $0.timestamp.extract(.month) <= 3)
            // Weekday (Mon-Fri, dow: 1-5)
            && ($0.timestamp.extract(.dow) >= 1 && $0.timestamp.extract(.dow) <= 5)
            // Business hours (9 AM - 5 PM)
            && ($0.timestamp.extract(.hour) >= 9 && $0.timestamp.extract(.hour) < 17)
        }
      ) {
        """
        SELECT "events"."id", "events"."title", "events"."timestamp"
        FROM "events"
        WHERE ((((EXTRACT(MONTH FROM "events"."timestamp")) >= (1)) AND (EXTRACT(MONTH FROM "events"."timestamp")) <= (3)) AND ((EXTRACT(DOW FROM "events"."timestamp")) >= (1)) AND (EXTRACT(DOW FROM "events"."timestamp")) <= (5)) AND ((EXTRACT(HOUR FROM "events"."timestamp")) >= (9)) AND (EXTRACT(HOUR FROM "events"."timestamp")) < (17)
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

// MARK: - Test Result Types

/// Example of using @Selection macro for type-safe query results
@Selection
private struct MonthlyEventSummary {
  let monthStart: Date
  let eventCount: Int
  let year: Int
  let month: Int
}

// MARK: - SnapshotTests.DateTime Namespace

extension SnapshotTests {
  enum DateTime {}
}
