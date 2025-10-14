import Foundation
import StructuredQueriesCore

// MARK: - TextSearch Namespace

/// Namespace for PostgreSQL full-text search types and utilities.
public enum TextSearch {}

extension TextSearch {
    /// Represents a PostgreSQL `tsvector` value.
    ///
    /// A `tsvector` is a sorted list of distinct lexemes, which are words that have been
    /// normalized to merge different variants of the same word. PostgreSQL uses tsvector
    /// for full-text search operations.
    ///
    /// In Swift, we represent this as an opaque type that can be stored and retrieved,
    /// but the actual text search processing happens in PostgreSQL.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// @Table
    /// struct Article: FullTextSearchable {
    ///     let id: Int
    ///     var title: String
    ///     var body: String
    ///     var searchVector: TextSearch.Vector
    /// }
    /// ```
    public struct Vector: Sendable, Hashable, Codable {
        /// The underlying string representation of the tsvector
        public let value: String

        /// Creates a new Vector with the given value
        public init(value: String) {
            self.value = value
        }
    }
}

// MARK: - Vector QueryBindable

extension TextSearch.Vector: QueryBindable {
    public var queryBinding: QueryBinding {
        // tsvector is stored as text in PostgreSQL
        .text(value)
    }
}

// MARK: - Vector QueryDecodable

extension TextSearch.Vector: QueryDecodable {
    @inlinable
    public init(decoder: inout some QueryDecoder) throws {
        guard let result = try decoder.decode(String.self)
        else { throw QueryDecodingError.missingRequiredColumn }
        self.init(value: result)
    }
}

// MARK: - Vector CustomStringConvertible

extension TextSearch.Vector: CustomStringConvertible {
    public var description: String {
        value
    }
}

// MARK: - Vector ExpressibleByStringLiteral

extension TextSearch.Vector: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value: value)
    }
}

// MARK: - Backward Compatibility

/// Typealias for backward compatibility. Use `TextSearch.Vector` instead.
@available(*, deprecated, renamed: "TextSearch.Vector")
public typealias TSVector = TextSearch.Vector

extension TextSearch {
    /// Weight labels for tsvector positions.
    ///
    /// Used to assign importance to different parts of a document during full-text search.
    /// Higher weights (A) receive more importance in ranking calculations.
    ///
    /// ## Weight Meanings
    ///
    /// - `.A` - Highest importance (typically titles, headings)
    /// - `.B` - High importance (typically subtitles, emphasized text)
    /// - `.C` - Medium importance (typically abstracts, summaries)
    /// - `.D` - Lowest importance (typically body text, default)
    public enum Weight: String, Sendable {
        case A  // Highest importance
        case B  // High importance
        case C  // Medium importance
        case D  // Lowest importance (default)
    }
}

extension TextSearch {
    /// A valid word range for `ts_headline()` where minimum is less than maximum.
    ///
    /// This type ensures that `minWords < maxWords` at compile time, preventing
    /// PostgreSQL errors when generating headlines.
    ///
    /// ```swift
    /// // Valid ranges
    /// let range = TextSearch.WordRange(min: 3, max: 10)  // OK
    ///
    /// // Invalid ranges return nil
    /// TextSearch.WordRange(min: 10, max: 3)  // nil
    /// TextSearch.WordRange(min: 5, max: 5)   // nil (must be strictly less than)
    /// ```
    public struct WordRange: Sendable, Equatable {
        public let min: Int
        public let max: Int

        /// Creates a word range if valid (min < max).
        ///
        /// - Parameters:
        ///   - min: Minimum number of words (must be positive and less than max)
        ///   - max: Maximum number of words (must be greater than min)
        /// - Returns: A valid word range, or nil if constraints aren't met
        public init?(min: Int, max: Int) {
            guard min > 0, max > 0, min < max else { return nil }
            self.min = min
            self.max = max
        }

        /// Creates a word range with only a maximum, using PostgreSQL's default minimum (15).
        ///
        /// **Note**: This will fail if `max` is less than or equal to 15.
        ///
        /// - Parameter max: Maximum number of words (must be > 15)
        /// - Returns: A valid word range, or nil if max <= 15
        public static func upTo(_ max: Int) -> WordRange? {
            WordRange(min: 15, max: max)
        }

        /// Common word range presets
        // swiftlint:disable:next force_unwrapping
        public static let short = WordRange(min: 3, max: 10)!  // Concise snippets
        // swiftlint:disable:next force_unwrapping
        public static let medium = WordRange(min: 10, max: 25)!  // Balanced excerpts
        // swiftlint:disable:next force_unwrapping
        public static let long = WordRange(min: 20, max: 50)!  // Detailed excerpts
    }

    /// Normalization options for `ts_rank()` and `ts_rank_cd()`.
    ///
    /// These options control how document length and structure affect ranking scores.
    /// Values can be combined using `OptionSet` semantics.
    ///
    /// ## Common Combinations
    ///
    /// ```swift
    /// // Length normalization
    /// .divideByLogLength
    ///
    /// // Length + unique word normalization
    /// [.divideByLogLength, .divideByUniqueWordCount]
    /// ```
    public struct RankNormalization: OptionSet, Sendable, ExpressibleByIntegerLiteral {

        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public init(integerLiteral value: Int) {
            self.rawValue = value
        }
    }
}

