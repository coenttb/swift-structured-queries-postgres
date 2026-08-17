extension RangeReplaceableCollection {
    public init<each Q: QueryExpression>(_ elements: repeat each Q)
    where Element == QueryFragment {
        self.init()
        for element in repeat each elements {
            append(element.queryFragment)
        }
    }

    public init<each Q: QueryExpression>(_ elements: repeat each Q)
    where Element == any QueryExpression {
        // swiftlint:disable:previous no_any_protocol_existential
        // reason: fork-heritage type-erased DSL (pointfreeco/swift-structured-queries)
        self.init()
        for element in repeat each elements {
            append(element)
        }
    }

    public func removingDuplicates() -> Self where Element: Hashable {
        var set: Set<Element> = []
        return filter { set.insert($0).inserted }
    }
}
