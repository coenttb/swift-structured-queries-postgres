import Foundation
import StructuredQueriesCore

// MARK: - JSONB.AdditionalOperators (Table 9.48)

extension JSONB {
    /// Additional JSONB operators from PostgreSQL Table 9.48
    ///
    /// These operators provide advanced JSONB-specific functionality:
    /// - Containment operators: `@>`, `<@`
    /// - Key existence operators: `?`, `?|`, `?&`
    /// - Concatenation operator: `||`
    /// - Deletion operators: `-`, `#-`
    ///
    /// **Note**: These operators are JSONB-only and not available for json type.
    ///
    /// See [PostgreSQL Documentation - Table 9.48](https://www.postgresql.org/docs/current/functions-json.html)
    public enum AdditionalOperators {}
}

// MARK: - Containment Operators

extension JSONB.AdditionalOperators {
    /// PostgreSQL @> operator - checks if left JSONB contains right
    ///
    /// **PostgreSQL Documentation**: Table 9.48
    ///
    /// Example:
    /// ```swift
    /// User.where { $0.settings.contains(["theme": "dark"]) }
    /// // WHERE settings @> '{"theme": "dark"}'::jsonb
    /// ```
    public struct Contains<LHS: QueryExpression>: QueryExpression {
        public typealias QueryValue = Bool

        let lhs: LHS
        let rhs: Data

        init(lhs: LHS, rhs: some Encodable) {
            self.lhs = lhs
            if let data = try? jsonbEncoder.encode(rhs) {
                self.rhs = data
            } else {
                self.rhs = Data()
            }
        }

        public var queryFragment: QueryFragment {
            let jsonString = String(data: rhs, encoding: .utf8) ?? "{}"
            return "(\(lhs.queryFragment) @> \(bind: jsonString)::jsonb)"
        }
    }

    /// PostgreSQL <@ operator - checks if left JSONB is contained by right
    ///
    /// **PostgreSQL Documentation**: Table 9.48
    ///
    /// Example:
    /// ```swift
    /// User.where { $0.settings.isContained(by: ["theme": "dark", "lang": "en"]) }
    /// // WHERE settings <@ '{"theme": "dark", "lang": "en"}'::jsonb
    /// ```
    public struct ContainedBy<LHS: QueryExpression>: QueryExpression {
        public typealias QueryValue = Bool

        let lhs: LHS
        let rhs: Data

        init(lhs: LHS, rhs: some Encodable) {
            self.lhs = lhs
            if let data = try? jsonbEncoder.encode(rhs) {
                self.rhs = data
            } else {
                self.rhs = Data()
            }
        }

        public var queryFragment: QueryFragment {
            let jsonString = String(data: rhs, encoding: .utf8) ?? "{}"
            return "(\(lhs.queryFragment) <@ \(bind: jsonString)::jsonb)"
        }
    }
}

// MARK: - Key Existence Operators

extension JSONB.AdditionalOperators {
    /// Namespace for key existence operations
    ///
    /// **PostgreSQL Documentation**: Table 9.48
    public enum Keys {
        /// PostgreSQL ? operator - checks if a key exists
        ///
        /// **PostgreSQL Documentation**: Table 9.48
        ///
        /// Example:
        /// ```swift
        /// User.where { $0.settings.hasKey("theme") }
        /// // WHERE settings ? 'theme'
        /// ```
        public struct Exists<LHS: QueryExpression>: QueryExpression {
            public typealias QueryValue = Bool

            let jsonb: LHS
            let key: String

            public var queryFragment: QueryFragment {
                "(\(jsonb.queryFragment) ? \(bind: key))"
            }
        }

        /// PostgreSQL ?| operator - checks if any of the keys exist
        ///
        /// **PostgreSQL Documentation**: Table 9.48
        ///
        /// Example:
        /// ```swift
        /// User.where { $0.settings.hasAny(of: ["theme", "language"]) }
        /// // WHERE settings ?| ARRAY['theme', 'language']
        /// ```
        public struct AnyExist<LHS: QueryExpression>: QueryExpression {
            public typealias QueryValue = Bool

            let jsonb: LHS
            let keys: [String]

