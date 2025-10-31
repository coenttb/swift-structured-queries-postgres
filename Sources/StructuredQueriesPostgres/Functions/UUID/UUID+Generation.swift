import Foundation
import StructuredQueriesCore

// MARK: - UUID Generation Functions
//
// PostgreSQL Chapter 9.14: UUID Functions
// https://www.postgresql.org/docs/18/functions-uuid.html
//
// Functions for generating UUIDs server-side

// MARK: - PostgreSQL.UUID Namespace Functions

extension PostgreSQL.UUID {
  /// PostgreSQL's `gen_random_uuid()` - Version 4 (random) UUID
  ///
  /// Generates a cryptographically random UUID suitable for primary keys.
  ///
  /// ```swift
  /// User.insert {
  ///     User.Draft(id: PostgreSQL.UUID.random(), name: "Alice")
  /// }
  /// // INSERT INTO "users" ("id", "name") VALUES (gen_random_uuid(), 'Alice')
  /// ```
  ///
  /// - Returns: A random UUID expression suitable for use in queries
  ///
  /// > Note: Equivalent to PostgreSQL's `gen_random_uuid()` or `uuidv4()`.
  /// > This is the most commonly used UUID type for primary keys.
  ///
  /// > Tip: Use `.timeOrdered()` instead if you need time-ordered UUIDs for better index performance.
  public static func random() -> some QueryExpression<Foundation.UUID> {
    SQLQueryExpression("gen_random_uuid()", as: Foundation.UUID.self)
  }

  /// Alias for `.random()` - PostgreSQL's `uuidv4()`
  ///
  /// Generates a Version 4 (random) UUID.
  ///
  /// ```swift
  /// User.insert {
  ///     User.Draft(id: PostgreSQL.UUID.v4(), name: "Bob")
  /// }
  /// // INSERT INTO "users" ("id", "name") VALUES (uuidv4(), 'Bob')
  /// ```
  ///
  /// - Returns: A random UUID expression
  ///
  /// > Note: This is an alias for `.random()` and generates the same result.
  public static func v4() -> some QueryExpression<Foundation.UUID> {
    SQLQueryExpression("uuidv4()", as: Foundation.UUID.self)
  }

  /// PostgreSQL's `uuidv7()` - Version 7 (time-ordered) UUID
  ///
  /// Generates a time-ordered UUID with better index performance than v4.
  /// Version 7 UUIDs contain a timestamp component that can be extracted.
  ///
  /// ```swift
  /// Event.insert {
  ///     Event.Draft(id: PostgreSQL.UUID.timeOrdered(), name: "Login")
  /// }
  /// // INSERT INTO "events" ("id", "name") VALUES (uuidv7(), 'Login')
  /// ```
  ///
  /// - Returns: A time-ordered UUID expression
  ///
  /// > Note: Requires PostgreSQL 13+. UUIDs sort chronologically, improving index performance.
  ///
  /// > Tip: Extract creation time with `.extractTimestamp()`.
  ///
  /// **Why use v7 over v4?**
  /// - Better B-tree index performance (sequential inserts)
  /// - Natural chronological ordering
  /// - Embedded timestamp can be extracted without separate column
  /// - Reduces index fragmentation
  public static func timeOrdered() -> some QueryExpression<Foundation.UUID> {
    SQLQueryExpression("uuidv7()", as: Foundation.UUID.self)
  }

  /// Alias for `.timeOrdered()` - PostgreSQL's `uuidv7()`
  ///
  /// Generates a Version 7 (time-ordered) UUID.
  ///
  /// ```swift
  /// Event.insert {
  ///     Event.Draft(id: PostgreSQL.UUID.v7(), name: "Logout")
  /// }
  /// // INSERT INTO "events" ("id", "name") VALUES (uuidv7(), 'Logout')
  /// ```
  ///
  /// - Returns: A time-ordered UUID expression
  ///
  /// > Note: This is an alias for `.timeOrdered()` and generates the same result.
  public static func v7() -> some QueryExpression<Foundation.UUID> {
    SQLQueryExpression("uuidv7()", as: Foundation.UUID.self)
  }

