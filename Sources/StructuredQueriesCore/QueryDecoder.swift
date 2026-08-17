import Foundation

/// A type that can decode values from a database connection into in-memory representations.
public protocol QueryDecoder {
    /// Decodes a single value of the given type from the current column.
    ///
    /// - Parameter columnType: The type to decode as.
    /// - Returns: A value of the requested type, or `nil` if the column is `NULL`.
    mutating func decode(
        _ columnType: [UInt8].Type
    ) throws -> [UInt8]?  // swiftlint:disable:this discouraged_optional_collection
    // swiftlint:disable:previous typed_throws_required
    // reason: fork-heritage untyped-throws surface (pointfreeco/swift-structured-queries)

    /// Decodes a single value of the given type from the current column.
    ///
    /// - Parameter columnType: The type to decode as.
    /// - Returns: A value of the requested type, or `nil` if the column is `NULL`.
    mutating func decode(_ columnType: Double.Type) throws -> Double?
    // swiftlint:disable:previous typed_throws_required
    // reason: fork-heritage untyped-throws surface (pointfreeco/swift-structured-queries)

    /// Decodes a single value of the given type from the current column.
    ///
    /// - Parameter columnType: The type to decode as.
    /// - Returns: A value of the requested type, or `nil` if the column is `NULL`.
    mutating func decode(_ columnType: Int64.Type) throws -> Int64?
    // swiftlint:disable:previous typed_throws_required
    // reason: fork-heritage untyped-throws surface (pointfreeco/swift-structured-queries)

    /// Decodes a single value of the given type from the current column.
    ///
    /// - Parameter columnType: The type to decode as.
    /// - Returns: A value of the requested type, or `nil` if the column is `NULL`.
    mutating func decode(_ columnType: UInt64.Type) throws -> UInt64?
    // swiftlint:disable:previous typed_throws_required
    // reason: fork-heritage untyped-throws surface (pointfreeco/swift-structured-queries)

    /// Decodes a single value of the given type from the current column.
    ///
    /// - Parameter columnType: The type to decode as.
    /// - Returns: A value of the requested type, or `nil` if the column is `NULL`.
    mutating func decode(_ columnType: String.Type) throws -> String?
    // swiftlint:disable:previous typed_throws_required
    // reason: fork-heritage untyped-throws surface (pointfreeco/swift-structured-queries)

    /// Decodes a single value of the given type from the current column.
    ///
    /// - Parameter columnType: The type to decode as.
    /// - Returns: A value of the requested type, or `nil` if the column is `NULL`.
    mutating func decode(_ columnType: Bool.Type) throws -> Bool?
    // swiftlint:disable:previous typed_throws_required
    // reason: fork-heritage untyped-throws surface (pointfreeco/swift-structured-queries)

    /// Decodes a single value of the given type from the current column.
    ///
    /// - Parameter columnType: The type to decode as.
    /// - Returns: A value of the requested type, or `nil` if the column is `NULL`.
    mutating func decode(_ columnType: Int.Type) throws -> Int?
    // swiftlint:disable:previous typed_throws_required
    // reason: fork-heritage untyped-throws surface (pointfreeco/swift-structured-queries)

    /// Decodes a single value of the given type from the current column.
    ///
    /// - Parameter columnType: The type to decode as.
    /// - Returns: A value of the requested type, or `nil` if the column is `NULL`.
    mutating func decode(_ columnType: Date.Type) throws -> Date?
    // swiftlint:disable:previous typed_throws_required
    // reason: fork-heritage untyped-throws surface (pointfreeco/swift-structured-queries)

    /// Decodes a single value of the given type from the current column.
    ///
    /// - Parameter columnType: The type to decode as.
    /// - Returns: A value of the requested type, or `nil` if the column is `NULL`.
    mutating func decode(_ columnType: UUID.Type) throws -> UUID?
    // swiftlint:disable:previous typed_throws_required
    // reason: fork-heritage untyped-throws surface (pointfreeco/swift-structured-queries)

    /// Decodes a single value of the given type from the current column.
    ///
    /// - Parameter columnType: The type to decode as.
    /// - Returns: A value of the requested type, or `nil` if the column is `NULL`.
    mutating func decode(_ columnType: Decimal.Type) throws -> Decimal?
    // swiftlint:disable:previous typed_throws_required
    // reason: fork-heritage untyped-throws surface (pointfreeco/swift-structured-queries)

    /// Decodes a single value of the given type starting from the current column.
    ///
    /// - Parameter columnType: The type to decode as.
    /// - Returns: A value of the requested type, or `nil` if the column is `NULL`.
    mutating func decode<T: QueryRepresentable>(_ columnType: T.Type) throws -> T.QueryOutput?
    // swiftlint:disable:previous typed_throws_required
    // reason: fork-heritage untyped-throws surface (pointfreeco/swift-structured-queries)
}

extension QueryDecoder {
    /// Decodes a single value of the given type starting from the current column.
    ///
    /// - Parameter columnType: The type to decode as.
    /// - Returns: A value of the requested type, or `nil` if the column is `NULL`.
    @inlinable
    @inline(__always)
    public mutating func decode<T: QueryRepresentable>(
        _ columnType: T.Type
    ) throws -> T.QueryOutput? {
        // swiftlint:disable:previous typed_throws_required
        // reason: fork-heritage untyped-throws surface (pointfreeco/swift-structured-queries)
        try T?(decoder: &self)?.queryOutput
    }

    /// Decodes a single tuple of the given type starting from the current column.
    ///
    /// - Parameter columnTypes: The types to decode as.
    /// - Returns: A tuple of the requested types.
    @inlinable
    @inline(__always)
    public mutating func decodeColumns<each T: QueryRepresentable>(
        _ columnTypes: (repeat each T).Type
    ) throws -> (repeat (each T).QueryOutput) {
        // swiftlint:disable:previous typed_throws_required
        // reason: fork-heritage untyped-throws surface (pointfreeco/swift-structured-queries)
        try (repeat (each T)(decoder: &self).queryOutput)
    }

    @inlinable
    @inline(__always)
    public mutating func decode<T: QueryRepresentable<T>>(
        _ columnType: T.Type = T.self
    ) throws -> T? {
        // swiftlint:disable:previous typed_throws_required
        // reason: fork-heritage untyped-throws surface (pointfreeco/swift-structured-queries)
        try T?(decoder: &self)?.queryOutput
    }
}

public enum QueryDecodingError: Swift.Error {
    case missingRequiredColumn
}
