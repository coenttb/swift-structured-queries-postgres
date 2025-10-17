import Foundation
import StructuredQueriesCore

// MARK: - PostgreSQL Date/Time Field Extraction
/// Fields that can be extracted from a date/time value using `EXTRACT`
///
/// Each field has a specific return type based on PostgreSQL behavior.
public struct DateField<ReturnType: QueryBindable> {
    let sqlName: String

    private init(_ sqlName: String) {
        self.sqlName = sqlName
    }
}

// MARK: - Integer-returning fields

extension DateField where ReturnType == Int {
    /// Extracts the year (integer)
    public static var year: DateField<Int> { DateField("YEAR") }

    /// Extracts the month (integer, 1-12)
    public static var month: DateField<Int> { DateField("MONTH") }

    /// Extracts the day of month (integer, 1-31)
    public static var day: DateField<Int> { DateField("DAY") }

    /// Extracts the hour (integer, 0-23)
    public static var hour: DateField<Int> { DateField("HOUR") }

    /// Extracts the minute (integer, 0-59)
    public static var minute: DateField<Int> { DateField("MINUTE") }

    /// Extracts the day of week (integer, 0-6, Sunday is 0)
    public static var dow: DateField<Int> { DateField("DOW") }

    /// Extracts the day of year (integer, 1-365/366)
    public static var doy: DateField<Int> { DateField("DOY") }
}

// MARK: - Double-returning fields

extension DateField where ReturnType == Double {
    /// Extracts seconds since Unix epoch (double precision)
    ///
    /// Returns seconds since 1970-01-01 00:00:00 UTC as a Double.
    public static var epoch: DateField<Double> { DateField("EPOCH") }

    /// Extracts the second (double precision, can include fractional seconds)
    ///
    /// Returns the seconds field, including fractional seconds.
    public static var second: DateField<Double> { DateField("SECOND") }
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
    /// Type-safe extraction with correct return types for each field.
    ///
    /// ```swift
    /// Reminder.where { $0.dueDate.extract(.year) == 2024 }
    /// // SELECT … FROM "reminders" WHERE EXTRACT(YEAR FROM "reminders"."dueDate") = 2024
    /// // Returns Int
    ///
    /// Event.select { $0.timestamp.extract(.epoch) }
    /// // SELECT EXTRACT(EPOCH FROM "events"."timestamp") FROM "events"
    /// // Returns Double (seconds since 1970-01-01)
    ///
    /// Log.select { $0.createdAt.extract(.second) }
    /// // SELECT EXTRACT(SECOND FROM "logs"."createdAt") FROM "logs"
    /// // Returns Double (with fractional seconds)
    /// ```
    ///
    /// - Parameter field: The date/time field to extract
    /// - Returns: Int for year, month, day, hour, minute, dow, doy
    ///            Double for epoch and second (which can have fractional parts)
    public func extract<T>(_ field: DateField<T>) -> some QueryExpression<T> {
        SQLQueryExpression(
            "EXTRACT(\(raw: field.sqlName) FROM \(self.queryFragment))",
            as: T.self
        )
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
            "DATE_TRUNC('\(raw: precision.rawValue)', \(self.queryFragment))",
            as: Date.self
        )
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
