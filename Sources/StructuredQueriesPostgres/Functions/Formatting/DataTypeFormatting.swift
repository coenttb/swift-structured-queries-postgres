import Foundation
import StructuredQueriesCore

// MARK: - PostgreSQL Data Type Formatting Functions
//
// PostgreSQL Chapter 9.8: Data Type Formatting Functions
// https://www.postgresql.org/docs/18/functions-formatting.html
//
// Functions for formatting timestamps, dates, times, numbers, and other data types to/from strings.

// MARK: - TO_CHAR Functions

extension QueryExpression where QueryValue == Date {
  /// Converts timestamp to string using a format pattern
  ///
  /// PostgreSQL's `to_char(timestamp, text)` function.
  ///
  /// ```swift
  /// Order.select { $0.createdAt.toChar("YYYY-MM-DD HH24:MI:SS") }
  /// // SELECT to_char("orders"."createdAt", 'YYYY-MM-DD HH24:MI:SS') FROM "orders"
  /// ```
  ///
  /// Common format patterns:
  /// - `YYYY` - 4-digit year
  /// - `MM` - Month number (01-12)
  /// - `DD` - Day of month (01-31)
  /// - `HH24` - Hour (00-23)
  /// - `HH` or `HH12` - Hour (01-12)
  /// - `MI` - Minute (00-59)
  /// - `SS` - Second (00-59)
  /// - `MS` - Milliseconds (000-999)
  /// - `Day` - Full day name
  /// - `Mon` - Abbreviated month name
  /// - `TZ` - Time zone abbreviation
  ///
  /// See: https://www.postgresql.org/docs/18/functions-formatting.html#FUNCTIONS-FORMATTING-DATETIME-TABLE
  public func toChar(_ format: String) -> some QueryExpression<String> {
    SQLQueryExpression(
      "to_char(\(self.queryFragment), \(bind: format))",
      as: String.self
    )
  }
}

extension QueryExpression where QueryValue: Numeric & QueryBindable {
  /// Converts number to string using a format pattern
  ///
  /// PostgreSQL's `to_char(numeric, text)` function.
  ///
  /// ```swift
  /// Product.select { $0.price.toChar("$999,999.99") }
  /// // SELECT to_char("products"."price", '$999,999.99') FROM "products"
  /// ```
  ///
  /// Common format patterns:
  /// - `9` - Digit position (can be omitted if zero)
  /// - `0` - Digit position (always shown)
  /// - `.` (period) - Decimal point
  /// - `,` (comma) - Thousands separator
  /// - `$` - Dollar sign
  /// - `FM` - Fill mode (suppress leading zeros/spaces)
  /// - `TH` or `th` - Ordinal number suffix
  ///
  /// Examples:
  /// - `999,999.99` → "1,234.56"
  /// - `FM999999.90` → "1234.50" (no leading spaces)
  /// - `$999,999.00` → "$1,234.00"
  ///
  /// See: https://www.postgresql.org/docs/18/functions-formatting.html#FUNCTIONS-FORMATTING-NUMERIC-TABLE
  public func toChar(_ format: String) -> some QueryExpression<String> {
    SQLQueryExpression(
      "to_char(\(self.queryFragment), \(bind: format))",
      as: String.self
    )
  }
}

extension QueryExpression where QueryValue == Int {
  /// Converts integer to string using a format pattern
  ///
  /// PostgreSQL's `to_char(int, text)` function.
  ///
  /// ```swift
  /// Stats.select { $0.count.toChar("FM999,999") }
  /// // SELECT to_char("stats"."count", 'FM999,999') FROM "stats"
  /// ```
  public func toChar(_ format: String) -> some QueryExpression<String> {
    SQLQueryExpression(
      "to_char(\(self.queryFragment), \(bind: format))",
      as: String.self
    )
  }
}

extension QueryExpression where QueryValue == Double {
  /// Converts double to string using a format pattern
  ///
  /// PostgreSQL's `to_char(double precision, text)` function.
  ///
  /// ```swift
  /// Measurement.select { $0.value.toChar("999.999EEEE") }
  /// // SELECT to_char("measurements"."value", '999.999EEEE') FROM "measurements"
  /// ```
  public func toChar(_ format: String) -> some QueryExpression<String> {
    SQLQueryExpression(
      "to_char(\(self.queryFragment), \(bind: format))",
      as: String.self
    )
  }
}

