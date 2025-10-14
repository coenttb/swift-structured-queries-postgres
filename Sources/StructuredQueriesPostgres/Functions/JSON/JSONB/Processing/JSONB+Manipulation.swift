import Foundation
import StructuredQueriesCore

// MARK: - JSONB.Processing.Manipulation (Table 9.51)

extension JSONB.Processing {
    /// PostgreSQL jsonb_set function - sets a value at the specified path
    ///
    /// **PostgreSQL Documentation**: Table 9.51
    public struct Set<LHS: QueryExpression>: QueryExpression {
        public typealias QueryValue = Data

        let jsonb: LHS
        let path: [String]
        let value: Data
        let createIfMissing: Bool

        init(jsonb: LHS, path: [String], value: some Encodable, createIfMissing: Bool = true) {
            self.jsonb = jsonb
            self.path = path
            self.createIfMissing = createIfMissing
            if let data = try? jsonbEncoder.encode(value) {
                self.value = data
            } else {
                self.value = Data()
            }
        }

        public var queryFragment: QueryFragment {
            let pathArray = "'{" + path.joined(separator: ",") + "}'"
            let jsonString = String(data: value, encoding: .utf8) ?? "{}"
            return
                "jsonb_set(\(jsonb.queryFragment), \(raw: pathArray), \(bind: jsonString)::jsonb, \(createIfMissing))"
        }
    }

    /// PostgreSQL jsonb_insert function - inserts a value at the specified path
    ///
    /// **PostgreSQL Documentation**: Table 9.51
    public struct Insert<LHS: QueryExpression>: QueryExpression {
        public typealias QueryValue = Data

        let jsonb: LHS
        let path: [String]
        let value: Data
        let after: Bool

        init(jsonb: LHS, path: [String], value: some Encodable, after: Bool = false) {
            self.jsonb = jsonb
            self.path = path
            self.after = after
            if let data = try? jsonbEncoder.encode(value) {
                self.value = data
            } else {
                self.value = Data()
            }
        }

        public var queryFragment: QueryFragment {
            let pathArray = "'{" + path.joined(separator: ",") + "}'"
            let jsonString = String(data: value, encoding: .utf8) ?? "{}"
            return
                "jsonb_insert(\(jsonb.queryFragment), \(raw: pathArray), \(bind: jsonString)::jsonb, \(after))"
        }
    }

    /// PostgreSQL jsonb_strip_nulls function - removes null values from a JSONB object
    ///
    /// **PostgreSQL Documentation**: Table 9.51
    public struct StripNulls<LHS: QueryExpression>: QueryExpression {
        public typealias QueryValue = Data

        let jsonb: LHS

        public var queryFragment: QueryFragment {
            "jsonb_strip_nulls(\(jsonb.queryFragment))"
        }
    }
}

// MARK: - JSONB.Processing.Typed (preserve JSONB type)

extension JSONB.Processing {
    /// PostgreSQL jsonb_set function - sets a value at the specified path (typed)
    ///
    /// **PostgreSQL Documentation**: Table 9.51
    public struct TypedSet<LHS: QueryExpression, Value: _JSONBRepresentationProtocol>:
        QueryExpression
    {
        public typealias QueryValue = Value

        let jsonb: LHS
        let path: [String]
        let value: Data
        let createIfMissing: Bool

        init(jsonb: LHS, path: [String], value: some Encodable, createIfMissing: Bool = true) {
            self.jsonb = jsonb
            self.path = path
            self.createIfMissing = createIfMissing
            if let data = try? jsonbEncoder.encode(value) {
                self.value = data
            } else {
                self.value = Data()
            }
        }

        public var queryFragment: QueryFragment {
            let pathArray = "'{" + path.joined(separator: ",") + "}'"
            let jsonString = String(data: value, encoding: .utf8) ?? "{}"
            return
                "jsonb_set(\(jsonb.queryFragment), \(raw: pathArray), \(bind: jsonString)::jsonb, \(createIfMissing))"
        }
    }

