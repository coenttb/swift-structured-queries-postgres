import Foundation
import StructuredQueriesCore

// MARK: - PostgreSQL String Functions

extension QueryExpression where QueryValue == String {
    /// PostgreSQL's string concatenation using the `||` operator
    ///
    /// ```swift
    /// User.select { $0.firstName.concat(" ").concat($0.lastName) }
    /// // SELECT ("users"."firstName" || ' ' || "users"."lastName") FROM "users"
    /// ```
    public func concat(_ other: String) -> some QueryExpression<String> {
        SQLQueryExpression("(\(self.queryFragment) || \(bind: other))", as: String.self)
    }

    /// PostgreSQL's string concatenation with another expression using the `||` operator
    ///
    /// ```swift
    /// User.select { $0.firstName.concat($0.lastName) }
    /// // SELECT ("users"."firstName" || "users"."lastName") FROM "users"
    /// ```
    public func concat(_ other: some QueryExpression<String>) -> some QueryExpression<String> {
        SQLQueryExpression("(\(self.queryFragment) || \(other.queryFragment))", as: String.self)
    }

    /// PostgreSQL's `POSITION` function - finds the position of a substring
    ///
    /// Returns the position (1-indexed) of the first occurrence of substring, or 0 if not found.
    ///
    /// ```swift
    /// Reminder.where { $0.title.position(of: "buy") > 0 }
    /// // SELECT … FROM "reminders" WHERE POSITION('buy' IN "reminders"."title") > 0
    /// ```
    ///
    /// > Note: SQLite equivalent: `INSTR`
    public func position(of substring: String) -> some QueryExpression<Int> {
        SQLQueryExpression("POSITION(\(bind: substring) IN \(self.queryFragment))", as: Int.self)
    }

    /// PostgreSQL's `STRPOS` function - alternative to POSITION
    ///
    /// Returns the position (1-indexed) of the first occurrence of substring, or 0 if not found.
    ///
    /// ```swift
    /// Reminder.where { $0.title.strpos("buy") > 0 }
    /// // SELECT … FROM "reminders" WHERE STRPOS("reminders"."title", 'buy') > 0
    /// ```
    public func strpos(_ substring: String) -> some QueryExpression<Int> {
        SQLQueryExpression("STRPOS(\(self.queryFragment), \(bind: substring))", as: Int.self)
    }

    /// PostgreSQL's `SUBSTRING` function - extracts a substring
    ///
    /// ```swift
    /// User.select { $0.name.substring(from: 1, for: 5) }
    /// // SELECT SUBSTRING("users"."name" FROM 1 FOR 5) FROM "users"
    ///
    /// User.select { $0.name.substring(from: 10) }
    /// // SELECT SUBSTRING("users"."name" FROM 10) FROM "users"
    /// ```
    public func substring(from start: Int, for length: Int? = nil) -> some QueryExpression<String> {
        if let length {
            return SQLQueryExpression(
                "SUBSTRING(\(self.queryFragment) FROM \(start) FOR \(length))", as: String.self)
        } else {
            return SQLQueryExpression(
                "SUBSTRING(\(self.queryFragment) FROM \(start))", as: String.self)
        }
    }

    /// PostgreSQL's `QUOTE_LITERAL` function - quotes a string for safe SQL inclusion
    ///
    /// Escapes single quotes and wraps the string in single quotes, making it safe to include in SQL.
    ///
    /// ```swift
    /// User.select { $0.comment.quoteLiteral() }
    /// // SELECT QUOTE_LITERAL("users"."comment") FROM "users"
    /// ```
    ///
    /// > Note: SQLite equivalent: `QUOTE`
    public func quoteLiteral() -> some QueryExpression<String> {
        SQLQueryExpression("QUOTE_LITERAL(\(self.queryFragment))", as: String.self)
    }

    /// PostgreSQL's `QUOTE_IDENT` function - quotes an identifier for safe SQL inclusion
    ///
    /// Wraps the identifier in double quotes, making it safe to use as a table or column name.
    ///
    /// ```swift
    /// #sql("SELECT * FROM \(tableName.quoteIdent())")
    /// ```
    public func quoteIdent() -> some QueryExpression<String> {
        SQLQueryExpression("QUOTE_IDENT(\(self.queryFragment))", as: String.self)
    }

