import Foundation
import IssueReporting
import StructuredQueriesCore

/// A PostgreSQL trigger function written in PL/pgSQL.
///
/// Trigger functions are the first tier of PostgreSQL's two-tier trigger system. A trigger function
/// contains the PL/pgSQL code that executes when a trigger fires. Functions can be reused across
/// multiple triggers.
///
/// ## Example
///
/// ```swift
/// // Create a reusable timestamp function
/// let updateTimestamp = Trigger.Function<User>.plpgsql(
///   "update_timestamp",
///   """
///   BEGIN
///     NEW.updated_at = CURRENT_TIMESTAMP;
///     RETURN NEW;
///   END;
///   """
/// )
///
/// // Use it in multiple triggers
/// let userTrigger = User.createTrigger("user_ts", timing: .before, events: [.update], function: updateTimestamp)
/// let profileTrigger = Profile.createTrigger("profile_ts", timing: .before, events: [.update], function: updateTimestamp)
/// ```
extension Trigger {
    public struct Function: Sendable, Statement {
        public typealias From = Never
        public typealias Joins = ()
        public typealias QueryValue = ()

        /// The function name
        public let name: String

        /// Whether to use CREATE OR REPLACE
        public let orReplace: Bool

        /// The PL/pgSQL function body
        private let body: QueryFragment

        init(name: String, body: QueryFragment, orReplace: Bool = true) {
            self.name = name
            self.body = body
            self.orReplace = orReplace
        }

        public var query: QueryFragment {
            var query: QueryFragment = "CREATE"
            if orReplace {
                query.append(" OR REPLACE")
            }
            query.append(" FUNCTION \(quote: name)()")
            query.append("\(.newline)RETURNS TRIGGER AS $$")
            query.append("\(.newline)\(generateBody())")
            query.append("\(.newline)$$ LANGUAGE plpgsql")
            return query
        }

        private func generateBody() -> QueryFragment {
            // Wrap raw PL/pgSQL in BEGIN...END if not already present
            let bodyString = body.debugDescription
            let trimmed = bodyString.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.uppercased().hasPrefix("BEGIN") {
                return body
            } else {
                var result: QueryFragment = "BEGIN"
                result.append("\(.newline)\(body.indented())")
                result.append("\(.newline)END")
                return result
            }
        }

        /// Returns a `DROP FUNCTION` statement for this function.
        ///
        /// - Parameters:
        ///   - ifExists: Adds an `IF EXISTS` condition to the `DROP FUNCTION`.
        ///   - cascade: Adds `CASCADE` to automatically drop dependent triggers.
        /// - Returns: A `DROP FUNCTION` statement for this function.
        public func drop(ifExists: Bool = false, cascade: Bool = false) -> some Statement<()> {
            var query: QueryFragment = "DROP FUNCTION"
            if ifExists {
                query.append(" IF EXISTS")
            }
            query.append(" \(quote: name)()")
            if cascade {
                query.append(" CASCADE")
            }
            return SQLQueryExpression(query)
        }
    }
}

// MARK: - Convenience Constructors

