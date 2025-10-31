import Foundation
import StructuredQueriesCore

// MARK: - PostgreSQL JSON Conversion Utilities
//
// This file contains JSON-related utility functions for PostgreSQL.
// These functions handle conversion between Swift types and PostgreSQL's JSON/JSONB representations.

extension QueryExpression where QueryValue == Bool {
  /// Converts boolean to PostgreSQL JSON boolean representation
  ///
  /// Converts a boolean expression to a string `'true'` or `'false'` for JSON compatibility.
  ///
  /// ```swift
  /// User.select { $0.isActive.toJSONBoolean() }
  /// // SELECT CASE WHEN "users"."isActive" THEN 'true' ELSE 'false' END FROM "users"
  /// ```
  public func toJSONBoolean() -> some QueryExpression<String> {
    SQLQueryExpression(
      "CASE WHEN \(self.queryFragment) THEN 'true' ELSE 'false' END", as: String.self)
  }
}

extension QueryExpression where QueryValue == String {
  /// PostgreSQL's `to_json` function for proper JSON escaping
  ///
  /// Converts a string value to a JSON-encoded value, properly escaping special characters.
  ///
  /// ```swift
  /// User.select { $0.description.jsonQuote() }
  /// // SELECT to_json("users"."description") FROM "users"
  /// ```
  public func jsonQuote() -> some QueryExpression<Data> {
    SQLQueryExpression("to_json(\(self.queryFragment))", as: Data.self)
  }
}

extension QueryExpression where QueryValue == String? {
  /// PostgreSQL's `to_json` function for proper JSON escaping (nullable)
  ///
  /// Converts a nullable string value to a JSON-encoded value.
  ///
  /// ```swift
  /// User.select { $0.bio.jsonQuote() }
  /// // SELECT to_json("users"."bio") FROM "users"
  /// ```
  public func jsonQuote() -> some QueryExpression<Data?> {
    SQLQueryExpression("to_json(\(self.queryFragment))", as: Data?.self)
  }
}

extension QueryExpression {
  /// Generic JSON quote for any expression type
  ///
  /// Converts any expression to a JSON-encoded value.
  ///
  /// ```swift
  /// User.select { $0.metadata.jsonQuote() }
  /// // SELECT to_json("users"."metadata") FROM "users"
  /// ```
  public func jsonQuote() -> some QueryExpression<Data> {
    SQLQueryExpression("to_json(\(self.queryFragment))", as: Data.self)
  }
}
