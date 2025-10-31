import Foundation
import StructuredQueriesCore

// MARK: - JSONB.Operators (Table 9.47)

extension JSONB {
  /// Basic JSON/JSONB operators from PostgreSQL Table 9.47
  ///
  /// These operators provide fundamental path extraction capabilities for JSON/JSONB columns:
  /// - `->` operator: Extract object field or array element (returns JSON)
  /// - `->>` operator: Extract as text
  /// - `#>` operator: Extract at path (returns JSON)
  /// - `#>>` operator: Extract at path as text
  ///
  /// See [PostgreSQL Documentation - Table 9.47](https://www.postgresql.org/docs/current/functions-json.html)
  public enum Operators {}
}

// MARK: - Path Extraction Operators

extension JSONB.Operators {
  /// PostgreSQL -> operator - extract JSON element (returns JSON)
  ///
  /// **PostgreSQL Documentation**: Table 9.47
  ///
  /// Example:
  /// ```swift
  /// User.select { $0.settings.field("theme") }
  /// // SELECT settings -> 'theme' FROM users
  /// ```
  public struct Field<LHS: QueryExpression>: QueryExpression {
    public typealias QueryValue = Data

    let jsonb: LHS
    let key: String

    public var queryFragment: QueryFragment {
      "(\(jsonb.queryFragment) -> \(bind: key))"
    }
  }

  /// PostgreSQL ->> operator - extract JSON element as text
  ///
  /// **PostgreSQL Documentation**: Table 9.47
  ///
  /// Example:
  /// ```swift
  /// User.select { $0.settings.fieldAsText("theme") }
  /// // SELECT settings ->> 'theme' FROM users
  /// ```
  public struct FieldText<LHS: QueryExpression>: QueryExpression {
    public typealias QueryValue = String?

    let jsonb: LHS
    let key: String

    public var queryFragment: QueryFragment {
      "(\(jsonb.queryFragment) ->> \(bind: key))"
    }
  }

  /// PostgreSQL -> operator with integer - extract array element (returns JSON)
  ///
  /// **PostgreSQL Documentation**: Table 9.47
  ///
  /// Example:
  /// ```swift
  /// User.select { $0.tags.element(at: 0) }
  /// // SELECT tags -> 0 FROM users
  /// ```
  public struct Index<LHS: QueryExpression>: QueryExpression {
    public typealias QueryValue = Data

    let jsonb: LHS
    let index: Int

    public var queryFragment: QueryFragment {
      "(\(jsonb.queryFragment) -> \(index))"
    }
  }

  /// PostgreSQL ->> operator with integer - extract array element as text
  ///
  /// **PostgreSQL Documentation**: Table 9.47
  ///
  /// Example:
  /// ```swift
  /// User.select { $0.tags.elementAsText(at: 0) }
  /// // SELECT tags ->> 0 FROM users
  /// ```
  public struct IndexText<LHS: QueryExpression>: QueryExpression {
    public typealias QueryValue = String?

    let jsonb: LHS
    let index: Int

    public var queryFragment: QueryFragment {
      "(\(jsonb.queryFragment) ->> \(index))"
    }
  }

  /// PostgreSQL #> operator - extract at path (returns JSON)
  ///
  /// **PostgreSQL Documentation**: Table 9.47
  ///
  /// Example:
  /// ```swift
  /// User.select { $0.profile.value(at: ["address", "city"]) }
  /// // SELECT profile #> '{address,city}' FROM users
  /// ```
  public struct Path<LHS: QueryExpression>: QueryExpression {
    public typealias QueryValue = Data

    let jsonb: LHS
    let path: [String]

    public var queryFragment: QueryFragment {
      let pathArray = "'{" + path.joined(separator: ",") + "}'"
      return "(\(jsonb.queryFragment) #> \(raw: pathArray))"
    }
  }

  /// PostgreSQL #>> operator - extract at path as text
  ///
  /// **PostgreSQL Documentation**: Table 9.47
  ///
  /// Example:
  /// ```swift
  /// User.select { $0.profile.valueAsText(at: ["address", "city"]) }
  /// // SELECT profile #>> '{address,city}' FROM users
  /// ```
  public struct PathText<LHS: QueryExpression>: QueryExpression {
    public typealias QueryValue = String?

    let jsonb: LHS
    let path: [String]

    public var queryFragment: QueryFragment {
      let pathArray = "'{" + path.joined(separator: ",") + "}'"
      return "(\(jsonb.queryFragment) #>> \(raw: pathArray))"
    }
  }
}

// MARK: - Operator Chaining Support

extension JSONB.Operators.Field {
  public func field(_ key: String) -> JSONB.Operators.Field<Self> {
    JSONB.Operators.Field<Self>(jsonb: self, key: key)
  }

  public func fieldAsText(_ key: String) -> JSONB.Operators.FieldText<Self> {
    JSONB.Operators.FieldText<Self>(jsonb: self, key: key)
  }
}

extension JSONB.Operators.Path {
  public func field(_ key: String) -> JSONB.Operators.Field<Self> {
    JSONB.Operators.Field<Self>(jsonb: self, key: key)
  }

  public func fieldAsText(_ key: String) -> JSONB.Operators.FieldText<Self> {
    JSONB.Operators.FieldText<Self>(jsonb: self, key: key)
  }
}
