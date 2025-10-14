import Foundation

extension Data: QueryBindable {
    public var queryBinding: QueryBinding {
        .blob([UInt8](self))
    }

    public init(decoder: inout some QueryDecoder) throws {
        // Decode as blob/bytea
        guard let bytes = try decoder.decode([UInt8].self)
        else { throw QueryDecodingError.missingRequiredColumn }
        self.init(bytes)
    }
}

extension URL: QueryBindable {
    public var queryBinding: QueryBinding {
        .text(absoluteString)
    }

    public init(decoder: inout some QueryDecoder) throws {
        guard let url = Self(string: try String(decoder: &decoder)) else {
            throw InvalidURL()
        }
        self = url
    }
}

private struct InvalidURL: Error {}
