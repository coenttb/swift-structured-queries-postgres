import Foundation
import StructuredQueriesCore

// MARK: - PostgreSQL String Manipulation Functions
//
// PostgreSQL Chapter 9.4: String Functions and Operators
// https://www.postgresql.org/docs/18/functions-string.html
//
// String manipulation and transformation functions.

extension QueryExpression where QueryValue == String {
    // MARK: - String Replacement

    /// Replaces all occurrences of a substring with another substring
    ///
    /// PostgreSQL's `replace(string, from, to)` function.
    ///
    /// ```swift
    /// User.select { $0.name.replacing("John", with: "Jane") }
    /// // SELECT replace("users"."name", 'John', 'Jane') FROM "users"
    /// ```
    ///
    /// - Parameters:
    ///   - substring: The substring to find
    ///   - newSubstring: The replacement substring
    /// - Returns: The string with all occurrences replaced
    public func replacing(_ substring: String, with newSubstring: String) -> some QueryExpression<
        String
    > {
        SQLQueryExpression(
            "replace(\(self.queryFragment), \(bind: substring), \(bind: newSubstring))",
            as: String.self
        )
    }

    // MARK: - String Extraction

    /// Returns the first n characters from a string (left part)
    ///
    /// PostgreSQL's `left(string, n)` function.
    ///
    /// ```swift
    /// User.select { $0.name.left(5) }
    /// // SELECT left("users"."name", 5) FROM "users"
    /// ```
    ///
    /// - Parameter n: Number of characters to extract from the left
    /// - Returns: The leftmost n characters
    public func left(_ n: Int) -> some QueryExpression<String> {
        SQLQueryExpression(
            "left(\(self.queryFragment), \(n))",
            as: String.self
        )
    }

    /// Returns the last n characters from a string (right part)
    ///
    /// PostgreSQL's `right(string, n)` function.
    ///
    /// ```swift
    /// User.select { $0.phone.right(4) }
    /// // SELECT right("users"."phone", 4) FROM "users"
    /// ```
    ///
    /// - Parameter n: Number of characters to extract from the right
    /// - Returns: The rightmost n characters
    public func right(_ n: Int) -> some QueryExpression<String> {
        SQLQueryExpression(
            "right(\(self.queryFragment), \(n))",
            as: String.self
        )
    }

    // MARK: - String Transformation

    /// Reverses the order of characters in a string
    ///
    /// PostgreSQL's `reverse(string)` function.
    ///
    /// ```swift
    /// User.select { $0.name.reversed() }
    /// // SELECT reverse("users"."name") FROM "users"
    /// ```
    ///
    /// - Returns: The string with characters in reverse order
    public func reversed() -> some QueryExpression<String> {
        SQLQueryExpression(
            "reverse(\(self.queryFragment))",
            as: String.self
        )
    }

    /// Repeats the string a specified number of times
    ///
    /// PostgreSQL's `repeat(string, n)` function.
    ///
    /// ```swift
    /// User.select { $0.separator.repeated(3) }
    /// // SELECT repeat("users"."separator", 3) FROM "users"
    /// ```
    ///
    /// - Parameter times: Number of times to repeat the string
    /// - Returns: The string repeated n times
    public func repeated(_ times: Int) -> some QueryExpression<String> {
        SQLQueryExpression(
            "repeat(\(self.queryFragment), \(times))",
            as: String.self
        )
    }

    // MARK: - Character Replacement

    /// Replaces each character in the string that matches a character in the from set
    /// with the corresponding character in the to set
    ///
    /// PostgreSQL's `translate(string, from, to)` function.
    ///
    /// ```swift
    /// User.select { $0.phone.translate(from: "()-", to: "") }
    /// // SELECT translate("users"."phone", '()-', '') FROM "users"
    /// ```
    ///
    /// - Parameters:
    ///   - from: Characters to replace
    ///   - to: Replacement characters (positional)
    /// - Returns: The string with characters translated
    ///
    /// > Note: If `to` is shorter than `from`, characters in `from` with no corresponding
    /// > character in `to` are deleted from the result.
    public func translate(from: String, to: String) -> some QueryExpression<String> {
        SQLQueryExpression(
            "translate(\(self.queryFragment), \(bind: from), \(bind: to))",
            as: String.self
        )
    }

