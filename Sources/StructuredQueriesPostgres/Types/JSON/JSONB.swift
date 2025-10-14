import Foundation
import StructuredQueriesCore

/// Protocol to identify JSONB representation types
/// Used for operator extension constraints
public protocol _JSONBRepresentationProtocol: QueryRepresentable {
    associatedtype UnderlyingType: Codable
}

/// A type representing PostgreSQL JSONB storage for Codable types.
///
/// This type mirrors the upstream `_CodableJSONRepresentation` pattern but uses
/// PostgreSQL's binary JSONB format instead of text JSON.
///
/// ```swift
/// @Table("posts")
/// struct Post {
///     @Column(as: [String].JSONB.self)
///     var tags: [String]
///
///     @Column(as: [String: String].JSONB.self)
///     var metadata: [String: String]
/// }
/// ```
public struct _JSONBRepresentation<QueryOutput: Codable>: _JSONBRepresentationProtocol {
    public typealias UnderlyingType = QueryOutput

    public var queryOutput: QueryOutput

    public init(queryOutput: QueryOutput) {
        self.queryOutput = queryOutput
    }
}

// MARK: - Typealias Extensions

extension Decodable where Self: Encodable {
    /// A query expression representing PostgreSQL JSONB.
    ///
    /// JSONB is PostgreSQL's binary JSON format that provides better performance
    /// and indexing capabilities compared to regular JSON text.
    ///
    /// ```swift
    /// @Table
    /// struct SubscriptionPlan {
    ///   @Column(as: [String].JSONB.self)
    ///   var features: [String]
    ///
    ///   @Column(as: [String: String].JSONB.self)
    ///   var restrictions: [String: String]
    /// }
    /// ```
    public typealias JSONB = _JSONBRepresentation<Self>
}

extension Optional where Wrapped: Codable {
    @_documentation(visibility: private)
    public typealias JSONB = _JSONBRepresentation<Wrapped>?
}

// MARK: - QueryBindable

extension _JSONBRepresentation: QueryBindable {
    public var queryBinding: QueryBinding {
        do {
            let jsonData = try jsonEncoder.encode(queryOutput)
            return .jsonb(jsonData)
        } catch {
            return .invalid(error)
        }
    }
}

// MARK: - QueryDecodable

extension _JSONBRepresentation: QueryDecodable {
    public init(decoder: inout some QueryDecoder) throws {
        self.init(
            queryOutput: try jsonDecoder.decode(
                QueryOutput.self,
                from: Data(String(decoder: &decoder).utf8)
            )
        )
    }
}

// MARK: - Equatable & Sendable

extension _JSONBRepresentation: Equatable where QueryOutput: Equatable {}
extension _JSONBRepresentation: Sendable where QueryOutput: Sendable {}

// MARK: - JSON Encoder/Decoder

private let jsonDecoder: JSONDecoder = {
    var decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom {
        try Date(iso8601String: $0.singleValueContainer().decode(String.self))
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
        encoder.outputFormatting = [.sortedKeys]  // Remove prettyPrinted for SQL
    #endif
    return encoder
}()
