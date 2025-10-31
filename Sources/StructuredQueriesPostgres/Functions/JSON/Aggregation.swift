import Foundation
import StructuredQueriesCore

// MARK: - PostgreSQL JSON Aggregation Functions

extension QueryExpression {
  /// PostgreSQL's json_agg function - aggregates values into a JSON array
  public func jsonAgg() -> some QueryExpression<Data?> {
    JSONAggregation(expression: self, format: .json)
  }

  /// PostgreSQL's jsonb_agg function - aggregates values into a JSONB array
  public func jsonbAgg() -> some QueryExpression<Data?> {
    JSONAggregation(expression: self, format: .jsonb)
  }

  /// PostgreSQL's array_agg function - aggregates values into a PostgreSQL array
  public func arrayAgg() -> some QueryExpression<String?> {
    ArrayAggregation(expression: self)
  }
}

// MARK: - JSON Group Array (compatibility alias)

extension QueryExpression {
  /// Alias for jsonAgg()
  ///
  /// > Note: SQLite equivalent: `json_group_array()`
  public func jsonGroupArray() -> some QueryExpression<Data?> {
    jsonAgg()
  }
}

// MARK: - JSON Build Object

/// PostgreSQL's json_build_object function
/// Creates a JSON object from a variadic list of key-value pairs
public func jsonBuildObject(_ pairs: (String, any QueryExpression)...) -> some QueryExpression<Data>
{
  JSONBuildObject(pairs: pairs)
}

/// PostgreSQL's jsonb_build_object function
/// Creates a JSONB object from a variadic list of key-value pairs
public func jsonbBuildObject(_ pairs: (String, any QueryExpression)...) -> some QueryExpression<
  Data
> {
  JSONBuildObject(pairs: pairs, format: .jsonb)
}

// MARK: - Implementation Types

private struct JSONAggregation<Expression: QueryExpression>: QueryExpression {
  typealias QueryValue = Data?

  let expression: Expression
  let format: JSONFormat

  enum JSONFormat {
    case json
    case jsonb

    var functionName: String {
      switch self {
      case .json: return "json_agg"
      case .jsonb: return "jsonb_agg"
      }
    }
  }

  var queryFragment: QueryFragment {
    "\(raw: format.functionName)(\(expression.queryFragment))"
  }
}

private struct ArrayAggregation<Expression: QueryExpression>: QueryExpression {
  typealias QueryValue = String?

  let expression: Expression

  var queryFragment: QueryFragment {
    "array_agg(\(expression.queryFragment))"
  }
}

private struct JSONBuildObject: QueryExpression {
  typealias QueryValue = Data

  let pairs: [(String, any QueryExpression)]
  let format: JSONFormat

  enum JSONFormat {
    case json
    case jsonb

    var functionName: String {
      switch self {
      case .json: return "json_build_object"
      case .jsonb: return "jsonb_build_object"
      }
    }
  }

  init(pairs: [(String, any QueryExpression)], format: JSONFormat = .json) {
    self.pairs = pairs
    self.format = format
  }

  var queryFragment: QueryFragment {
    var fragment: QueryFragment = "\(raw: format.functionName)("
    for (index, (key, value)) in pairs.enumerated() {
      if index > 0 {
        fragment.append(", ")
      }
      fragment.append("\(bind: key), \(value.queryFragment)")
    }
    fragment.append(")")
    return fragment
  }
}

// MARK: - JSON Operators

extension QueryExpression where QueryValue == Data {
  /// PostgreSQL's -> operator - extract JSON object field by key
  public func field(_ key: String) -> some QueryExpression<Data> {
    JSONFieldOperator<Self, Data>(json: self, key: key, asText: false)
  }

  /// PostgreSQL's ->> operator - extract JSON object field as text
  public func fieldAsText(_ key: String) -> some QueryExpression<String> {
    JSONFieldOperator<Self, String>(json: self, key: key, asText: true)
  }

  /// PostgreSQL's -> operator - extract JSON array element by index
  public func element(at index: Int) -> some QueryExpression<Data> {
    JSONIndexOperator<Self, Data>(json: self, index: index, asText: false)
  }

  /// PostgreSQL's ->> operator - extract JSON array element as text
  public func elementAsText(at index: Int) -> some QueryExpression<String> {
    JSONIndexOperator<Self, String>(json: self, index: index, asText: true)
  }
}

private struct JSONFieldOperator<JSON: QueryExpression, Output>: QueryExpression
where JSON.QueryValue == Data {
  typealias QueryValue = Output

  let json: JSON
  let key: String
  let asText: Bool

  var queryFragment: QueryFragment {
    let op = asText ? "->>" : "->"
    return "(\(json.queryFragment) \(raw: op) \(bind: key))"
  }
}

private struct JSONIndexOperator<JSON: QueryExpression, Output>: QueryExpression
where JSON.QueryValue == Data {
  typealias QueryValue = Output

  let json: JSON
  let index: Int
  let asText: Bool

  var queryFragment: QueryFragment {
    let op = asText ? "->>" : "->"
    return "(\(json.queryFragment) \(raw: op) \(index))"
  }
}

// MARK: - FILTER clause support

extension QueryExpression {
  /// PostgreSQL's FILTER clause for aggregate functions
  /// Example: json_agg(column) FILTER (WHERE condition)
  public func filter(where condition: some QueryExpression<Bool>) -> some QueryExpression<
    QueryValue
  > {
    FilteredAggregation(aggregate: self, condition: condition)
  }
}

private struct FilteredAggregation<Aggregate: QueryExpression, Condition: QueryExpression>:
  QueryExpression
where Condition.QueryValue == Bool {
  typealias QueryValue = Aggregate.QueryValue

  let aggregate: Aggregate
  let condition: Condition

  var queryFragment: QueryFragment {
    "\(aggregate.queryFragment) FILTER (WHERE \(condition.queryFragment))"
  }
}
