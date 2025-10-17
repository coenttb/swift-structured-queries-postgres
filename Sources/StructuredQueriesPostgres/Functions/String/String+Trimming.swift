import Foundation
import StructuredQueriesCore

// MARK: - String Trimming Functions
//
// PostgreSQL Chapter 9.4: String Functions and Operators
// https://www.postgresql.org/docs/18/functions-string.html
//
// Functions for trimming characters from strings: ltrim(), rtrim(), btrim()/trim()

extension PostgreSQL.String {
    /// Removes specified characters from the start of a string
    ///
    /// PostgreSQL's `ltrim(string [, characters])` function.
    ///
    /// ```swift
    /// PostgreSQL.String.ltrim($0.code, characters: "0")
    /// // SELECT ltrim("users"."code", '0') FROM "users"
    /// ```
    ///
    /// - Parameters:
    ///   - value: The string expression
    ///   - characters: Characters to remove (defaults to whitespace)
    /// - Returns: The string with leading characters removed
    public static func ltrim(
        _ value: some QueryExpression<Swift.String>,
        characters: Swift.String = " "
    ) -> some QueryExpression<Swift.String> {
        SQLQueryExpression(
            "ltrim(\(value.queryFragment), \(bind: characters))",
            as: Swift.String.self
        )
    }

    /// Removes characters from the start of an expression-based string
    ///
    /// PostgreSQL's `ltrim(string, characters)` function.
    public static func ltrim(
        _ value: some QueryExpression<Swift.String>,
        characters: some QueryExpression<Swift.String>
    ) -> some QueryExpression<Swift.String> {
        QueryFunction("ltrim", value, characters)
    }

    /// Removes specified characters from the end of a string
    ///
    /// PostgreSQL's `rtrim(string [, characters])` function.
    ///
    /// ```swift
    /// PostgreSQL.String.rtrim($0.description, characters: ".")
    /// // SELECT rtrim("users"."description", '.') FROM "users"
    /// ```
    ///
    /// - Parameters:
    ///   - value: The string expression
    ///   - characters: Characters to remove (defaults to whitespace)
    /// - Returns: The string with trailing characters removed
    public static func rtrim(
        _ value: some QueryExpression<Swift.String>,
        characters: Swift.String = " "
    ) -> some QueryExpression<Swift.String> {
        SQLQueryExpression(
            "rtrim(\(value.queryFragment), \(bind: characters))",
            as: Swift.String.self
        )
    }

    /// Removes characters from the end of an expression-based string
    ///
    /// PostgreSQL's `rtrim(string, characters)` function.
    public static func rtrim(
        _ value: some QueryExpression<Swift.String>,
        characters: some QueryExpression<Swift.String>
    ) -> some QueryExpression<Swift.String> {
        QueryFunction("rtrim", value, characters)
    }

    /// Removes specified characters from both ends of a string
    ///
    /// PostgreSQL's `btrim(string [, characters])` function.
    ///
    /// ```swift
    /// PostgreSQL.String.btrim($0.name, characters: " -")
    /// // SELECT btrim("users"."name", ' -') FROM "users"
    /// ```
    ///
    /// - Parameters:
    ///   - value: The string expression
    ///   - characters: Characters to remove (defaults to whitespace)
    /// - Returns: The string with leading and trailing characters removed
    public static func btrim(
        _ value: some QueryExpression<Swift.String>,
        characters: Swift.String = " "
    ) -> some QueryExpression<Swift.String> {
        SQLQueryExpression(
            "btrim(\(value.queryFragment), \(bind: characters))",
            as: Swift.String.self
        )
    }

    /// Removes characters from both ends of an expression-based string
    ///
    /// PostgreSQL's `btrim(string, characters)` function.
    public static func btrim(
        _ value: some QueryExpression<Swift.String>,
        characters: some QueryExpression<Swift.String>
    ) -> some QueryExpression<Swift.String> {
        QueryFunction("trim", value, characters)
    }
}

// MARK: - QueryExpression Extension (Fluent API)