    /// PostgreSQL's `ASCII` function - returns the ASCII code of the first character
    ///
    /// ```swift
    /// User.select { $0.name.ascii() }
    /// // SELECT ASCII("users"."name") FROM "users"
    /// ```
    ///
    /// > Note: SQLite equivalent: `UNICODE` (partial - only ASCII range)
    public func ascii() -> some QueryExpression<Int?> {
        SQLQueryExpression("ASCII(\(self.queryFragment))", as: Int?.self)
    }

    /// PostgreSQL's `trim` function - removes characters from both ends of a string
    ///
    /// Removes leading and trailing whitespace (or specified characters) from the string.
    ///
    /// ```swift
    /// User.select { $0.name.trim() }
    /// // SELECT trim("users"."name") FROM "users"
    ///
    /// User.select { $0.name.trim(characters: "x") }
    /// // SELECT trim('x' FROM "users"."name") FROM "users"
    /// ```
    ///
    /// - Parameter characters: Characters to remove (defaults to whitespace)
    /// - Returns: The string with leading and trailing characters removed
    ///
    /// > Note: For more control, use `btrim()`, `ltrim()`, or `rtrim()` from StringManipulation
    public func trim(characters: String? = nil) -> some QueryExpression<String> {
        if let characters {
            return SQLQueryExpression(
                "trim(\(bind: characters) FROM \(self.queryFragment))",
                as: String.self
            )
        } else {
            return SQLQueryExpression(
                "trim(\(self.queryFragment))",
                as: String.self
            )
        }
    }
}

// MARK: - String Concatenation with Separator

/// Concatenates multiple strings with a separator, ignoring NULL values
///
/// PostgreSQL's `concat_ws(separator, str1, str2, ...)` function.
///
/// ```swift
/// let fullName = concatWithSeparator(" ", $0.firstName, $0.middleName, $0.lastName)
/// // SELECT concat_ws(' ', "firstName", "middleName", "lastName")
/// ```
///
/// - Parameters:
///   - separator: The separator to use between strings
///   - strings: Variable number of string expressions
/// - Returns: Concatenated string with separator
///
/// > Note: NULL values are skipped, not converted to empty strings
public func concatWithSeparator(
    _ separator: String,
    _ s1: some QueryExpression<String?>
) -> some QueryExpression<String> {
    SQLQueryExpression(
        "concat_ws(\(bind: separator), \(s1.queryFragment))",
        as: String.self
    )
}

/// Concatenates two strings with a separator, ignoring NULL values
public func concatWithSeparator(
    _ separator: String,
    _ s1: some QueryExpression<String?>,
    _ s2: some QueryExpression<String?>
) -> some QueryExpression<String> {
    SQLQueryExpression(
        "concat_ws(\(bind: separator), \(s1.queryFragment), \(s2.queryFragment))",
        as: String.self
    )
}

/// Concatenates three strings with a separator, ignoring NULL values
public func concatWithSeparator(
    _ separator: String,
    _ s1: some QueryExpression<String?>,
    _ s2: some QueryExpression<String?>,
    _ s3: some QueryExpression<String?>
) -> some QueryExpression<String> {
    SQLQueryExpression(
        "concat_ws(\(bind: separator), \(s1.queryFragment), \(s2.queryFragment), \(s3.queryFragment))",
        as: String.self
    )
}

/// Concatenates four strings with a separator, ignoring NULL values
public func concatWithSeparator(
    _ separator: String,
    _ s1: some QueryExpression<String?>,
    _ s2: some QueryExpression<String?>,
    _ s3: some QueryExpression<String?>,
    _ s4: some QueryExpression<String?>
) -> some QueryExpression<String> {
    SQLQueryExpression(
        "concat_ws(\(bind: separator), \(s1.queryFragment), \(s2.queryFragment), \(s3.queryFragment), \(s4.queryFragment))",
        as: String.self
    )
}