extension Trigger.Function {
    /// Defines a trigger function that performs the specified actions.
    ///
    /// This method uses a result builder to construct the function body, allowing you to
    /// write multiple statements with conditional logic.
    ///
    /// ## Examples
    ///
    /// ```swift
    /// // Using result builder with multiple statements
    /// Trigger.Function<User>.define("update_timestamp") {
    ///   #sql("NEW.updated_at = CURRENT_TIMESTAMP")
    ///   #sql("RETURN NEW")
    /// }
    ///
    /// // With conditional logic
    /// Trigger.Function<User>.define("validate_user") {
    ///   if needsValidation {
    ///     #sql("IF NEW.age < 0 THEN")
    ///     #sql("  RAISE EXCEPTION 'Age cannot be negative'")
    ///     #sql("END IF")
    ///   }
    ///   #sql("RETURN NEW")
    /// }
    ///
    /// // With column interpolation
    /// let column = "updated_at"
    /// Trigger.Function<User>.define("update_column") {
    ///   #sql("NEW.\(quote: column) = CURRENT_TIMESTAMP")
    ///   #sql("RETURN NEW")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - name: The function name.
    ///   - orReplace: Whether to use `CREATE OR REPLACE FUNCTION`. Defaults to `true`.
    ///   - performs: A result builder that generates the function body statements.
    /// - Returns: A trigger function.
    public static func define(
        _ name: String,
        orReplace: Bool = true,
        @QueryFragmentBuilder<any Statement> performs body: () -> [QueryFragment]
    ) -> Self {
        let statements = body()
        var bodyFragment = statements.joined(separator: ";\(.newlineOrSpace)")
        // Ensure the last statement also ends with a semicolon
        bodyFragment.append(";")
        return Self(name: name, body: bodyFragment, orReplace: orReplace)
    }

    /// Defines a trigger function from a single code fragment.
    ///
    /// This overload accepts a single `QueryFragment` for simple cases where you have
    /// the entire function body as one piece. The result builder version is preferred
    /// for most use cases.
    ///
    /// ## Examples
    ///
    /// ```swift
    /// // Simple string literal
    /// Trigger.Function<User>.define("simple_func", """
    ///   NEW.updated_at = CURRENT_TIMESTAMP;
    ///   RETURN NEW;
    ///   """)
    ///
    /// // Using #sql macro for validation
    /// Trigger.Function<User>.define("validated_func", #sql("""
    ///   NEW.updated_at = CURRENT_TIMESTAMP;
    ///   RETURN NEW;
    ///   """))
    /// ```
    ///
    /// - Parameters:
    ///   - name: The function name.
    ///   - orReplace: Whether to use `CREATE OR REPLACE FUNCTION`. Defaults to `true`.
    ///   - performs: The function body as a single `QueryFragment`.
    /// - Returns: A trigger function.
    @_disfavoredOverload
    public static func define(
        _ name: String,
        orReplace: Bool = true,
        performs body: QueryFragment
    ) -> Self {
        Self(name: name, body: body, orReplace: orReplace)
    }

    // MARK: - PL/pgSQL API (for PostgreSQL experts)

    /// Creates a trigger function from PL/pgSQL code using a result builder.
    ///
    /// This is an alias for `define(_:performs:)` for developers familiar with PostgreSQL's
    /// PL/pgSQL language. For idiomatic Swift, use `define(_:performs:)` instead.
    ///
    /// - Parameters:
    ///   - name: The function name.
    ///   - orReplace: Whether to use `CREATE OR REPLACE FUNCTION`. Defaults to `true`.
    ///   - body: A result builder that generates PL/pgSQL statements.
    /// - Returns: A trigger function.
    @_disfavoredOverload
    public static func plpgsql(
        _ name: String,
        orReplace: Bool = true,
        @QueryFragmentBuilder<any Statement> _ body: () -> [QueryFragment]
    ) -> Self {
        define(name, orReplace: orReplace, performs: body)
    }

    /// Creates a trigger function from a single PL/pgSQL code fragment.
    ///
    /// This is an alias for `define(_:performs:)` for developers familiar with PostgreSQL's
    /// PL/pgSQL language. For idiomatic Swift, use `define(_:performs:)` instead.
    ///
    /// - Parameters:
    ///   - name: The function name.
    ///   - orReplace: Whether to use `CREATE OR REPLACE FUNCTION`. Defaults to `true`.
    ///   - body: The PL/pgSQL function body as a single `QueryFragment`.
    /// - Returns: A trigger function.
    @_disfavoredOverload
    public static func plpgsql(
        _ name: String,
        orReplace: Bool = true,
        _ body: QueryFragment
    ) -> Self {
        define(name, orReplace: orReplace, performs: body)
    }
}