            public var queryFragment: QueryFragment {
                var arrayFragment: QueryFragment = "ARRAY["
                for (index, key) in keys.enumerated() {
                    if index > 0 {
                        arrayFragment.append(", ")
                    }
                    arrayFragment.append("\(bind: key)")
                }
                arrayFragment.append("]")
                return "(\(jsonb.queryFragment) ?| \(arrayFragment))"
            }
        }

        /// PostgreSQL ?& operator - checks if all keys exist
        ///
        /// **PostgreSQL Documentation**: Table 9.48
        ///
        /// Example:
        /// ```swift
        /// User.where { $0.settings.hasAll(of: ["theme", "language"]) }
        /// // WHERE settings ?& ARRAY['theme', 'language']
        /// ```
        public struct AllExist<LHS: QueryExpression>: QueryExpression {
            public typealias QueryValue = Bool

            let jsonb: LHS
            let keys: [String]

            public var queryFragment: QueryFragment {
                var arrayFragment: QueryFragment = "ARRAY["
                for (index, key) in keys.enumerated() {
                    if index > 0 {
                        arrayFragment.append(", ")
                    }
                    arrayFragment.append("\(bind: key)")
                }
                arrayFragment.append("]")
                return "(\(jsonb.queryFragment) ?& \(arrayFragment))"
            }
        }
    }
}

// MARK: - Concatenation Operators

extension JSONB.AdditionalOperators {
    /// PostgreSQL || operator - concatenate/merge JSONB values (returns Data)
    ///
    /// **PostgreSQL Documentation**: Table 9.48
    ///
    /// This operator is used for raw Data columns or intermediate operations in SELECT queries.
    ///
    /// Example:
    /// ```swift
    /// User.update { $0.settings = $0.settings.concat(["newField": "value"]) }
    /// // UPDATE users SET settings = settings || '{"newField": "value"}'::jsonb
    /// ```
    public struct Concat<LHS: QueryExpression>: QueryExpression {
        public typealias QueryValue = Data

        let lhs: LHS
        let rhs: Data

        init(lhs: LHS, rhs: some Encodable) {
            self.lhs = lhs
            if let data = try? jsonbEncoder.encode(rhs) {
                self.rhs = data
            } else {
                self.rhs = Data()
            }
        }

        public var queryFragment: QueryFragment {
            let jsonString = String(data: rhs, encoding: .utf8) ?? "{}"
            return "(\(lhs.queryFragment) || \(bind: jsonString)::jsonb)"
        }
    }

    /// PostgreSQL || operator - concatenate/merge JSONB values (preserves JSONB type)
    ///
    /// **PostgreSQL Documentation**: Table 9.48
    ///
    /// This operator preserves the JSONB representation type, allowing assignment in UPDATE statements.
    ///
    /// Example:
    /// ```swift
    /// User.update { $0.settings = $0.settings.concat(["newField": "value"]) }
    /// // UPDATE users SET settings = settings || '{"newField": "value"}'::jsonb
    /// ```
    public struct TypedConcat<LHS: QueryExpression, Value: _JSONBRepresentationProtocol>:
        QueryExpression
    {
        public typealias QueryValue = Value

        let lhs: LHS
        let rhs: Data

        init(lhs: LHS, rhs: some Encodable) {
            self.lhs = lhs
            if let data = try? jsonbEncoder.encode(rhs) {
                self.rhs = data
            } else {
                self.rhs = Data()
            }
        }

        public var queryFragment: QueryFragment {
            let jsonString = String(data: rhs, encoding: .utf8) ?? "{}"
            return "(\(lhs.queryFragment) || \(bind: jsonString)::jsonb)"
        }
    }
}

// MARK: - Deletion Operators

extension JSONB.AdditionalOperators {
    /// Namespace for deletion operations (returns Data)
    ///
    /// **PostgreSQL Documentation**: Table 9.48 (operators: `-`, `#-`)
    ///
    /// These operators are used for raw Data columns or intermediate operations in SELECT queries.
    public enum Delete {
        /// PostgreSQL - operator - delete key from JSONB
        ///
        /// **PostgreSQL Documentation**: Table 9.48
        ///
        /// Example:
        /// ```swift
        /// User.update { $0.settings = $0.settings.removing("obsoleteField") }
        /// // UPDATE users SET settings = settings - 'obsoleteField'
        /// ```
        public struct Key<LHS: QueryExpression>: QueryExpression {
            public typealias QueryValue = Data

