import Foundation
import StructuredQueriesCore

// MARK: - Date/Time Truncation
//
// PostgreSQL Chapter 9.9: Date/Time Functions and Operators
// https://www.postgresql.org/docs/18/functions-datetime.html
//
// DATE_TRUNC function for truncating timestamps to specified precision

/// Precision levels for date/time truncation using `DATE_TRUNC`
public enum DateTruncPrecision: String {
  case year = "year"
  case month = "month"
  case day = "day"
  case hour = "hour"
  case minute = "minute"
  case second = "second"
}

extension QueryExpression where QueryValue == Date {
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
