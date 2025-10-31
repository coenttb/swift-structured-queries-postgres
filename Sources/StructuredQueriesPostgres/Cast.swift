import Foundation
import StructuredQueriesCore

// MARK: - Cast extensions for QueryExpression

extension QueryExpression where QueryValue: QueryBindable {
  /// Cast this expression to another type
  public func cast<Other: PostgreSQLType>(
    as _: Other.Type = Other.self
  ) -> some QueryExpression<Other> {
    Cast(base: self)
  }
}

extension QueryExpression where QueryValue: QueryBindable & _OptionalProtocol {
  /// Cast optional expression to another optional type
  public func cast<Other: _OptionalPromotable & PostgreSQLType>(
    as _: Other.Type = Other.self
  ) -> some QueryExpression<Other._Optionalized>
  where Other._Optionalized: PostgreSQLType {
    Cast(base: self)
  }
}

// MARK: - Type-inferred cast

extension QueryExpression where QueryValue == Int {
  /// Cast to Double with inferred type
  public func cast() -> some QueryExpression<Double> {
    cast(as: Double.self)
  }
}

extension QueryExpression where QueryValue == Int? {
  /// Cast to Double? with inferred type
  public func cast() -> some QueryExpression<Double?> {
    cast(as: Double.self)
  }
}

// MARK: - PostgreSQL Type Protocol

/// Protocol for types that can be used in CAST expressions
public protocol PostgreSQLType: QueryBindable {
  static var typeName: String { get }
}

// MARK: - Integer Types

extension PostgreSQLType where Self: BinaryInteger {
  public static var typeName: String { "INTEGER" }
}

extension Int: PostgreSQLType {}
extension Int8: PostgreSQLType {
  public static var typeName: String { "SMALLINT" }
}
extension Int16: PostgreSQLType {
  public static var typeName: String { "SMALLINT" }
}
extension Int32: PostgreSQLType {
  public static var typeName: String { "INTEGER" }
}
extension Int64: PostgreSQLType {
  public static var typeName: String { "BIGINT" }
}

extension UInt8: PostgreSQLType {
  public static var typeName: String { "SMALLINT" }
}
extension UInt16: PostgreSQLType {
  public static var typeName: String { "INTEGER" }
}
extension UInt32: PostgreSQLType {
  public static var typeName: String { "BIGINT" }
}

// MARK: - Floating Point Types

extension PostgreSQLType where Self: FloatingPoint {
  public static var typeName: String { "REAL" }
}

extension Double: PostgreSQLType {
  public static var typeName: String { "DOUBLE PRECISION" }
}
extension Float: PostgreSQLType {}

// MARK: - Other Types

extension Bool: PostgreSQLType {
  public static var typeName: String { "BOOLEAN" }
}

extension String: PostgreSQLType {
  public static var typeName: String { "TEXT" }
}

extension [UInt8]: PostgreSQLType {
  public static var typeName: String { "BYTEA" }
}

extension Date: PostgreSQLType {
  public static var typeName: String { "TIMESTAMP" }
}

extension UUID: PostgreSQLType {
  public static var typeName: String { "UUID" }
}

// MARK: - Optional Types

extension Optional: PostgreSQLType where Wrapped: PostgreSQLType {
  public static var typeName: String { Wrapped.typeName }
}

// MARK: - RawRepresentable Types

extension RawRepresentable where RawValue: PostgreSQLType {
  public static var typeName: String { RawValue.typeName }
}

// MARK: - Cast Expression

private struct Cast<QueryValue: PostgreSQLType, Base: QueryExpression>: QueryExpression {
  let base: Base
  var queryFragment: QueryFragment {
    "CAST(\(base.queryFragment) AS \(raw: QueryValue.typeName))"
  }
}