extension TextSearch.RankNormalization {

    /// No normalization (default)
    public static let none = TextSearch.RankNormalization([])

    /// Divide rank by (1 + log of document length)
    ///
    /// Recommended for most use cases - reduces but doesn't eliminate length bias.
    public static let divideByLogLength = TextSearch.RankNormalization(rawValue: 1)

    /// Divide rank by document length
    ///
    /// Heavily penalizes long documents.
    public static let divideByLength = TextSearch.RankNormalization(rawValue: 2)

    /// Divide rank by mean harmonic distance between extents
    ///
    /// Considers how close query terms appear to each other.
    public static let divideByMeanHarmonicDistance = TextSearch.RankNormalization(rawValue: 4)

    /// Divide rank by number of unique words in document
    public static let divideByUniqueWordCount = TextSearch.RankNormalization(rawValue: 8)

    /// Divide rank by (1 + log of unique words)
    public static let divideByLogUniqueWords = TextSearch.RankNormalization(rawValue: 16)

    /// Divide rank by (rank + 1)
    ///
    /// Normalizes scores to 0-1 range.
    public static let divideByRankPlusOne = TextSearch.RankNormalization(rawValue: 32)
}

// MARK: - Full-Text Search Protocol

/// A table with full-text search capabilities using PostgreSQL's tsvector type.
///
/// Apply this protocol to a `@Table` declaration to introduce PostgreSQL full-text search helpers.
///
/// ## Overview
///
/// PostgreSQL provides powerful full-text search capabilities via `tsvector` and `tsquery` types.
/// This protocol enables type-safe query building for full-text search operations.
///
/// ## Why searchVectorColumn is Required
///
/// PostgreSQL uses dedicated `tsvector` columns within regular tables. A table can have multiple
/// tsvector columns for different search purposes (unlike virtual table approaches).
///
/// This protocol requirement tells the query builder which column contains the search vector,
/// enabling type-safe query generation:
///
/// ```swift
/// Article.where { $0.match("swift") }
/// // Generates: WHERE "articles"."searchVector" @@ to_tsquery('swift')
/// ```
///
/// ## Default Implementation
///
/// The protocol provides a default of `"searchVector"` following PostgreSQL conventions.
/// Most tables work without any override:
///
/// ```swift
/// @Table
/// struct Article: FullTextSearchable {
///   let id: Int
///   var title: String
///   var body: String
///   var searchVector: TextSearch.Vector  // Uses default "searchVector"
///   // No override needed!
/// }
/// ```
///
/// Only customize when your schema differs:
///
/// ```swift
/// @Table
/// struct Article: FullTextSearchable {
///   let id: Int
///   var title: String
///   var body: String
///   var searchVector: TextSearch.Vector  // camelCase preference
///
///   static var searchVectorColumn: String { "searchVector" }
/// }
/// ```
///
/// ## Example Usage
///
/// ```swift
/// // Basic search
/// Article.where { $0.match("swift & postgresql") }
///
/// // Search with ranking
/// Article.where { $0.match("swift") }
///   .order { $0.rank("swift") }
///
/// // Search with highlighting
/// Article.where { $0.match("swift") }
///   .select {
///     ($0, $0.body.headline(matching: "swift", startDelimiter: "<mark>", stopDelimiter: "</mark>"))
///   }
/// ```
///
/// ## PostgreSQL Documentation
///
/// - [Full Text Search](https://www.postgresql.org/docs/current/textsearch.html)
/// - [Text Search Types](https://www.postgresql.org/docs/current/datatype-textsearch.html)
/// - [Text Search Functions](https://www.postgresql.org/docs/current/functions-textsearch.html)
public protocol FullTextSearchable: Table {
    /// The name of the tsvector column used for full-text search.
    ///
    /// Default implementation returns `"searchVector"` following PostgreSQL conventions.
    /// Override this when your schema uses a different column name.
    ///
    /// ## Why This is Required
    ///
    /// PostgreSQL stores search vectors as columns in regular tables. A table can have multiple
    /// tsvector columns, so the protocol must know which column to target when generating queries.
    ///
    /// ## Example
    ///
    /// ```swift
    /// @Table
    /// struct Product: FullTextSearchable {
    ///     let id: Int
    ///     var searchVector: TextSearch.Vector
    ///
    ///     static var searchVectorColumn: String { "searchVector" }
    /// }
    /// ```
    ///
    static var searchVectorColumn: String { get }
}

extension FullTextSearchable {
    /// Default tsvector column name.
    public static var searchVectorColumn: String { "searchVector" }
}

// MARK: - Convenience Extensions

extension Optional: FullTextSearchable where Wrapped: FullTextSearchable {
    public static var searchVectorColumn: String { Wrapped.searchVectorColumn }
}

extension TableAlias: FullTextSearchable where Base: FullTextSearchable {
    public static var searchVectorColumn: String { Base.searchVectorColumn }
}
