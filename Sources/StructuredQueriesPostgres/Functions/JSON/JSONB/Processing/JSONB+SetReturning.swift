import Foundation
import StructuredQueriesCore

// MARK: - JSONB.Processing.SetReturning (Table 9.51)

extension JSONB.Processing {
  /// Set-Returning Functions from PostgreSQL Table 9.51
  ///
  /// These functions expand JSON/JSONB values into multiple rows, useful for:
  /// - Unnesting arrays into individual elements
  /// - Expanding objects into key/value pairs
  /// - Extracting object keys
  ///
  /// **Note**: These functions return sets of values (multiple rows), not single values.
  ///
  /// See [PostgreSQL Documentation - Table 9.51](https://www.postgresql.org/docs/current/functions-json.html)
  public enum SetReturning {}
}

extension JSONB.Processing.SetReturning {
  /// PostgreSQL json_array_elements function - expands JSON array to set of JSON values
  ///
  /// **PostgreSQL Documentation**: Table 9.51
  ///
  /// Expands the top-level JSON array into a set of JSON values, one per array element.
  ///
  /// Example:
  /// ```swift
  /// // SELECT json_array_elements('[1,2,3]'::json)
  /// // Returns 3 rows: 1, 2, 3
  /// ```
  ///
  /// **Use cases:**
  /// - Unnesting JSON arrays into rows
  /// - Processing array elements individually
  /// - JOIN operations with array elements
  public struct ArrayElements<LHS: QueryExpression>: QueryExpression {
    public typealias QueryValue = Data

    let jsonb: LHS
    let format: Format

    enum Format {
      case json
      case jsonb

      var functionName: String {
        switch self {
        case .json: return "json_array_elements"
        case .jsonb: return "jsonb_array_elements"
        }
      }
    }

    public var queryFragment: QueryFragment {
      "\(raw: format.functionName)(\(jsonb.queryFragment))"
    }
  }

  /// PostgreSQL json_array_elements_text function - expands JSON array to set of text values
  ///
  /// **PostgreSQL Documentation**: Table 9.51
  ///
  /// Example:
  /// ```swift
  /// // SELECT json_array_elements_text('["a","b","c"]'::json)
  /// // Returns 3 rows: "a", "b", "c"
  /// ```
  public struct ArrayElementsText<LHS: QueryExpression>: QueryExpression {
    public typealias QueryValue = String

    let jsonb: LHS
    let format: Format

    enum Format {
      case json
      case jsonb

      var functionName: String {
        switch self {
        case .json: return "json_array_elements_text"
        case .jsonb: return "jsonb_array_elements_text"
        }
      }
    }

    public var queryFragment: QueryFragment {
      "\(raw: format.functionName)(\(jsonb.queryFragment))"
    }
  }

  /// PostgreSQL json_each function - expands JSON object to set of key/value pairs
  ///
  /// **PostgreSQL Documentation**: Table 9.51
  ///
  /// Expands the top-level JSON object into a set of key/value pairs.
  ///
  /// Example:
  /// ```swift
  /// // SELECT * FROM json_each('{"a":1,"b":2}'::json)
  /// // Returns 2 rows: (key: "a", value: 1), (key: "b", value: 2)
  /// ```
  ///
  /// **Use cases:**
  /// - Iterating over object properties
  /// - Converting objects to relational rows
  /// - Dynamic column access
  public struct Each<LHS: QueryExpression>: QueryExpression {
    public typealias QueryValue = (String, Data)

    let jsonb: LHS
    let format: Format

    enum Format {
      case json
      case jsonb

      var functionName: String {
        switch self {
        case .json: return "json_each"
        case .jsonb: return "jsonb_each"
        }
      }
    }

    public var queryFragment: QueryFragment {
      "\(raw: format.functionName)(\(jsonb.queryFragment))"
    }
  }

  /// PostgreSQL json_each_text function - expands JSON object to set of key/text pairs
  ///
  /// **PostgreSQL Documentation**: Table 9.51
  ///
  /// Example:
  /// ```swift
  /// // SELECT * FROM json_each_text('{"a":"foo","b":"bar"}'::json)
  /// // Returns 2 rows: (key: "a", value: "foo"), (key: "b", value: "bar")
  /// ```
  public struct EachText<LHS: QueryExpression>: QueryExpression {
    public typealias QueryValue = (String, String)

    let jsonb: LHS
    let format: Format

    enum Format {
      case json
      case jsonb

      var functionName: String {
        switch self {
        case .json: return "json_each_text"
        case .jsonb: return "jsonb_each_text"
        }
      }
    }

    public var queryFragment: QueryFragment {
      "\(raw: format.functionName)(\(jsonb.queryFragment))"
    }
  }

  /// PostgreSQL json_object_keys function - returns set of keys in top-level JSON object
  ///
  /// **PostgreSQL Documentation**: Table 9.51
  ///
  /// Returns the set of keys in the top-level JSON object.
  ///
  /// Example:
  /// ```swift
  /// // SELECT json_object_keys('{"a":1,"b":2,"c":3}'::json)
  /// // Returns 3 rows: "a", "b", "c"
  /// ```
  ///
  /// **Use cases:**
  /// - Discovering object structure
  /// - Dynamic schema analysis
  /// - Validation of expected keys
  public struct ObjectKeys<LHS: QueryExpression>: QueryExpression {
    public typealias QueryValue = String

    let jsonb: LHS
    let format: Format

    enum Format {
      case json
      case jsonb

      var functionName: String {
        switch self {
        case .json: return "json_object_keys"
        case .jsonb: return "jsonb_object_keys"
        }
      }
    }

    public var queryFragment: QueryFragment {
      "\(raw: format.functionName)(\(jsonb.queryFragment))"
    }
  }
}