            let jsonb: LHS
            let key: String

            public var queryFragment: QueryFragment {
                "(\(jsonb.queryFragment) - \(bind: key))"
            }
        }

        /// PostgreSQL - operator - delete multiple keys from JSONB
        ///
        /// **PostgreSQL Documentation**: Table 9.48
        ///
        /// Example:
        /// ```swift
        /// User.update { $0.settings = $0.settings.removing(keys: ["field1", "field2"]) }
        /// // UPDATE users SET settings = settings - ARRAY['field1', 'field2']
        /// ```
        public struct Keys<LHS: QueryExpression>: QueryExpression {
            public typealias QueryValue = Data

            let jsonb: LHS
            let keys: [String]

            public var queryFragment: QueryFragment {
                var arrayFragment: QueryFragment = "ARRAY["
                for (index, key) in keys.enumerated() {
                    if index > 0 {
                        arrayFragment.append(", ")
                    }
                    arrayFragment.append("\(bind: key)")
                }
                arrayFragment.append("]")
                return "(\(jsonb.queryFragment) - \(arrayFragment))"
            }
        }

        /// PostgreSQL - operator - delete array element by index
        ///
        /// **PostgreSQL Documentation**: Table 9.48
        ///
        /// Example:
        /// ```swift
        /// User.update { $0.tags = $0.tags.removing(at: 2) }
        /// // UPDATE users SET tags = tags - 2
        /// ```
        public struct Index<LHS: QueryExpression>: QueryExpression {
            public typealias QueryValue = Data

            let jsonb: LHS
            let index: Int

            public var queryFragment: QueryFragment {
                "(\(jsonb.queryFragment) - \(index))"
            }
        }

        /// PostgreSQL #- operator - delete at path
        ///
        /// **PostgreSQL Documentation**: Table 9.48
        ///
        /// Example:
        /// ```swift
        /// User.update { $0.profile = $0.profile.removing(path: ["address", "zipcode"]) }
        /// // UPDATE users SET profile = profile #- '{address,zipcode}'
        /// ```
        public struct Path<LHS: QueryExpression>: QueryExpression {
            public typealias QueryValue = Data

            let jsonb: LHS
            let path: [String]

            public var queryFragment: QueryFragment {
                let pathArray = "'{" + path.joined(separator: ",") + "}'"
                return "(\(jsonb.queryFragment) #- \(raw: pathArray))"
            }
        }
    }

    /// Namespace for typed deletion operations (preserves JSONB type)
    ///
    /// **PostgreSQL Documentation**: Table 9.48 (operators: `-`, `#-`)
    ///
    /// These operators preserve the JSONB representation type, allowing assignment in UPDATE statements.
    public enum TypedDelete {
        /// PostgreSQL - operator - delete key from JSONB (typed)
        ///
        /// **PostgreSQL Documentation**: Table 9.48
        public struct Key<LHS: QueryExpression, Value: _JSONBRepresentationProtocol>:
            QueryExpression
        {
            public typealias QueryValue = Value

            let jsonb: LHS
            let key: String

            public var queryFragment: QueryFragment {
                "(\(jsonb.queryFragment) - \(bind: key))"
            }
        }

        /// PostgreSQL - operator - delete multiple keys from JSONB (typed)
        ///
        /// **PostgreSQL Documentation**: Table 9.48
        public struct Keys<LHS: QueryExpression, Value: _JSONBRepresentationProtocol>:
            QueryExpression
        {
            public typealias QueryValue = Value

            let jsonb: LHS
            let keys: [String]

            public var queryFragment: QueryFragment {
                var arrayFragment: QueryFragment = "ARRAY["
                for (index, key) in keys.enumerated() {
                    if index > 0 {
                        arrayFragment.append(", ")
                    }
                    arrayFragment.append("\(bind: key)")
                }
                arrayFragment.append("]")
                return "(\(jsonb.queryFragment) - \(arrayFragment))"
            }
        }