  /// PostgreSQL's `uuidv7(interval)` - Time-ordered UUID with timestamp shift
  ///
  /// Generates a time-ordered UUID with an adjusted timestamp.
  /// Useful for backdating or future-dating events.
  ///
  /// ```swift
  /// Event.insert {
  ///     Event.Draft(id: PostgreSQL.UUID.timeOrdered(shift: "-1 hour"), name: "Historical Event")
  /// }
  /// // INSERT INTO "events" ("id", "name") VALUES (uuidv7('-1 hour'::interval), 'Historical Event')
  ///
  /// Reminder.insert {
  ///     Reminder.Draft(id: PostgreSQL.UUID.timeOrdered(shift: "30 minutes"))
  /// }
  /// // INSERT INTO "reminders" ("id") VALUES (uuidv7('30 minutes'::interval))
  /// ```
  ///
  /// - Parameter shift: PostgreSQL interval syntax for time adjustment
  /// - Returns: A time-ordered UUID with shifted timestamp
  ///
  /// > Warning: Invalid interval syntax causes runtime PostgreSQL error.
  ///
  /// **Valid interval examples:**
  /// - Negative shifts (past): `"-1 hour"`, `"-30 minutes"`, `"-2 days"`
  /// - Positive shifts (future): `"30 minutes"`, `"1 day"`, `"2 hours"`
  /// - Complex intervals: `"-1 hour 30 minutes"`, `"1 day 12 hours"`
  ///
  /// **Use cases:**
  /// - Backdating events: `.timeOrdered(shift: "-1 hour")`
  /// - Scheduling future events: `.timeOrdered(shift: "1 day")`
  /// - Testing time-based logic with controlled timestamps
  public static func timeOrdered(shift: String) -> some QueryExpression<Foundation.UUID> {
    SQLQueryExpression("uuidv7('\(raw: shift)'::interval)", as: Foundation.UUID.self)
  }
}

// MARK: - Foundation.UUID Convenience Properties
//
// These provide ergonomic static properties for common usage patterns.
// They delegate to PostgreSQL.UUID namespace functions.

extension Foundation.UUID {
  /// Convenience property for PostgreSQL.UUID.random()
  ///
  /// ```swift
  /// User.insert { User.Draft(id: .random, name: "Alice") }
  /// // INSERT INTO "users" ("id", "name") VALUES (gen_random_uuid(), 'Alice')
  /// ```
  ///
  /// > Note: Delegates to `PostgreSQL.UUID.random()` for implementation.
  public static var random: some QueryExpression<UUID> {
    PostgreSQL.UUID.random()
  }

  /// Convenience property for PostgreSQL.UUID.v4()
  ///
  /// ```swift
  /// User.insert { User.Draft(id: .v4, name: "Bob") }
  /// // INSERT INTO "users" ("id", "name") VALUES (uuidv4(), 'Bob')
  /// ```
  ///
  /// > Note: Delegates to `PostgreSQL.UUID.v4()` for implementation.
  public static var v4: some QueryExpression<UUID> {
    PostgreSQL.UUID.v4()
  }

  /// Convenience property for PostgreSQL.UUID.timeOrdered()
  ///
  /// ```swift
  /// Event.insert { Event.Draft(id: .timeOrdered, name: "Login") }
  /// // INSERT INTO "events" ("id", "name") VALUES (uuidv7(), 'Login')
  /// ```
  ///
  /// > Note: Delegates to `PostgreSQL.UUID.timeOrdered()` for implementation.
  public static var timeOrdered: some QueryExpression<UUID> {
    PostgreSQL.UUID.timeOrdered()
  }

  /// Convenience property for PostgreSQL.UUID.v7()
  ///
  /// ```swift
  /// Event.insert { Event.Draft(id: .v7, name: "Logout") }
  /// // INSERT INTO "events" ("id", "name") VALUES (uuidv7(), 'Logout')
  /// ```
  ///
  /// > Note: Delegates to `PostgreSQL.UUID.v7()` for implementation.
  public static var v7: some QueryExpression<UUID> {
    PostgreSQL.UUID.v7()
  }

  /// Convenience function for PostgreSQL.UUID.timeOrdered(shift:)
  ///
  /// ```swift
  /// Event.insert {
  ///     Event.Draft(id: .timeOrdered(shift: "-1 hour"), name: "Historical Event")
  /// }
  /// // INSERT INTO "events" ("id", "name") VALUES (uuidv7('-1 hour'::interval), 'Historical Event')
  /// ```
  ///
  /// - Parameter shift: PostgreSQL interval syntax for time adjustment
  /// - Returns: A time-ordered UUID with shifted timestamp
  ///
  /// > Note: Delegates to `PostgreSQL.UUID.timeOrdered(shift:)` for implementation.
  public static func timeOrdered(shift: String) -> some QueryExpression<UUID> {
    PostgreSQL.UUID.timeOrdered(shift: shift)
  }
}