// MARK: - TO_DATE and TO_TIMESTAMP Functions

extension QueryExpression where QueryValue == String {
  /// Converts string to date using a format pattern
  ///
  /// PostgreSQL's `to_date(text, text)` function.
  ///
  /// ```swift
  /// Import.select { $0.dateString.toDate(format: "YYYY-MM-DD") }
  /// // SELECT to_date("imports"."dateString", 'YYYY-MM-DD') FROM "imports"
  /// ```
  ///
  /// Common format patterns:
  /// - `YYYY` - 4-digit year
  /// - `MM` - Month number (01-12)
  /// - `DD` - Day of month (01-31)
  /// - `Mon` - Abbreviated month name
  /// - `Month` - Full month name
  /// - `Day` - Full day name
  ///
  /// Examples:
  /// - `"2024-01-15"` with format `"YYYY-MM-DD"` → 2024-01-15
  /// - `"Jan 15, 2024"` with format `"Mon DD, YYYY"` → 2024-01-15
  ///
  /// See: https://www.postgresql.org/docs/18/functions-formatting.html#FUNCTIONS-FORMATTING-DATETIME-TABLE
  public func toDate(format: String) -> some QueryExpression<Date> {
    SQLQueryExpression(
      "to_date(\(self.queryFragment), \(bind: format))",
      as: Date.self
    )
  }

  /// Converts string to timestamp using a format pattern
  ///
  /// PostgreSQL's `to_timestamp(text, text)` function.
  ///
  /// ```swift
  /// Import.select { $0.timestampString.toTimestamp(format: "YYYY-MM-DD HH24:MI:SS") }
  /// // SELECT to_timestamp("imports"."timestampString", 'YYYY-MM-DD HH24:MI:SS') FROM "imports"
  /// ```
  ///
  /// Common format patterns (in addition to date patterns):
  /// - `HH24` - Hour (00-23)
  /// - `HH` or `HH12` - Hour (01-12)
  /// - `MI` - Minute (00-59)
  /// - `SS` - Second (00-59)
  /// - `MS` - Milliseconds (000-999)
  /// - `US` - Microseconds (000000-999999)
  /// - `AM` or `PM` - Meridiem indicator
  /// - `TZ` - Time zone abbreviation
  ///
  /// Examples:
  /// - `"2024-01-15 14:30:00"` with format `"YYYY-MM-DD HH24:MI:SS"` → timestamp
  /// - `"Jan 15, 2024 2:30 PM"` with format `"Mon DD, YYYY HH:MI PM"` → timestamp
  ///
  /// See: https://www.postgresql.org/docs/18/functions-formatting.html#FUNCTIONS-FORMATTING-DATETIME-TABLE
  public func toTimestamp(format: String) -> some QueryExpression<Date> {
    SQLQueryExpression(
      "to_timestamp(\(self.queryFragment), \(bind: format))",
      as: Date.self
    )
  }
}

/// Converts Unix timestamp (seconds since epoch) to timestamp
///
/// PostgreSQL's `to_timestamp(double precision)` function.
///
/// ```swift
/// Event.select { toTimestamp($0.unixTime) }
/// // SELECT to_timestamp("events"."unixTime") FROM "events"
/// ```
///
/// - Parameter unixTimestamp: Unix timestamp expression (seconds since 1970-01-01 00:00:00 UTC)
/// - Returns: Timestamp with time zone
public func toTimestamp(_ unixTimestamp: some QueryExpression<Double>) -> some QueryExpression<Date>
{
  SQLQueryExpression(
    "to_timestamp(\(unixTimestamp.queryFragment))",
    as: Date.self
  )
}

// MARK: - TO_NUMBER Function

