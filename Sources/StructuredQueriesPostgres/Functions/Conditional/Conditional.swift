import Foundation
import StructuredQueriesCore

// MARK: - PostgreSQL Conditional Functions

// MARK: COALESCE

extension QueryExpression where QueryValue: QueryBindable {
    /// PostgreSQL's `COALESCE` function - returns the first non-null value
    ///
    /// ```swift
    /// User.select { $0.nickname.coalesce("Anonymous") }
    /// // SELECT COALESCE("users"."nickname", 'Anonymous') FROM "users"
    /// ```
    ///
    /// > Note: SQLite equivalent: `IFNULL`
    ///
    /// - Parameter defaultValue: The value to return if this expression is NULL
    /// - Returns: The first non-null value between the expression and the default
    public func coalesce(_ defaultValue: QueryValue) -> some QueryExpression<QueryValue> {
        SQLQueryExpression(
            "COALESCE(\(self.queryFragment), \(bind: defaultValue))", as: QueryValue.self)
    }
}

extension QueryExpression {
    /// PostgreSQL's `COALESCE` function with another expression
    ///
    /// ```swift
    /// User.select { $0.nickname.coalesce($0.username) }
    /// // SELECT COALESCE("users"."nickname", "users"."username") FROM "users"
    /// ```
    ///
    /// - Parameter defaultExpression: The expression to evaluate if this one is NULL
    /// - Returns: The first non-null value between the two expressions
    public func coalesce(_ defaultExpression: some QueryExpression<QueryValue>)
        -> some QueryExpression<QueryValue>
    {
        SQLQueryExpression(
            "COALESCE(\(self.queryFragment), \(defaultExpression.queryFragment))",
            as: QueryValue.self)
    }
}

// MARK: EXISTS / NOT EXISTS

/// PostgreSQL's `EXISTS` function - tests whether a subquery returns any rows
///
/// Returns `true` if the subquery returns at least one row, `false` otherwise.
/// More efficient than counting rows when you only need to know if any exist.
///
/// ```swift
/// // Find users who have at least one reminder
/// User.where {
///   exists(
///     Reminder.where { $0.assignedUserID == $1.id }
///   )
/// }
/// // SELECT … FROM "users" WHERE EXISTS (
/// //   SELECT … FROM "reminders" WHERE "reminders"."assignedUserID" = "users"."id"
/// // )
/// ```
///
/// - Parameter subquery: The subquery to test for existence
/// - Returns: A boolean expression indicating whether any rows exist
public func exists(_ subquery: some Statement) -> some QueryExpression<Bool> {
    SQLQueryExpression("EXISTS (\(subquery.queryFragment))", as: Bool.self)
}

/// PostgreSQL's `NOT EXISTS` function - tests whether a subquery returns no rows
///
/// Returns `true` if the subquery returns zero rows, `false` otherwise.
///
/// ```swift
/// // Find users who have no reminders
/// User.where {
///   notExists(
///     Reminder.where { $0.assignedUserID == $1.id }
///   )
/// }
/// // SELECT … FROM "users" WHERE NOT EXISTS (
/// //   SELECT … FROM "reminders" WHERE "reminders"."assignedUserID" = "users"."id"
/// // )
/// ```
///
/// - Parameter subquery: The subquery to test for non-existence
/// - Returns: A boolean expression indicating whether no rows exist
public func notExists(_ subquery: some Statement) -> some QueryExpression<Bool> {
    SQLQueryExpression("NOT EXISTS (\(subquery.queryFragment))", as: Bool.self)
}

// MARK: Aggregate Alternatives

extension QueryExpression where QueryValue: Numeric & QueryBindable {
    /// Returns the sum of values, or 0 if the result set is empty (instead of NULL like `SUM`)
    ///
    /// ```swift
    /// Order.select { $0.amount.sumOrZero() }
    /// // SELECT COALESCE(SUM("orders"."amount"), 0) FROM "orders"
    /// ```
    ///
    /// - Returns: The sum of all values, or 0 if no rows match
    ///
    /// > Note: SQLite equivalent: `TOTAL`
    public func sumOrZero() -> some QueryExpression<QueryValue> {
        SQLQueryExpression("COALESCE(SUM(\(self.queryFragment)), 0)", as: QueryValue.self)
    }

    /// PostgreSQL `SUM` with a custom default value
    ///
    /// Returns the sum of values, or the specified default if the result set is empty.
    ///
    /// ```swift
    /// Order.select { $0.amount.sumOr(100) }
    /// // SELECT COALESCE(SUM("orders"."amount"), 100) FROM "orders"
    /// ```
    ///
    /// - Parameter defaultValue: The value to return if no rows match
    /// - Returns: The sum of all values, or the default value if no rows match
    public func sumOr(_ defaultValue: QueryValue) -> some QueryExpression<QueryValue> {
        SQLQueryExpression(
            "COALESCE(SUM(\(self.queryFragment)), \(bind: defaultValue))", as: QueryValue.self)
    }
}
