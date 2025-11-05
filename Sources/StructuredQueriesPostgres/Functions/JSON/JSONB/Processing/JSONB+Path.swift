import Foundation
import StructuredQueriesCore

// MARK: - JSONB.Processing.Path (Table 9.51)

extension JSONB.Processing {
    /// JSON Path Query Functions from PostgreSQL Table 9.51
    ///
    /// Advanced path-based operations for querying JSON structures:
    /// - Path extraction functions
    /// - Path existence checking
    /// - Path query execution
    ///
    /// **Note**: Some functions require PostgreSQL 12+
    ///
    /// See [PostgreSQL Documentation - Table 9.51](https://www.postgresql.org/docs/current/functions-json.html)
    public enum Path {}
}

extension JSONB.Processing.Path {
    /// PostgreSQL json_extract_path function - extracts JSON value at specified path
    ///
    /// **PostgreSQL Documentation**: Table 9.51
    ///
    /// Extracts JSON sub-object at the specified path (equivalent to `#>` operator).
    ///
    /// Example:
    /// ```swift
    /// // SELECT json_extract_path('{"a":{"b":"foo"}}'::json, 'a', 'b')
    /// // Returns: "foo"
    /// ```
    ///
    /// **Use cases:**
    /// - Dynamic path-based extraction
    /// - Nested value access
    /// - Programmatic JSON navigation
    public struct ExtractPath<LHS: QueryExpression>: QueryExpression {
        public typealias QueryValue = Data

        let jsonb: LHS
        let path: [String]
        let format: Format

        enum Format {
            case json
            case jsonb

            var functionName: String {
                switch self {
                case .json: return "json_extract_path"
                case .jsonb: return "jsonb_extract_path"
                }
            }
        }

        public var queryFragment: QueryFragment {
            var fragment: QueryFragment = "\(raw: format.functionName)(\(jsonb.queryFragment)"
            for pathElement in path {
                fragment.append(", \(bind: pathElement)")
            }
            fragment.append(")")
            return fragment
        }
    }

    /// PostgreSQL json_extract_path_text function - extracts JSON value at path as text
    ///
    /// **PostgreSQL Documentation**: Table 9.51
    ///
    /// Example:
    /// ```swift
    /// // SELECT json_extract_path_text('{"a":{"b":"foo"}}'::json, 'a', 'b')
    /// // Returns: "foo" (as text)
    /// ```
    public struct ExtractPathText<LHS: QueryExpression>: QueryExpression {
        public typealias QueryValue = String?

        let jsonb: LHS
        let path: [String]
        let format: Format

        enum Format {
            case json
            case jsonb

            var functionName: String {
                switch self {
                case .json: return "json_extract_path_text"
                case .jsonb: return "jsonb_extract_path_text"
                }
            }
        }

        public var queryFragment: QueryFragment {
            var fragment: QueryFragment = "\(raw: format.functionName)(\(jsonb.queryFragment)"
            for pathElement in path {
                fragment.append(", \(bind: pathElement)")
            }
            fragment.append(")")
            return fragment
        }
    }

    /// PostgreSQL jsonb_path_exists function - checks if JSON path returns any item
    ///
    /// **PostgreSQL Documentation**: Table 9.51
    /// **Requires**: PostgreSQL 12+
    ///
    /// Tests whether a JSON path expression matches any elements.
    ///
    /// Example:
    /// ```swift
    /// // SELECT jsonb_path_exists('{"a":[1,2,3]}'::jsonb, '$.a[*] ? (@ > 2)')
    /// // Returns: true
    /// ```
    public struct PathExists<LHS: QueryExpression>: QueryExpression {
        public typealias QueryValue = Bool

        let jsonb: LHS
        let path: String

        public var queryFragment: QueryFragment {
            "jsonb_path_exists(\(jsonb.queryFragment), \(bind: path))"
        }
    }

    /// PostgreSQL jsonb_path_query function - executes JSON path query
    ///
    /// **PostgreSQL Documentation**: Table 9.51
    /// **Requires**: PostgreSQL 12+
    ///
    /// Returns all JSON items returned by the JSON path for the specified JSON value.
    ///
    /// Example:
    /// ```swift
    /// // SELECT jsonb_path_query('{"a":[1,2,3]}'::jsonb, '$.a[*]')
    /// // Returns 3 rows: 1, 2, 3
    /// ```
    public struct PathQuery<LHS: QueryExpression>: QueryExpression {
        public typealias QueryValue = Data

        let jsonb: LHS
        let path: String

        public var queryFragment: QueryFragment {
            "jsonb_path_query(\(jsonb.queryFragment), \(bind: path))"
        }
    }
}
