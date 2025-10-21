import Foundation
import StructuredQueriesCore

// MARK: - Current Date/Time Functions
//
// PostgreSQL Chapter 9.9: Date/Time Functions and Operators
// https://www.postgresql.org/docs/18/functions-datetime.html
//
// Functions for getting current date/time values

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