    /// PostgreSQL jsonb_insert function - inserts a value at the specified path (typed)
    ///
    /// **PostgreSQL Documentation**: Table 9.51
    public struct TypedInsert<LHS: QueryExpression, Value: _JSONBRepresentationProtocol>:
        QueryExpression
    {
        public typealias QueryValue = Value

        let jsonb: LHS
        let path: [String]
        let value: Data
        let after: Bool

        init(jsonb: LHS, path: [String], value: some Encodable, after: Bool = false) {
            self.jsonb = jsonb
            self.path = path
            self.after = after
            if let data = try? jsonbEncoder.encode(value) {
                self.value = data
            } else {
                self.value = Data()
            }
        }

        public var queryFragment: QueryFragment {
            let pathArray = "'{" + path.joined(separator: ",") + "}'"
            let jsonString = String(data: value, encoding: .utf8) ?? "{}"
            return
                "jsonb_insert(\(jsonb.queryFragment), \(raw: pathArray), \(bind: jsonString)::jsonb, \(after))"
        }
    }

    /// PostgreSQL jsonb_strip_nulls function - removes null values from a JSONB object (typed)
    ///
    /// **PostgreSQL Documentation**: Table 9.51
    public struct TypedStripNulls<LHS: QueryExpression, Value: _JSONBRepresentationProtocol>:
        QueryExpression
    {
        public typealias QueryValue = Value

        let jsonb: LHS

        public var queryFragment: QueryFragment {
            "jsonb_strip_nulls(\(jsonb.queryFragment))"
        }
    }
}

// MARK: - QueryExpression Function Extensions

extension QueryExpression where QueryValue == Data {
    /// PostgreSQL's jsonb_set function - Update JSONB at path
    ///
    /// Example:
    /// ```swift
    /// User.update {
    ///     $0.settings = $0.settings.setting(["preferences", "theme"], to: "dark")
    /// }
    /// // UPDATE users SET settings = jsonb_set(settings, '{preferences,theme}', '"dark"'::jsonb, true)
    /// ```
    public func setting<T: Encodable>(
        _ path: [String],
        to value: T,
        createIfMissing: Bool = true
    ) -> some QueryExpression<Data> {
        JSONB.Processing.Set(
            jsonb: self, path: path, value: value, createIfMissing: createIfMissing)
    }

    /// PostgreSQL's jsonb_insert function - Insert into JSONB at path
    ///
    /// Example:
    /// ```swift
    /// User.update {
    ///     $0.settings = $0.settings.inserting(["id": 123], at: ["items", "0"])
    /// }
    /// // UPDATE users SET settings = jsonb_insert(settings, '{items,0}', '{"id": 123}'::jsonb, false)
    /// ```
    public func inserting<T: Encodable>(
        _ value: T,
        at path: [String],
        after: Bool = false
    ) -> some QueryExpression<Data> {
        JSONB.Processing.Insert(jsonb: self, path: path, value: value, after: after)
    }

    /// PostgreSQL's jsonb_strip_nulls function - Remove null values from JSONB
    ///
    /// Example:
    /// ```swift
    /// User.update { $0.settings = $0.settings.strippingNulls() }
    /// // UPDATE users SET settings = jsonb_strip_nulls(settings)
    /// ```
    public func strippingNulls() -> some QueryExpression<Data> {
        JSONB.Processing.StripNulls(jsonb: self)
    }

    /// PostgreSQL's jsonb_pretty function - Format JSONB for display
    ///
    /// Example:
    /// ```swift
    /// User.select { $0.settings.prettyFormatted() }
    /// // SELECT jsonb_pretty(settings) FROM users
    /// ```
    public func prettyFormatted() -> some QueryExpression<String> {
        JSONB.Processing.Pretty(jsonb: self)
    }

    /// PostgreSQL's jsonb_typeof function - Get JSONB value type
    ///
    /// Example:
    /// ```swift
    /// User.select { $0.settings.typeString() }
    /// // SELECT jsonb_typeof(settings) FROM users
    /// ```
    public func typeString() -> some QueryExpression<String> {
        JSONB.Processing.TypeOf(jsonb: self)
    }

    /// PostgreSQL's jsonb_array_length function - Get JSONB array length
    ///
    /// Example:
    /// ```swift
    /// User.select { $0.tags.arrayLength() }
    /// // SELECT jsonb_array_length(tags) FROM users
    /// ```
    ///
    /// > Note: This method is specifically for JSONB arrays. For PostgreSQL array types,
    /// > use the `arrayLength()` method on Collection types instead.
    public func arrayLength() -> some QueryExpression<Int> {
        JSONB.Processing.ArrayLength(jsonb: self)
    }
}
