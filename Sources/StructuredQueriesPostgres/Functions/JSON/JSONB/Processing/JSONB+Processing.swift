import Foundation
import StructuredQueriesCore

// MARK: - JSONB.Processing (Table 9.51)

extension JSONB {
  /// JSON Processing Functions from PostgreSQL Table 9.51
  ///
  /// Contains PostgreSQL JSONB functions organized by category:
  /// - Query functions (jsonb_pretty, jsonb_typeof, jsonb_array_length)
  /// - Manipulation functions (jsonb_set, jsonb_insert, jsonb_strip_nulls)
  /// - Set-returning functions (json_array_elements, json_each, json_object_keys)
  /// - Path functions (jsonb_extract_path, jsonb_path_exists, jsonb_path_query)
  ///
  /// See [PostgreSQL Documentation - Table 9.51](https://www.postgresql.org/docs/current/functions-json.html)
  public enum Processing {}
}

// MARK: - JSONB.Processing.Query

extension JSONB.Processing {
  /// PostgreSQL jsonb_pretty function - formats JSONB for display
  ///
  /// **PostgreSQL Documentation**: Table 9.51
  public struct Pretty<LHS: QueryExpression>: QueryExpression {
    public typealias QueryValue = String

    let jsonb: LHS

    public var queryFragment: QueryFragment {
      "jsonb_pretty(\(jsonb.queryFragment))"
    }
  }

  /// PostgreSQL jsonb_typeof function - returns the type of the JSONB value
  ///
  /// **PostgreSQL Documentation**: Table 9.51
  public struct TypeOf<LHS: QueryExpression>: QueryExpression {
    public typealias QueryValue = String

    let jsonb: LHS

    public var queryFragment: QueryFragment {
      "jsonb_typeof(\(jsonb.queryFragment))"
    }
  }

  /// PostgreSQL jsonb_array_length function - returns the length of a JSONB array
  ///
  /// **PostgreSQL Documentation**: Table 9.51
  public struct ArrayLength<LHS: QueryExpression>: QueryExpression {
    public typealias QueryValue = Int

    let jsonb: LHS

    public var queryFragment: QueryFragment {
      "jsonb_array_length(\(jsonb.queryFragment))"
    }
  }
}