    /// Replaces a substring with another substring
    ///
    /// PostgreSQL's `overlay(string placing string from int [for int])` function.
    ///
    /// ```swift
    /// User.select { $0.email.overlay(placing: "***", from: 5, for: 3) }
    /// // SELECT overlay("users"."email" placing '***' from 5 for 3) FROM "users"
    /// ```
    ///
    /// - Parameters:
    ///   - newSubstring: The string to insert
    ///   - position: The starting position (1-indexed)
    ///   - length: Number of characters to replace (optional, defaults to length of newSubstring)
    /// - Returns: The string with the specified portion replaced
    public func overlay(placing newSubstring: String, from position: Int, for length: Int? = nil)
        -> some QueryExpression<String>
    {
        if let length {
            return SQLQueryExpression(
                "overlay(\(self.queryFragment) placing \(bind: newSubstring) from \(position) for \(length))",
                as: String.self
            )
        } else {
            return SQLQueryExpression(
                "overlay(\(self.queryFragment) placing \(bind: newSubstring) from \(position))",
                as: String.self
            )
        }
    }

    // MARK: - Padding

    /// Pads the string on the left with spaces (or specified characters) to reach the specified length
    ///
    /// PostgreSQL's `lpad(string, length [, fill])` function.
    ///
    /// ```swift
    /// User.select { $0.id.lpad(to: 10, with: "0") }
    /// // SELECT lpad("users"."id", 10, '0') FROM "users"
    /// ```
    ///
    /// - Parameters:
    ///   - length: Target length
    ///   - fill: Fill string (defaults to space)
    /// - Returns: The padded string
    public func lpad(to length: Int, with fill: String = " ") -> some QueryExpression<String> {
        SQLQueryExpression(
            "lpad(\(self.queryFragment), \(length), \(bind: fill))",
            as: String.self
        )
    }

    /// Pads the string on the right with spaces (or specified characters) to reach the specified length
    ///
    /// PostgreSQL's `rpad(string, length [, fill])` function.
    ///
    /// ```swift
    /// User.select { $0.name.rpad(to: 20, with: ".") }
    /// // SELECT rpad("users"."name", 20, '.') FROM "users"
    /// ```
    ///
    /// - Parameters:
    ///   - length: Target length
    ///   - fill: Fill string (defaults to space)
    /// - Returns: The padded string
    public func rpad(to length: Int, with fill: String = " ") -> some QueryExpression<String> {
        SQLQueryExpression(
            "rpad(\(self.queryFragment), \(length), \(bind: fill))",
            as: String.self
        )
    }

    // MARK: - Trimming

    /// Removes specified characters from the start of a string
    ///
    /// PostgreSQL's `ltrim(string [, characters])` function.
    ///
    /// ```swift
    /// User.select { $0.code.ltrim(characters: "0") }
    /// // SELECT ltrim("users"."code", '0') FROM "users"
    /// ```
    ///
    /// - Parameter characters: Characters to remove (defaults to whitespace)
    /// - Returns: The string with leading characters removed
    public func ltrim(characters: String = " ") -> some QueryExpression<String> {
        SQLQueryExpression(
            "ltrim(\(self.queryFragment), \(bind: characters))",
            as: String.self
        )
    }

    /// Removes specified characters from the end of a string
    ///
    /// PostgreSQL's `rtrim(string [, characters])` function.
    ///
    /// ```swift
    /// User.select { $0.description.rtrim(characters: ".") }
    /// // SELECT rtrim("users"."description", '.') FROM "users"
    /// ```
    ///
    /// - Parameter characters: Characters to remove (defaults to whitespace)
    /// - Returns: The string with trailing characters removed
    public func rtrim(characters: String = " ") -> some QueryExpression<String> {
        SQLQueryExpression(
            "rtrim(\(self.queryFragment), \(bind: characters))",
            as: String.self
        )
    }

    /// Removes specified characters from both ends of a string
    ///
    /// PostgreSQL's `btrim(string [, characters])` function.
    ///
    /// ```swift
    /// User.select { $0.name.btrim(characters: " -") }
    /// // SELECT btrim("users"."name", ' -') FROM "users"
    /// ```
    ///
    /// - Parameter characters: Characters to remove (defaults to whitespace)
    /// - Returns: The string with leading and trailing characters removed
    public func btrim(characters: String = " ") -> some QueryExpression<String> {
        SQLQueryExpression(
            "btrim(\(self.queryFragment), \(bind: characters))",
            as: String.self
        )
    }
}
