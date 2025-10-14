/// A builder of insert statement values.
///
/// This result builder is used by ``Table/insert(or:_:values:onConflict:where:doUpdate:where:)`` to
/// insert any number of rows into a table.
@resultBuilder
public enum InsertValuesBuilder<Value> {
    public static func buildExpression(_ expression: [Value]) -> [[QueryFragment]]
    where Value: Table {
        var valueFragments: [[QueryFragment]] = []
        for value in expression {
            var valueFragment: [QueryFragment] = []
            for column in Value.TableColumns.writableColumns {
                func open<Root, Member>(
                    _ column: some WritableTableColumnExpression<Root, Member>
                ) -> QueryFragment {
                    Member(queryOutput: (value as! Root)[keyPath: column.keyPath]).queryFragment
                }
                valueFragment.append(open(column))
            }
            valueFragments.append(valueFragment)
        }
        return valueFragments
    }

    @_disfavoredOverload
    public static func buildExpression(_ expression: [Value.Draft]) -> [[QueryFragment]]
    where Value: PrimaryKeyedTable {
        var valueFragments: [[QueryFragment]] = []
        for value in expression {
            var valueFragment: [QueryFragment] = []
            for column in Value.Draft.TableColumns.writableColumns {
                func open<Root, Member>(
                    _ column: some WritableTableColumnExpression<Root, Member>
                ) -> QueryFragment {
                    Member(queryOutput: (value as! Root)[keyPath: column.keyPath]).queryFragment
                }
                valueFragment.append(open(column))
            }
            valueFragments.append(valueFragment)
        }
        return valueFragments
    }

    @_disfavoredOverload
    public static func buildExpression<V: QueryExpression>(
        _ expression: [V]
    ) -> [[QueryFragment]]
    where
        Value == V.QueryValue,
        V.QueryValue: QueryRepresentable & QueryBindable
    {
        [expression.map(\.queryFragment)]
    }

    @_disfavoredOverload
    public static func buildExpression(
        _ expression: [Value.QueryOutput]
    ) -> [[QueryFragment]]
    where Value: QueryRepresentable & QueryBindable {
        [expression.map { Value(queryOutput: $0).queryFragment }]
    }

    public static func buildExpression(_ expression: Value) -> [[QueryFragment]]
    where Value: Table {
        buildExpression([expression])
    }

    public static func buildExpression(_ expression: Value.Draft) -> [[QueryFragment]]
    where Value: PrimaryKeyedTable {
        buildExpression([expression])
    }

    @_disfavoredOverload
    public static func buildExpression<V: QueryExpression>(
        _ expression: V
    ) -> [[QueryFragment]]
    where
        Value == V.QueryValue,
        V.QueryValue: QueryRepresentable & QueryBindable
    {
        buildExpression([expression])
    }

    public static func buildExpression(
        _ expression: Value.QueryOutput
    ) -> [[QueryFragment]]
    where Value: QueryRepresentable & QueryBindable {
        buildExpression([expression])
    }

    @_disfavoredOverload
    public static func buildExpression<each V: QueryExpression>(
        _ expression: (repeat each V)
    ) -> [[QueryFragment]]
    where
        Value == (repeat (each V).QueryValue),
        repeat (each V).QueryValue: QueryRepresentable & QueryBindable
    {
        var valueFragment: [QueryFragment] = []
        for column in repeat each expression {
            valueFragment.append(column.queryFragment)
        }
        return [valueFragment]
    }

    public static func buildExpression<each V: QueryRepresentable & QueryBindable>(
        _ expression: (repeat (each V).QueryOutput)
    ) -> [[QueryFragment]]
    where Value == (repeat each V) {
        var valueFragment: [QueryFragment] = []
        for (columnType, column) in repeat ((each V).self, each expression) {
            valueFragment.append(columnType.init(queryOutput: column).queryFragment)
        }
        return [valueFragment]
    }

    public static func buildExpression(
        _ expression: Value.Selection
    ) -> [[QueryFragment]]
    where Value: Table {
        [expression.allColumns.map(\.queryFragment)]
    }

    public static func buildArray(_ components: [[[QueryFragment]]]) -> [[QueryFragment]] {
        components.flatMap(\.self)
    }

    public static func buildBlock(_ components: [[QueryFragment]]) -> [[QueryFragment]] {
        components
    }

    public static func buildEither(first component: [[QueryFragment]]) -> [[QueryFragment]] {
        component
    }

    public static func buildEither(second component: [[QueryFragment]]) -> [[QueryFragment]] {
        component
    }

    public static func buildLimitedAvailability(_ component: [[QueryFragment]]) -> [[QueryFragment]]
    {
        component
    }

    public static func buildOptional(_ component: [[QueryFragment]]?) -> [[QueryFragment]] {
        component ?? []
    }

    public static func buildPartialBlock(first: [[QueryFragment]]) -> [[QueryFragment]] {
        first
    }

    public static func buildPartialBlock(
        accumulated: [[QueryFragment]],
        next: [[QueryFragment]]
    ) -> [[QueryFragment]] {
        accumulated + next
    }
}

public struct _ExcludedName: AliasName {
    public static var aliasName: String { "excluded" }
}
