// MARK: - INNER JOIN Operations

extension Select {
    // MARK: Primary Overload - Most General Case

    /// Creates a new select statement from this one by joining another table.
    ///
    /// This is the primary overload handling the most general case where both
    /// the caller and other select may have columns and joins.
    ///
    /// - Parameters:
    ///   - other: A select statement for another table.
    ///   - constraint: The constraint describing the join.
    /// - Returns: A new select statement that joins the given table and combines their clauses.
    public func join<
        each C1: QueryRepresentable,
        each C2: QueryRepresentable,
        F: Table,
        each J1: Table,
        each J2: Table
    >(
        _ other: some SelectStatement<(repeat each C2), F, (repeat each J2)>,
        on constraint: (
            (
                From.TableColumns, repeat (each J1).TableColumns, F.TableColumns,
                repeat (each J2).TableColumns
            )
        ) -> some QueryExpression<Bool>
    ) -> Select<(repeat each C1, repeat each C2), From, (repeat each J1, F, repeat each J2)>
    where Columns == (repeat each C1), Joins == (repeat each J1) {
        let other = other.asSelect()
        let join = _JoinClause(
            operator: nil,
            table: F.self,
            constraint: constraint(
                (From.columns, repeat (each J1).columns, F.columns, repeat (each J2).columns)
            )
        )
        return Select<(repeat each C1, repeat each C2), From, (repeat each J1, F, repeat each J2)>(
            isEmpty: isEmpty || other.isEmpty,
            distinct: other.distinct ?? distinct,
            columns: columns + other.columns,
            joins: joins + [join] + other.joins,
            where: `where` + other.where,
            group: group + other.group,
            having: having + other.having,
            order: order + other.order,
            windows: windows + other.windows,
            limit: other.limit ?? limit
        )
    }

    // MARK: Optimization 1 - Other Has No Joins

    /// Creates a new select statement from this one by joining another table.
    ///
    /// Optimization for when the other select has no joins (`other.Joins == ()`).
    ///
    /// - Parameters:
    ///   - other: A select statement for another table.
    ///   - constraint: The constraint describing the join.
    /// - Returns: A new select statement that joins the given table.
    @_documentation(visibility: private)
    @_disfavoredOverload
    public func join<
        each C1: QueryRepresentable, each C2: QueryRepresentable, F: Table, each J: Table
    >(
        _ other: some SelectStatement<(repeat each C2), F, ()>,
        on constraint: (
            (From.TableColumns, repeat (each J).TableColumns, F.TableColumns)
        ) -> some QueryExpression<Bool>
    ) -> Select<(repeat each C1, repeat each C2), From, (repeat each J, F)>
    where Columns == (repeat each C1), Joins == (repeat each J) {
        let other = other.asSelect()
        let join = _JoinClause(
            operator: nil,
            table: F.self,
            constraint: constraint(
                (From.columns, repeat (each J).columns, F.columns)
            )
        )
        return Select<(repeat each C1, repeat each C2), From, (repeat each J, F)>(
            isEmpty: isEmpty || other.isEmpty,
            distinct: other.distinct ?? distinct,
            columns: columns + other.columns,
            joins: joins + [join] + other.joins,
            where: `where` + other.where,
            group: group + other.group,
            having: having + other.having,
            order: order + other.order,
            windows: windows + other.windows,
            limit: other.limit ?? limit
        )
    }

    // MARK: Optimization 2 - Other Has No Columns

    /// Creates a new select statement from this one by joining another table.
    ///
    /// Optimization for when the other select has no columns (`other.Columns == ()`).
    ///
    /// - Parameters:
    ///   - other: A select statement for another table.
    ///   - constraint: The constraint describing the join.
    /// - Returns: A new select statement that joins the given table.
    @_disfavoredOverload
    @_documentation(visibility: private)
    public func join<F: Table, each J: Table>(
        _ other: some SelectStatement<(), F, (repeat each J)>,
        on constraint: (
            (From.TableColumns, F.TableColumns, repeat (each J).TableColumns)
        ) -> some QueryExpression<Bool>
    ) -> Select<QueryValue, From, (F, repeat each J)> where QueryValue: QueryRepresentable {
        let other = other.asSelect()
        let join = _JoinClause(
            operator: nil,
            table: F.self,
            constraint: constraint(
                (From.columns, F.columns, repeat (each J).columns)
            )
        )
        return Select<QueryValue, From, (F, repeat each J)>(
            isEmpty: isEmpty || other.isEmpty,
            distinct: other.distinct ?? distinct,
            columns: columns + other.columns,
            joins: joins + [join] + other.joins,
            where: `where` + other.where,
            group: group + other.group,
            having: having + other.having,
            order: order + other.order,
            windows: windows + other.windows,
            limit: other.limit ?? limit
        )
    }