extension QueryExpression where QueryValue == Swift.String {
    /// Removes characters from the beginning of a string
    ///
    /// PostgreSQL's `ltrim()` function.
    ///
    /// ```swift
    /// User.select { $0.code.ltrim() }
    /// // SELECT ltrim("users"."code") FROM "users"
    ///
    /// User.select { $0.code.ltrim($0.prefix) }
    /// // SELECT ltrim("users"."code", "users"."prefix") FROM "users"
    /// ```
    ///
    /// - Parameter characters: Characters to trim (defaults to whitespace)
    /// - Returns: An expression wrapped with the `ltrim` function.
    public func ltrim(
        _ characters: (some QueryExpression<QueryValue>)? = QueryValue?.none
    ) -> some QueryExpression<Swift.String> {
        if let characters {
            return SQLQueryExpression("ltrim(\(self.queryFragment), \(characters.queryFragment))", as: Swift.String.self)
        } else {
            return SQLQueryExpression("ltrim(\(self.queryFragment))", as: Swift.String.self)
        }
    }

    /// Removes specified characters from the start of a string
    ///
    /// PostgreSQL's `ltrim(string, characters)` function.
    ///
    /// ```swift
    /// User.select { $0.code.ltrim(characters: "0") }
    /// // SELECT ltrim("users"."code", '0') FROM "users"
    /// ```
    ///
    /// - Parameter characters: Characters to remove
    /// - Returns: The string with leading characters removed
    public func ltrim(characters: Swift.String) -> some QueryExpression<Swift.String> {
        PostgreSQL.String.ltrim(self, characters: characters)
    }

    /// Removes characters from the end of a string
    ///
    /// PostgreSQL's `rtrim()` function.
    ///
    /// ```swift
    /// User.select { $0.description.rtrim() }
    /// // SELECT rtrim("users"."description") FROM "users"
    /// ```
    ///
    /// - Parameter characters: Characters to trim (defaults to whitespace)
    /// - Returns: An expression wrapped with the `rtrim` function.
    public func rtrim(
        _ characters: (some QueryExpression<QueryValue>)? = QueryValue?.none
    ) -> some QueryExpression<Swift.String> {
        if let characters {
            return SQLQueryExpression("rtrim(\(self.queryFragment), \(characters.queryFragment))", as: Swift.String.self)
        } else {
            return SQLQueryExpression("rtrim(\(self.queryFragment))", as: Swift.String.self)
        }
    }

    /// Removes specified characters from the end of a string
    ///
    /// PostgreSQL's `rtrim(string, characters)` function.
    ///
    /// ```swift
    /// User.select { $0.description.rtrim(characters: ".") }
    /// // SELECT rtrim("users"."description", '.') FROM "users"
    /// ```
    ///
    /// - Parameter characters: Characters to remove
    /// - Returns: The string with trailing characters removed
    public func rtrim(characters: Swift.String) -> some QueryExpression<Swift.String> {
        PostgreSQL.String.rtrim(self, characters: characters)
    }

    /// Removes characters from both ends of a string
    ///
    /// PostgreSQL's `trim()` function (via btrim).
    ///
    /// ```swift
    /// User.select { $0.name.trim() }
    /// // SELECT trim("users"."name") FROM "users"
    ///
    /// User.select { $0.name.trim($0.unwantedChars) }
    /// // SELECT trim("users"."name", "users"."unwantedChars") FROM "users"
    /// ```
    ///
    /// - Parameter characters: Characters to trim (defaults to whitespace)
    /// - Returns: An expression wrapped with the `trim` function.
    public func trim(
        _ characters: (some QueryExpression<QueryValue>)? = QueryValue?.none
    ) -> some QueryExpression<Swift.String> {
        if let characters {
            return SQLQueryExpression("trim(\(self.queryFragment), \(characters.queryFragment))", as: Swift.String.self)
        } else {
            return SQLQueryExpression("trim(\(self.queryFragment))", as: Swift.String.self)
        }
    }

    /// Removes specified characters from both ends of a string
    ///
    /// PostgreSQL's `btrim(string, characters)` function.
    ///
    /// ```swift
    /// User.select { $0.name.btrim(characters: " -") }
    /// // SELECT btrim("users"."name", ' -') FROM "users"
    /// ```
    ///
    /// - Parameter characters: Characters to remove
    /// - Returns: The string with leading and trailing characters removed
    public func btrim(characters: Swift.String) -> some QueryExpression<Swift.String> {
        PostgreSQL.String.btrim(self, characters: characters)
    }
}
