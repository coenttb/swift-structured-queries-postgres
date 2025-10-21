import Foundation
import StructuredQueriesCore

// MARK: - PostgreSQL String Functions Namespace
//
// PostgreSQL Chapter 9.4: String Functions and Operators
// https://www.postgresql.org/docs/18/functions-string.html
//
// ## Organization (Matches PostgreSQL Chapter 9.4)
//
// - **Case Conversion**: upper(), lower(), initcap()
// - **Length Functions**: length(), charLength(), bitLength(), octetLength()
// - **Trimming**: ltrim(), rtrim(), btrim()/trim()
// - **Extraction**: substring(), substr(), left(), right(), splitPart()
// - **Manipulation**: replacing(), translate(), overlay(), reversed(), repeated()
// - **Concatenation**: concat(), concatWithSeparator()
// - **Position**: position(), strpos()
// - **Padding**: lpad(), rpad()
// - **Quoting**: quote(), quoteLiteral(), quoteIdent()
// - **Utility**: chr(), ascii(), md5()
//
// ## Dual API Pattern
//
// All string functions support two calling styles:
//
// **Namespace style:**
// ```swift
// PostgreSQL.String.upper($0.name)
// PostgreSQL.String.substring($0.email, from: 1, for: 5)
// ```
//
// **Method style (fluent):**
// ```swift
// $0.name.uppercased()
// $0.email.substring(from: 1, for: 5)
// ```
//
// Both compile to identical SQL. Choose based on context and readability.

extension PostgreSQL {
    /// Namespace for PostgreSQL string functions
    ///
    /// This enum cannot be instantiated - it serves purely as a namespace.
    public enum String {}
}