extension QueryExpression where QueryValue == String {
  /// Converts string to number using a format pattern
  ///
  /// PostgreSQL's `to_number(text, text)` function.
  ///
  /// ```swift
  /// Import.select { $0.priceString.toNumber(format: "999,999.99") }
  /// // SELECT to_number("imports"."priceString", '999,999.99') FROM "imports"
  /// ```
  ///
  /// Common format patterns:
  /// - `9` - Digit position
  /// - `0` - Digit position (leading zeros)
  /// - `.` (period) - Decimal point
  /// - `,` (comma) - Thousands separator
  /// - `$` - Dollar sign
  /// - `S` - Plus/minus sign
  /// - `MI` - Minus sign if negative
  /// - `PL` - Plus sign if positive
  ///
  /// Examples:
  /// - `"1,234.56"` with format `"999,999.99"` → 1234.56
  /// - `"$1,234.00"` with format `"$999,999.00"` → 1234.00
  ///
  /// See: https://www.postgresql.org/docs/18/functions-formatting.html#FUNCTIONS-FORMATTING-NUMERIC-TABLE
  public func toNumber(format: String) -> some QueryExpression<Double> {
    SQLQueryExpression(
      "to_number(\(self.queryFragment), \(bind: format))",
      as: Double.self
    )
  }
}

// MARK: - AGE Function

extension QueryExpression where QueryValue == Date {
  /// Calculates the age (interval) from this timestamp to now
  ///
  /// PostgreSQL's `age(timestamp)` function.
  ///
  /// ```swift
  /// User.select { $0.birthDate.age() }
  /// // SELECT age("users"."birthDate") FROM "users"
  /// ```
  ///
  /// Returns an interval like "3 years 2 months 5 days"
  public func age() -> some QueryExpression<String> {
    SQLQueryExpression(
      "age(\(self.queryFragment))",
      as: String.self
    )
  }

  /// Calculates the age (interval) between two timestamps
  ///
  /// PostgreSQL's `age(timestamp, timestamp)` function.
  ///
  /// ```swift
  /// Event.select { $0.endDate.age(from: $0.startDate) }
  /// // SELECT age("events"."endDate", "events"."startDate") FROM "events"
  /// ```
  ///
  /// - Parameter from: The earlier timestamp
  /// - Returns: An interval representing the difference
  public func age(from: Date) -> some QueryExpression<String> {
    SQLQueryExpression(
      "age(\(self.queryFragment), \(bind: from))",
      as: String.self
    )
  }

  /// Calculates the age (interval) between two timestamp expressions
  ///
  /// PostgreSQL's `age(timestamp, timestamp)` function.
  public func age(from: some QueryExpression<Date>) -> some QueryExpression<String> {
    SQLQueryExpression(
      "age(\(self.queryFragment), \(from.queryFragment))",
      as: String.self
    )
  }
}

// MARK: - JUSTIFY Functions

extension QueryExpression where QueryValue == String {
  /// Adjusts interval so 30-day periods are represented as months
  ///
  /// PostgreSQL's `justify_days(interval)` function.
  ///
  /// ```swift
  /// Duration.select { $0.interval.justifyDays() }
  /// // SELECT justify_days("durations"."interval") FROM "durations"
  /// ```
  public func justifyDays() -> some QueryExpression<String> {
    SQLQueryExpression(
      "justify_days(\(self.queryFragment))",
      as: String.self
    )
  }

  /// Adjusts interval so 24-hour periods are represented as days
  ///
  /// PostgreSQL's `justify_hours(interval)` function.
  ///
  /// ```swift
  /// Duration.select { $0.interval.justifyHours() }
  /// // SELECT justify_hours("durations"."interval") FROM "durations"
  /// ```
  public func justifyHours() -> some QueryExpression<String> {
    SQLQueryExpression(
      "justify_hours(\(self.queryFragment))",
      as: String.self
    )
  }

  /// Adjusts interval using both justify_days and justify_hours
  ///
  /// PostgreSQL's `justify_interval(interval)` function.
  ///
  /// ```swift
  /// Duration.select { $0.interval.justifyInterval() }
  /// // SELECT justify_interval("durations"."interval") FROM "durations"
  /// ```
  public func justifyInterval() -> some QueryExpression<String> {
    SQLQueryExpression(
      "justify_interval(\(self.queryFragment))",
      as: String.self
    )
  }
}
