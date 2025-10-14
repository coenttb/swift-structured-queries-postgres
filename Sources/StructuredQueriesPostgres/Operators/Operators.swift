import StructuredQueriesCore

// MARK: - Core Operator Helper Structs

internal func isNull<Value>(_ expression: some QueryExpression<Value>) -> Bool {
    (expression as? any _OptionalProtocol).map { $0._wrapped == nil } ?? false
}

public struct _Null<Wrapped: QueryExpression>: QueryExpression {
    public typealias QueryValue = Wrapped?
    public var queryFragment: QueryFragment {
        Wrapped?.none.queryFragment
    }
}

extension _Null: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {}
}

struct UnaryOperator<QueryValue>: QueryExpression {
    let `operator`: QueryFragment
    let base: QueryFragment
    let separator: QueryFragment

    init(operator: QueryFragment, base: some QueryExpression, separator: QueryFragment = " ") {
        self.operator = `operator`
        self.base = base.queryFragment
        self.separator = separator
    }

    var queryFragment: QueryFragment {
        "\(`operator`)\(separator)(\(base))"
    }
}

struct BinaryOperator<QueryValue>: QueryExpression {
    let lhs: QueryFragment
    let `operator`: QueryFragment
    let rhs: QueryFragment

    init(
        lhs: some QueryExpression,
        operator: QueryFragment,
        rhs: some QueryExpression
    ) {
        self.lhs = lhs.queryFragment
        self.operator = `operator`
        self.rhs = rhs.queryFragment
    }

    var queryFragment: QueryFragment {
        // PostgreSQL-specific: Translate IS to IS NOT DISTINCT FROM for row comparisons
        // SQLite allows: (tuple) IS (tuple)
        // PostgreSQL requires: (tuple) IS NOT DISTINCT FROM (tuple) for NULL-safe comparisons
        let op: QueryFragment
        if `operator`.debugDescription == "IS" {
            op = "IS NOT DISTINCT FROM"
        } else if `operator`.debugDescription == "IS NOT" {
            op = "IS DISTINCT FROM"
        } else {
            op = `operator`
        }

        // For IN/BETWEEN operators, RHS is already parenthesized by _SequenceExpression
        // Don't double-wrap to avoid redundant parens: IN ((1, 2, 3)) → IN (1, 2, 3)
        let rhsDescription = rhs.debugDescription
        let wrappedRhs: QueryFragment
        if rhsDescription.hasPrefix("(") && rhsDescription.hasSuffix(")") {
            wrappedRhs = rhs
        } else {
            wrappedRhs = "(\(rhs))"
        }

        return "(\(lhs)) \(op) \(wrappedRhs)"
    }
}

struct LikeOperator<
    LHS: QueryExpression<String>,
    RHS: QueryExpression<String>
>: QueryExpression {
    typealias QueryValue = Bool

    let string: LHS
    let pattern: RHS
    let escape: Character?

    var queryFragment: QueryFragment {
        var query: QueryFragment = "(\(string.queryFragment) LIKE \(pattern.queryFragment)"
        if let escape {
            query.append(" ESCAPE \(bind: String(escape))")
        }
        query.append(")")
        return query
    }
}

extension Sequence where Element: QueryExpression, Element.QueryValue: QueryExpression {
    typealias Expression = _SequenceExpression<Self>
}

struct _SequenceExpression<S: Sequence>: QueryExpression
where S.Element: QueryExpression, S.Element.QueryValue: QueryExpression {
    typealias QueryValue = S
    let queryFragment: QueryFragment
    init(elements: S) {
        let itemsArray = Array(elements)
        if itemsArray.isEmpty {
            // PostgreSQL doesn't allow empty IN clauses: IN ()
            // Return NULL (no parens), BinaryOperator will wrap it: IN (NULL)
            // This never matches since NULL != anything
            queryFragment = "NULL"
        } else {
            // Wrap entire sequence in parens for IN operator
            // Scalars: (1, 2, 3) → column IN (1, 2, 3) ✅
            // Tuples: ((uuid, 'type')) → (a, b) IN ((uuid, 'type')) ✅
            let items = itemsArray.map { $0.queryFragment }.joined(separator: ", ")
            queryFragment = "(\(items))"
        }
    }
}
