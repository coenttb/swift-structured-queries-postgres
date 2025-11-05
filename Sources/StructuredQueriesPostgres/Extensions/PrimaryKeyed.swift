import StructuredQueriesCore

// MARK: - Convenience Extensions Using Operators and Aggregates

extension PrimaryKeyedTableDefinition where PrimaryColumn: TableColumnExpression {
    /// A query expression representing the number of rows in this table.
    ///
    /// - Parameters:
    ///   - isDistinct: Whether or not to include a `DISTINCT` clause, which filters duplicates from
    ///     the aggregation.
    ///   - filter: A `FILTER` clause to apply to the aggregation.
    /// - Returns: An expression representing the number of rows in this table.
    public func count(
        distinct isDistinct: Bool = false,
        filter: (some QueryExpression<Bool>)? = Bool?.none
    ) -> some QueryExpression<Int> {
        primaryKey.count(distinct: isDistinct, filter: filter)
    }
}

extension PrimaryKeyedTable {
    /// A where clause filtered by a primary key.
    ///
    /// - Parameter primaryKey: A primary key identifying a table row.
    /// - Returns: A `WHERE` clause.
    public static func find(
        _ primaryKey: some QueryExpression<PrimaryKey>
    ) -> Where<Self> {
        find([primaryKey])
    }

    /// A where clause filtered by primary keys.
    ///
    /// - Parameter primaryKey: Primary keys identifying table rows.
    /// - Returns: A `WHERE` clause.
    public static func find(
        _ primaryKeys: some Sequence<some QueryExpression<PrimaryKey>>
    ) -> Where<Self> {
        Self.where { $0.primaryKey.in(primaryKeys) }
    }

    public var primaryKey: PrimaryKey.QueryOutput {
        self[keyPath: Self.columns.primaryKey.keyPath]
    }
}

extension TableDraft {
    /// A where clause filtered by a primary key.
    ///
    /// - Parameter primaryKey: A primary key identifying a table row.
    /// - Returns: A `WHERE` clause.
    public static func find(
        _ primaryKey: some QueryExpression<PrimaryKey>
    ) -> Where<Self> {
        find([primaryKey])
    }

    /// A where clause filtered by primary keys.
    ///
    /// - Parameter primaryKeys: Primary keys identifying table rows.
    /// - Returns: A `WHERE` clause.
    public static func find(
        _ primaryKeys: some Sequence<some QueryExpression<PrimaryKey>>
    ) -> Where<Self> {
        Self.where { $0.primaryKey.in(primaryKeys) }
    }
}

extension Where where From: PrimaryKeyedTable {
    /// Adds a primary key condition to a where clause.
    ///
    /// - Parameter primaryKey: A primary key.
    /// - Returns: A where clause with the added primary key.
    public func find(_ primaryKey: some QueryExpression<From.PrimaryKey>) -> Self {
        find([primaryKey])
    }

    /// Adds a primary key condition to a where clause.
    ///
    /// - Parameter primaryKeys: A sequence of primary keys.
    /// - Returns: A where clause with the added primary keys condition.
    public func find(
        _ primaryKeys: some Sequence<some QueryExpression<From.PrimaryKey>>
    ) -> Self {
        Self.where { $0.primaryKey.in(primaryKeys) }
    }
}

extension Where where From: TableDraft {
    /// Adds a primary key condition to a where clause.
    ///
    /// - Parameter primaryKey: A primary key.
    /// - Returns: A where clause with the added primary key.
    public func find(_ primaryKey: some QueryExpression<From.PrimaryKey>)
        -> Self
    {
        find([primaryKey])
    }

    /// Adds a primary key condition to a where clause.
    ///
    /// - Parameter primaryKeys: A sequence of primary keys.
    /// - Returns: A where clause with the added primary keys condition.
    public func find(
        _ primaryKeys: some Sequence<some QueryExpression<From.PrimaryKey>>
    ) -> Self {
        Self.where { $0.primaryKey.in(primaryKeys) }
    }
}

extension Select where From: PrimaryKeyedTable {
    /// A select statement filtered by a primary key.
    ///
    /// - Parameter primaryKey: A primary key identifying a table row.
    /// - Returns: A select statement filtered by the given key.
    public func find(_ primaryKey: some QueryExpression<From.PrimaryKey>) -> Self {
        and(From.find(primaryKey))
    }