        /// PostgreSQL - operator - delete array element by index (typed)
        ///
        /// **PostgreSQL Documentation**: Table 9.48
        public struct Index<LHS: QueryExpression, Value: _JSONBRepresentationProtocol>:
            QueryExpression
        {
            public typealias QueryValue = Value

            let jsonb: LHS
            let index: Int

            public var queryFragment: QueryFragment {
                "(\(jsonb.queryFragment) - \(index))"
            }
        }

        /// PostgreSQL #- operator - delete at path (typed)
        ///
        /// **PostgreSQL Documentation**: Table 9.48
        public struct Path<LHS: QueryExpression, Value: _JSONBRepresentationProtocol>:
            QueryExpression
        {
            public typealias QueryValue = Value

            let jsonb: LHS
            let path: [String]

            public var queryFragment: QueryFragment {
                let pathArray = "'{" + path.joined(separator: ",") + "}'"
                return "(\(jsonb.queryFragment) #- \(raw: pathArray))"
            }
        }
    }
}

// MARK: - SQL/JSON Path Operators

extension JSONB.AdditionalOperators {
    /// PostgreSQL @? operator - does JSON path return any item for the specified JSON value?
    ///
    /// **PostgreSQL Documentation**: Table 9.48 (SQL/JSON path operators)
    ///
    /// Tests whether a JSON path expression matches any elements in the JSONB value.
    ///
    /// Example:
    /// ```swift
    /// User.where { $0.profile.jsonPathExists("$.address.city") }
    /// // WHERE profile @? '$.address.city'
    /// ```
    ///
    /// **Use cases:**
    /// - Checking if nested paths exist
    /// - Complex path-based queries
    /// - JSON schema validation
    ///
    /// **Note**: Requires PostgreSQL 12+
    public struct PathExists<LHS: QueryExpression>: QueryExpression {
        public typealias QueryValue = Bool

        let jsonb: LHS
        let path: String

        public var queryFragment: QueryFragment {
            "(\(jsonb.queryFragment) @? \(bind: path))"
        }
    }

    /// PostgreSQL @@ operator - returns the result of JSON path predicate check
    ///
    /// **PostgreSQL Documentation**: Table 9.48 (SQL/JSON path operators)
    ///
    /// Evaluates a JSON path expression and returns a boolean result.
    ///
    /// Example:
    /// ```swift
    /// User.where { $0.metadata.jsonPathMatch("$.tags[*] ? (@ == \"premium\")") }
    /// // WHERE metadata @@ '$.tags[*] ? (@ == "premium")'
    /// ```
    ///
    /// **Use cases:**
    /// - Advanced filtering with path predicates
    /// - Array element matching
    /// - Complex conditional queries
    ///
    /// **Note**: Requires PostgreSQL 12+
    public struct PathMatch<LHS: QueryExpression>: QueryExpression {
        public typealias QueryValue = Bool

        let jsonb: LHS
        let path: String

        public var queryFragment: QueryFragment {
            "(\(jsonb.queryFragment) @@ \(bind: path))"
        }
    }
}

// MARK: - SQL/JSON Path Operators on TableColumn

extension TableColumn where Value: _JSONBColumnValue {
    /// PostgreSQL's @? operator - checks if JSON path returns any item
    ///
    /// **PostgreSQL Documentation**: Table 9.48
    ///
    /// Example:
    /// ```swift
    /// User.where { $0.settings.jsonPathExists("$.notifications.email") }
    /// // WHERE settings @? '$.notifications.email'
    /// ```
    public func jsonPathExists(_ path: String) -> some QueryExpression<Bool> {
        JSONB.AdditionalOperators.PathExists(jsonb: self, path: path)
    }

    /// PostgreSQL's @@ operator - evaluates JSON path predicate
    ///
    /// **PostgreSQL Documentation**: Table 9.48
    ///
    /// Example:
    /// ```swift
    /// User.where { $0.tags.jsonPathMatch("$[*] ? (@ == \"active\")") }
    /// // WHERE tags @@ '$[*] ? (@ == "active")'
    /// ```
    public func jsonPathMatch(_ path: String) -> some QueryExpression<Bool> {
        JSONB.AdditionalOperators.PathMatch(jsonb: self, path: path)
    }
}
