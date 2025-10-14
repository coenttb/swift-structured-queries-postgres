import Foundation
import StructuredQueriesPostgresSupport

/// A type that enumerates the values that can be bound to the parameters of a SQL statement.
public enum QueryBinding: Hashable, Sendable {
    /// A value that should be bound to a statement as bytes.
    case blob([UInt8])

    case bool(Bool)

    /// A value that should be bound to a statement as a double.
    case double(Double)

    /// A value that should be bound to a statement as a date.
    case date(Date)

    /// A value that should be bound to a statement as an integer.
    case int(Int64)

    /// A value that should be bound to a statement as `NULL`.
    case null

    /// A value that should be bound to a statement as a string.
    case text(String)

    /// A value that should be bound to a statement as a unique identifier.
    case uuid(UUID)

    /// A value that should be bound to a statement as PostgreSQL JSONB.
    case jsonb(Data)

    /// A value that should be bound to a statement as a decimal.
    case decimal(Decimal)

    /// A value that should be bound to a statement as a PostgreSQL native array.
    case boolArray([Bool])
    case stringArray([String])
    case intArray([Int])
    case int16Array([Int16])
    case int32Array([Int32])
    case int64Array([Int64])
    case floatArray([Float])
    case doubleArray([Double])
    case uuidArray([UUID])
    case dateArray([Date])

    /// A generic array case for any QueryBindable element type that doesn't have a specific case.
    /// Elements are converted to their individual QueryBindings.
    case genericArray([QueryBinding])

    /// An error describing why a value cannot be bound to a statement.
    case invalid(QueryBindingError)

    @_disfavoredOverload
    public static func invalid(_ error: any Error) -> Self {
        .invalid(QueryBindingError(underlyingError: error))
    }
}

/// A type that wraps errors encountered when trying to bind a value to a statement.
public struct QueryBindingError: Error, Hashable {
    public let underlyingError: any Error
    public init(underlyingError: any Error) {
        self.underlyingError = underlyingError
    }
    public static func == (lhs: Self, rhs: Self) -> Bool { true }
    public func hash(into hasher: inout Hasher) {}
}

extension QueryBinding: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .blob(let data):
            return String(decoding: data, as: UTF8.self)
                .debugDescription
                .dropLast()
                .dropFirst()
                .quoted(.text)
        case .date(let date):
            return date.iso8601String.quoted(.text)
        case .double(let value):
            return "\(value)"
        case .int(let value):
            return "\(value)"
        case .null:
            return "NULL"
        case .text(let string):
            return string.quoted(.text)
        case .uuid(let uuid):
            return uuid.uuidString.lowercased().quoted(.text)
        case .jsonb(let data):
            return String(decoding: data, as: UTF8.self).quoted(.text)
        case .decimal(let value):
            return "\(value)"
        case .boolArray(let values):
            return "ARRAY[\(values.map { $0 ? "true" : "false" }.joined(separator: ", "))]"
        case .stringArray(let values):
            return "ARRAY[\(values.map { $0.quoted(.text) }.joined(separator: ", "))]"
        case .intArray(let values):
            return "ARRAY[\(values.map { "\($0)" }.joined(separator: ", "))]"
        case .int16Array(let values):
            return "ARRAY[\(values.map { "\($0)" }.joined(separator: ", "))]"
        case .int32Array(let values):
            return "ARRAY[\(values.map { "\($0)" }.joined(separator: ", "))]"
        case .int64Array(let values):
            return "ARRAY[\(values.map { "\($0)" }.joined(separator: ", "))]"
        case .floatArray(let values):
            return "ARRAY[\(values.map { "\($0)" }.joined(separator: ", "))]"
        case .doubleArray(let values):
            return "ARRAY[\(values.map { "\($0)" }.joined(separator: ", "))]"
        case .uuidArray(let values):
            return
                "ARRAY[\(values.map { $0.uuidString.lowercased().quoted(.text) }.joined(separator: ", "))]"
        case .dateArray(let values):
            return "ARRAY[\(values.map { $0.iso8601String.quoted(.text) }.joined(separator: ", "))]"
        case .genericArray(let bindings):
            return "ARRAY[\(bindings.map { $0.debugDescription }.joined(separator: ", "))]"
        case .invalid(let error):
            return "<invalid: \(error.underlyingError.localizedDescription)>"
        case .bool(let bool):
            return bool ? "true" : "false"
        }
    }
}
