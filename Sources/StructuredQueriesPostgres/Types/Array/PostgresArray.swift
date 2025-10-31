import Foundation
import StructuredQueriesCore

// MARK: - Native PostgreSQL Array Support

/// Makes Swift arrays work as native PostgreSQL arrays in queries.
///
/// This enables natural syntax like `[String].self` for native array columns,
/// while keeping `[String].JSONB.self` for JSONB storage.
///
/// ```swift
/// @Table
/// struct Post {
///     let id: Int
///
///     // Native PostgreSQL array (text[])
///     @Column(as: [String].self)
///     var tags: [String]
///
///     // JSONB array (for complex types)
///     @Column(as: [Comment].JSONB.self)
///     var comments: [Comment]
/// }
///
/// // Use array operators
/// Post.where { $0.tags.contains(["swift"]) }
/// // SQL: WHERE tags @> ARRAY['swift']
/// ```
///
/// ## Native Arrays vs JSONB Arrays
///
/// **Use Native Arrays (`[T].self`) when**:
/// - Storing primitive types (String, Int, UUID, etc.)
/// - Need array-specific operators (`@>`, `<@`, `&&`)
/// - Performance matters
/// - Want proper PostgreSQL array indexes (GIN/GiST)
///
/// **Use JSONB Arrays (`[T].JSONB.self`) when**:
/// - Storing complex Codable types
/// - Need JSON path queries
/// - Schema flexibility is important
///
/// ## Supported Element Types
///
/// - `Bool` → `boolean[]`
/// - `String` → `text[]`
/// - `Int` → `bigint[]` (64-bit) or `integer[]` (32-bit)
/// - `Int16` → `smallint[]`
/// - `Int32` → `integer[]`
/// - `Int64` → `bigint[]`
/// - `Float` → `real[]`
/// - `Double` → `double precision[]`
/// - `UUID` → `uuid[]`
/// - `Date` → `timestamptz[]`

// MARK: - Array QueryBindable Conformance

// Note: [UInt8] has special conformance in StructuredQueriesCore for bytea (blob) support.
// Due to Swift's conformance rules, that more-specific conformance takes precedence.
// This extension provides native array support for all other QueryBindable element types.
extension Array: QueryBindable, QueryExpression where Element: QueryBindable {
  public typealias QueryValue = [Element]

  public var queryBinding: QueryBinding {
    // Special case: [UInt8] is handled by the more-specific conformance in Core
    // for bytea (binary data) support
    if Element.self == UInt8.self {
      return .blob(self as! [UInt8])
    }

    // Map primitive types to their specific PostgreSQL array binding cases
    // These are optimized for the most common types
    switch Element.self {
    case is Bool.Type:
      return .boolArray(self as! [Bool])
    case is String.Type:
      return .stringArray(self as! [String])
    case is Int.Type:
      return .intArray(self as! [Int])
    case is Int16.Type:
      return .int16Array(self as! [Int16])
    case is Int32.Type:
      return .int32Array(self as! [Int32])
    case is Int64.Type:
      return .int64Array(self as! [Int64])
    case is Float.Type:
      return .floatArray(self as! [Float])
    case is Double.Type:
      return .doubleArray(self as! [Double])
    case is UUID.Type:
      return .uuidArray(self as! [UUID])
    case is Date.Type:
      return .dateArray(self as! [Date])
    default:
      // Fallback: Use genericArray for any other QueryBindable element type
      // This supports custom types like enums with RawRepresentable conformance
      return .genericArray(self.map { $0.queryBinding })
    }
  }
}

// MARK: - Array _OptionalPromotable Conformance

extension Array: _OptionalPromotable where Element: QueryDecodable {}

// MARK: - Array QueryDecodable Conformance

extension Array: QueryDecodable where Element: QueryDecodable {
  public init(decoder: inout some QueryDecoder) throws {
    // Special case: [UInt8] is for bytea (binary data)
    if Element.self == UInt8.self {
      guard let result = try decoder.decode([UInt8].self)
      else { throw QueryDecodingError.missingRequiredColumn }
      self = result as! [Element]
      return
    }

    // Other array types: Decoding is handled by swift-records package
    // via postgres-nio integration. This package only handles SQL generation.
    throw ArrayDecodingNotImplementedError()
  }
}

private struct ArrayDecodingNotImplementedError: Swift.Error {}

// MARK: - Array QueryRepresentable Conformance

extension Array: QueryRepresentable where Element: QueryDecodable {
  public init(queryOutput: [Element]) {
    self = queryOutput
  }

  public var queryOutput: [Element] {
    self
  }
}

// MARK: - Documentation

/// Native PostgreSQL array storage is now the default for arrays.
///
/// Simply use `[T].self` in `@Column(as:)` annotations:
///
/// ```swift
/// @Table
/// struct Article {
///     @Column(as: [String].self)
///     var tags: [String]  // text[]
///
///     @Column(as: [Int].self)
///     var scores: [Int]  // bigint[]
/// }
/// ```
///
/// Array operators work automatically:
///
/// ```swift
/// Article.where { $0.tags.contains(["swift", "postgres"]) }
/// // WHERE tags @> ARRAY['swift', 'postgres']
///
/// Article.where { $0.tags.overlaps(["rust", "go"]) }
/// // WHERE tags && ARRAY['rust', 'go']
/// ```
///
/// For JSONB storage of complex types, use `.JSONB`:
///
/// ```swift
/// @Table
/// struct Post {
///     @Column(as: [Comment].JSONB.self)
///     var comments: [Comment]  // Stored as JSONB
/// }
/// ```
public enum PostgresArrayDocumentation {}
