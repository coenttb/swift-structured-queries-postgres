import Foundation

/// A type that represents PostgreSQL JSONB storage for Codable types
public struct _PostgresJSONBRepresentation<QueryOutput: Codable>: QueryRepresentable {
    public var queryOutput: QueryOutput

    public init(queryOutput: QueryOutput) {
        self.queryOutput = queryOutput
    }

    public init(decoder: inout some QueryDecoder) throws {
        // Decode from JSONB data
        // PostgreSQL returns JSONB as a string (when in text format) or as binary data
        // We handle it as string here since QueryDecoder provides string access
        let jsonString = try String(decoder: &decoder)
        let jsonData = Data(jsonString.utf8)
        self.queryOutput = try jsonDecoder.decode(QueryOutput.self, from: jsonData)
    }
}

// Add PostgresJSONB typealias to Codable types
extension Decodable where Self: Encodable {
    /// A query expression representing PostgreSQL JSONB.
    ///
    /// JSONB is PostgreSQL's binary JSON format that provides better performance
    /// and indexing capabilities compared to regular JSON text.
    ///
    /// ```swift
    /// @Table
    /// struct SubscriptionPlan {
    ///   @Column(as: [String].PostgresJSONB.self)
    ///   var features: [String]
    ///   
    ///   @Column(as: [String: String].PostgresJSONB.self)
    ///   var restrictions: [String: String]
    /// }
    /// ```
    public typealias PostgresJSONB = _PostgresJSONBRepresentation<Self>
}

// Support for Optional
extension Optional where Wrapped: Codable {
    @_documentation(visibility: private)
    public typealias PostgresJSONB = _PostgresJSONBRepresentation<Wrapped>?
}

// QueryBindable conformance - uses the new .jsonb case
extension _PostgresJSONBRepresentation: QueryBindable {
    public var queryBinding: QueryBinding {
        do {
            let jsonData = try jsonEncoder.encode(queryOutput)
            return .jsonb(jsonData)
        } catch {
            return .invalid(error)
        }
    }
}

// JSON encoders/decoders (similar to Codable+JSON.swift)
private let jsonDecoder: JSONDecoder = {
    var decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom {
        try Date(iso8601String: try $0.singleValueContainer().decode(String.self))
    }
    return decoder
}()

private let jsonEncoder: JSONEncoder = {
    var encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .custom { date, encoder in
        var container = encoder.singleValueContainer()
        try container.encode(date.iso8601String)
    }
    #if DEBUG
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    #endif
    return encoder
}()