    // MARK: Where Delegation - Caller Is SelectOf

    /// Creates a new select statement from this one by joining another table.
    ///
    /// This overload handles delegation from `Where.join()` when the caller
    /// is a SelectOf (no columns, no joins). It enables use of `some SelectStatement`
    /// instead of `any` for better type inference.
    ///
    /// - Parameters:
    ///   - other: A select statement for another table.
    ///   - constraint: The constraint describing the join.
    /// - Returns: A new select statement that joins the given table.
    @_documentation(visibility: private)
    @_disfavoredOverload
    public func join<each C: QueryRepresentable, F: Table, each J: Table>(
        _ other: some SelectStatement<(repeat each C), F, (repeat each J)>,
        on constraint: (
            (From.TableColumns, F.TableColumns, repeat (each J).TableColumns)
        ) -> some QueryExpression<Bool>
    ) -> Select<(repeat each C), From, (F, repeat each J)>
    where Columns == (), Joins == () {
        let other = other.asSelect()
        let join = _JoinClause(
            operator: nil,
            table: F.self,
            constraint: constraint(
                (From.columns, F.columns, repeat (each J).columns)
            )
        )
        return Select<(repeat each C), From, (F, repeat each J)>(
            isEmpty: isEmpty || other.isEmpty,
            distinct: other.distinct ?? distinct,
            columns: columns + other.columns,
            joins: joins + [join] + other.joins,
            where: `where` + other.where,
            group: group + other.group,
            having: having + other.having,
            order: order + other.order,
            windows: windows + other.windows,
            limit: other.limit ?? limit
        )
    }

    // MARK: SelectOf Specialization - Both Empty (Most Specific)

    /// Creates a new select statement from this one by joining another table.
    ///
    /// Most specific overload for the common case of `SelectOf.join(SelectOf)`.
    /// NOT marked `@_disfavoredOverload` so it's preferred for optimal type inference.
    ///
    /// - Parameters:
    ///   - other: A select statement for another table.
    ///   - constraint: The constraint describing the join.
    /// - Returns: A new select statement that joins the given table.
    @_documentation(visibility: private)
    public func join<F: Table>(
        _ other: some SelectStatementOf<F>,
        on constraint: (
            (From.TableColumns, F.TableColumns)
        ) -> some QueryExpression<Bool>
    ) -> Select<(), From, F>
    where Columns == (), Joins == () {
        let other = other.asSelect()
        let join = _JoinClause(
            operator: nil,
            table: F.self,
            constraint: constraint(
                (From.columns, F.columns)
            )
        )
        return Select<(), From, F>(
            isEmpty: isEmpty || other.isEmpty,
            distinct: other.distinct ?? distinct,
            columns: columns + other.columns,
            joins: joins + [join] + other.joins,
            where: `where` + other.where,
            group: group + other.group,
            having: having + other.having,
            order: order + other.order,
            windows: windows + other.windows,
            limit: other.limit ?? limit
        )
    }

    // MARK: Legacy - Caller Has Joins, Other Is SelectOf

    /// Creates a new select statement from this one by joining another table.
    ///
    /// Legacy overload for when the caller has existing joins but other is SelectOf.
    ///
    /// - Parameters:
    ///   - other: A select statement for another table.
    ///   - constraint: The constraint describing the join.
    /// - Returns: A new select statement that joins the given table.
    @_disfavoredOverload
    @_documentation(visibility: private)
    public func join<F: Table>(
        _ other: some SelectStatementOf<F>,
        on constraint: (
            (From.TableColumns, Joins.TableColumns, F.TableColumns)
        ) -> some QueryExpression<Bool>
    ) -> Select<(), From, (Joins, F)> where Joins: Table {
        let other = other.asSelect()
        let join = _JoinClause(
            operator: .inner,
            table: F.self,
            constraint: constraint(
                (From.columns, Joins.columns, F.columns)
            )
        )
        return Select<(), From, (Joins, F)>(
            isEmpty: isEmpty || other.isEmpty,
            distinct: other.distinct ?? distinct,
            columns: columns + other.columns,
            joins: joins + [join] + other.joins,
            where: `where` + other.where,
            group: group + other.group,
            having: having + other.having,
            order: order + other.order,
            windows: windows + other.windows,
            limit: other.limit ?? limit
        )
    }
}