    /// A select statement filtered by a sequence of primary keys.
    ///
    /// - Parameter primaryKeys: A sequence of primary keys.
    /// - Returns: A select statement filtered by the given keys.
    public func find(
        _ primaryKeys: some Sequence<some QueryExpression<From.PrimaryKey>>
    ) -> Self {
        and(From.find(primaryKeys))
    }
}

extension Select where From: TableDraft {
    /// A select statement filtered by a primary key.
    ///
    /// - Parameter primaryKey: A primary key identifying a table row.
    /// - Returns: A select statement filtered by the given key.
    public func find(
        _ primaryKey: some QueryExpression<From.PrimaryKey>
    ) -> Self {
        and(From.find(primaryKey))
    }

    /// A select statement filtered by a sequence of primary keys.
    ///
    /// - Parameter primaryKeys: A sequence of primary keys.
    /// - Returns: A select statement filtered by the given keys.
    public func find(
        _ primaryKeys: some Sequence<some QueryExpression<From.PrimaryKey>>
    ) -> Self {
        and(From.find(primaryKeys))
    }
}

extension Update where From: PrimaryKeyedTable {
    /// An update statement filtered by a primary key.
    ///
    /// - Parameter primaryKey: A primary key identifying a table row.
    /// - Returns: An update statement filtered by the given key.
    public func find(_ primaryKey: some QueryExpression<From.PrimaryKey>) -> Self {
        find([primaryKey])
    }

    /// An update statement filtered by a sequence of primary keys.
    ///
    /// - Parameter primaryKeys: A sequence of primary keys.
    /// - Returns: An update statement filtered by the given keys.
    public func find(
        _ primaryKeys: some Sequence<some QueryExpression<From.PrimaryKey>>
    ) -> Self {
        self.where { $0.primaryKey.in(primaryKeys) }
    }
}

extension Update where From: TableDraft {
    /// An update statement filtered by a primary key.
    ///
    /// - Parameter primaryKey: A primary key identifying a table row.
    /// - Returns: An update statement filtered by the given key.
    public func find(_ primaryKey: some QueryExpression<From.PrimaryKey>)
        -> Self
    {
        find([primaryKey])
    }

    /// An update statement filtered by a sequence of primary keys.
    ///
    /// - Parameter primaryKeys: A sequence of primary keys.
    /// - Returns: An update statement filtered by the given keys.
    public func find(
        _ primaryKeys: some Sequence<some QueryExpression<From.PrimaryKey>>
    ) -> Self {
        self.where { $0.primaryKey.in(primaryKeys) }
    }
}

extension Delete where From: PrimaryKeyedTable {
    /// A delete statement filtered by a primary key.
    ///
    /// - Parameter primaryKey: A primary key identifying a table row.
    /// - Returns: A delete statement filtered by the given key.
    public func find(_ primaryKey: some QueryExpression<From.PrimaryKey>) -> Self {
        find([primaryKey])
    }

    /// A delete statement filtered by a sequence of primary keys.
    ///
    /// - Parameter primaryKeys: A sequence of primary keys.
    /// - Returns: A delete statement filtered by the given keys.
    public func find(
        _ primaryKeys: some Sequence<some QueryExpression<From.PrimaryKey>>
    ) -> Self {
        self.where { $0.primaryKey.in(primaryKeys) }
    }
}

extension Delete where From: TableDraft {
    /// A delete statement filtered by a primary key.
    ///
    /// - Parameter primaryKey: A primary key identifying a table row.
    /// - Returns: A delete statement filtered by the given key.
    public func find(_ primaryKey: some QueryExpression<From.PrimaryKey>)
        -> Self
    {
        find([primaryKey])
    }

    /// A delete statement filtered by a sequence of primary keys.
    ///
    /// - Parameter primaryKeys: A sequence of primary keys.
    /// - Returns: A delete statement filtered by the given keys.
    public func find(
        _ primaryKeys: some Sequence<some QueryExpression<From.PrimaryKey>>
    ) -> Self {
        self.where { $0.primaryKey.in(primaryKeys) }
    }
}
