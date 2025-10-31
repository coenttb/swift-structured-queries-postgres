import Foundation
import StructuredQueriesCore

// MARK: - JSONB Namespace

/// Namespace for PostgreSQL JSONB operations
///
/// Provides a clean, organized API for PostgreSQL's JSONB functionality through nested types.
///
/// **Nested Types:**
/// - `JSONB.Conversion` - Conversion functions (to_jsonb, jsonb_build_array, etc.)
/// - `JSONB.Operators` - JSONB operators (@>, <@, ->, etc.)
/// - `JSONB.Functions` - JSONB functions (jsonb_set, jsonb_insert, etc.)
/// - `JSONB.Index` - Index creation utilities (GIN, B-tree)
///
/// ```swift
/// User.select { columns in
///     JSONB.Conversion.arrayToJson(columns.tags)
/// }
/// ```
public enum JSONB {}

// MARK: - Shared JSON Encoder

/// Shared JSON encoder for JSONB operations
internal let jsonbEncoder: JSONEncoder = {
  var encoder = JSONEncoder()
  encoder.dateEncodingStrategy = .iso8601
  #if DEBUG
    encoder.outputFormatting = [.sortedKeys]
  #endif
  return encoder
}()
