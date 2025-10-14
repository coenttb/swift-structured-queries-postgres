import Foundation
import StructuredQueriesCore

// MARK: - PostgreSQL Date/Time Field Extraction

/// Fields that can be extracted from a date/time value using `EXTRACT`
public enum DateField: String {
    case year = "YEAR"
    case month = "MONTH"
    case day = "DAY"
    case hour = "HOUR"
    case minute = "MINUTE"
    case second = "SECOND"
    case dow = "DOW"  // day of week (0-6, Sunday is 0)
    case doy = "DOY"  // day of year (1-365/366)
    case epoch = "EPOCH"  // seconds since 1970-01-01 00:00:00 UTC
}

/// Precision levels for date/time truncation using `DATE_TRUNC`
public enum DateTruncPrecision: String {
    case year = "year"
    case month = "month"
    case day = "day"
    case hour = "hour"
    case minute = "minute"
    case second = "second"
}

// MARK: - PostgreSQL Date/Time Functions

extension QueryExpression where QueryValue == Date {
    /// PostgreSQL's `EXTRACT` function - extracts a specific field from a date/time value
    ///
    /// ```swift
    /// Reminder.where { $0.dueDate.extract(.year) == 2024 }
    /// // SELECT … FROM "reminders" WHERE EXTRACT(YEAR FROM "reminders"."dueDate") = 2024
    ///
    /// Event.select { $0.timestamp.extract(.epoch) }
    /// // SELECT EXTRACT(EPOCH FROM "events"."timestamp") FROM "events"
    /// ```
    ///
    /// - Parameter field: The date/time field to extract
    /// - Returns: An integer expression for most fields (year, month, day, hour, minute, dow, doy)
    ///            or a double expression for epoch and second (which can have fractional parts)
    public func extract(_ field: DateField) -> some QueryExpression<Int> {
        SQLQueryExpression(
            "EXTRACT(\(raw: field.rawValue) FROM \(self.queryFragment))", as: Int.self)
    }

    /// PostgreSQL's `DATE_TRUNC` function - truncates a date/time to the specified precision
    ///
    /// Rounds down the timestamp to the beginning of the specified time unit.
    ///
    /// ```swift
    /// Event.select { $0.timestamp.dateTrunc(.day) }
    /// // SELECT DATE_TRUNC('day', "events"."timestamp") FROM "events"
    ///
    /// Event.select { $0.timestamp.dateTrunc(.hour) }
    /// // SELECT DATE_TRUNC('hour', "events"."timestamp") FROM "events"
    /// ```
    ///
    /// - Parameter precision: The time unit to truncate to
    /// - Returns: A date expression truncated to the specified precision
    public func dateTrunc(_ precision: DateTruncPrecision) -> some QueryExpression<Date> {
        SQLQueryExpression(
            "DATE_TRUNC('\(raw: precision.rawValue)', \(self.queryFragment))", as: Date.self)
    }
}

// MARK: - PostgreSQL Current Date/Time

extension Date {
    /// PostgreSQL's `CURRENT_TIMESTAMP` - returns the current date and time
    ///
    /// Returns the start time of the current transaction (does not change during the transaction).
    ///
    /// ```swift
    /// Reminder.insert {
    ///   Reminder.Draft(title: "New reminder", createdAt: .currentTimestamp)
    /// }
    /// // INSERT INTO "reminders" ("title", "createdAt") VALUES ('New reminder', CURRENT_TIMESTAMP)
    /// ```
    public static var currentTimestamp: some QueryExpression<Date> {
        SQLQueryExpression("CURRENT_TIMESTAMP", as: Date.self)
    }

    /// PostgreSQL's `CURRENT_DATE` - returns the current date (without time)
    ///
    /// Returns the current date at the start of the transaction.
    ///
    /// ```swift
    /// Event.where { $0.eventDate >= .currentDate }
    /// // SELECT … FROM "events" WHERE "events"."eventDate" >= CURRENT_DATE
    /// ```
    public static var currentDate: some QueryExpression<Date> {
        SQLQueryExpression("CURRENT_DATE", as: Date.self)
    }
}
