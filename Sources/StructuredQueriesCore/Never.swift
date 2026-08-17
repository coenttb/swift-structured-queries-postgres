extension Never: Table {
    public struct TableColumns: TableDefinition {
        public typealias QueryValue = Never

        public static var allColumns: [any TableColumnExpression] { [] }
        // swiftlint:disable:previous no_any_protocol_existential
        // reason: fork-heritage type-erased DSL (pointfreeco/swift-structured-queries)

        public static var writableColumns: [any WritableTableColumnExpression] { [] }
        // swiftlint:disable:previous no_any_protocol_existential
        // reason: fork-heritage type-erased DSL (pointfreeco/swift-structured-queries)
    }

    public struct Selection: TableExpression {
        public typealias QueryValue = Never

        public var allColumns: [any QueryExpression] { [] }
        // swiftlint:disable:previous no_any_protocol_existential
        // reason: fork-heritage type-erased DSL (pointfreeco/swift-structured-queries)
    }

    public static var columns: TableColumns {
        TableColumns()
    }

    public static let tableName = "nevers"

    public init(decoder: inout some QueryDecoder) throws {
        // swiftlint:disable:previous typed_throws_required
        // reason: fork-heritage untyped-throws surface (pointfreeco/swift-structured-queries)
        throw NotDecodable()
    }

    private struct NotDecodable: Swift.Error {}
}
