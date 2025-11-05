extension Select {
    /// Creates a new select statement from this one by overriding its `LIMIT` and `OFFSET` clauses.
    ///
    /// - Parameters:
    ///   - maxLength: A closure that produces a `LIMIT` expression from this select's tables.
    ///   - offset: A closure that produces an `OFFSET` expression from this select's tables.
    /// - Returns: A new select statement that overrides this one's `LIMIT` and `OFFSET` clauses.
    public func limit<each J: Table>(
        _ maxLength: (From.TableColumns, repeat (each J).TableColumns) -> some QueryExpression<Int>,
        offset: ((From.TableColumns, repeat (each J).TableColumns) -> some QueryExpression<Int>)? =
            nil
    ) -> Self
    where Joins == (repeat each J) {
        var select = self
        select.limit = _LimitClause(
            maxLength: maxLength(From.columns, repeat (each J).columns).queryFragment,
            offset: offset?(From.columns, repeat (each J).columns).queryFragment
                ?? select.limit?.offset
        )
        return select
    }

    /// Creates a new select statement from this one by overriding its `LIMIT` and `OFFSET` clauses.
    ///
    /// - Parameters:
    ///   - maxLength: A closure that produces a `LIMIT` expression from this select's tables.
    ///   - offset: A closure that produces an `OFFSET` expression from this select's tables.
    /// - Returns: A new select statement that overrides this one's `LIMIT` and `OFFSET` clauses.
    public func limit(
        _ maxLength: (From.TableColumns, Joins.TableColumns) -> some QueryExpression<Int>,
        offset: ((From.TableColumns, Joins.TableColumns) -> some QueryExpression<Int>)? = nil
    ) -> Self
    where Joins: Table {
        var select = self
        select.limit = _LimitClause(
            maxLength: maxLength(From.columns, Joins.columns).queryFragment,
            offset: offset?(From.columns, Joins.columns).queryFragment ?? select.limit?.offset
        )
        return select
    }

    /// Creates a new select statement from this one by overriding its `LIMIT` and `OFFSET` clauses.
    ///
    /// - Parameters:
    ///   - maxLength: An integer limit for the select's `LIMIT` clause.
    ///   - offset: An optional integer offset of the select's `OFFSET` clause.
    /// - Returns: A new select statement that overrides this one's `LIMIT` and `OFFSET` clauses.
    public func limit<each J: Table>(_ maxLength: Int, offset: Int? = nil) -> Self
    where Joins == (repeat each J) {
        var select = self
        select.limit = _LimitClause(
            maxLength: maxLength.queryFragment,
            offset: offset?.queryFragment ?? select.limit?.offset
        )
        return select
    }
}
