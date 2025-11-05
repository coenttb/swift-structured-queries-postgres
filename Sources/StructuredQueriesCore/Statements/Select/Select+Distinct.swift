extension Select {
    /// Creates a new select statement from this one by setting its distinct clause.
    ///
    /// - Parameter isDistinct: Whether or not to `SELECT DISTINCT`.
    /// - Returns: A new select statement with a `DISTINCT` clause determined by `isDistinct`.
    public func distinct(_ isDistinct: Bool = true) -> Self {
        var select = self
        select.distinct = isDistinct ? .all : nil
        return select
    }

    /// Creates a new select statement from this one by setting its `DISTINCT ON` clause.
    ///
    /// PostgreSQL-specific feature that returns the first row of each group determined by the
    /// given expressions. Requires an `ORDER BY` clause to determine which row is "first".
    ///
    /// Example:
    /// ```swift
    /// WeatherReport
    ///     .distinct(on: { $0.location })
    ///     .order { ($0.location, $0.time.desc()) }
    ///     .select { ($0.location, $0.time, $0.report) }
    /// // SELECT DISTINCT ON (location) location, time, report
    /// // FROM weather_reports
    /// // ORDER BY location, time DESC
    /// ```
    ///
    /// - Parameter on: A result builder closure that returns expressions to use for determining distinct groups.
    /// - Returns: A new select statement with a `DISTINCT ON` clause.
    public func distinct(
        @QueryFragmentBuilder<()>
        on expressions: (From.TableColumns) -> [QueryFragment]
    ) -> Self where Joins == () {
        var select = self
        select.distinct = .on(expressions(From.columns))
        return select
    }

    /// Creates a new select statement from this one by setting its `DISTINCT ON` clause with joins.
    ///
    /// PostgreSQL-specific feature that returns the first row of each group determined by the
    /// given expressions. Requires an `ORDER BY` clause to determine which row is "first".
    ///
    /// - Parameter on: A result builder closure that returns expressions from joined tables.
    /// - Returns: A new select statement with a `DISTINCT ON` clause.
    public func distinct<each J: Table>(
        @QueryFragmentBuilder<()>
        on expressions: (From.TableColumns, repeat (each J).TableColumns) -> [QueryFragment]
    ) -> Self where Joins == (repeat each J) {
        var select = self
        select.distinct = .on(expressions(From.columns, repeat (each J).columns))
        return select
    }

    /// Creates a new select statement from this one by setting its `DISTINCT ON` clause with joins (single join).
    ///
    /// - Parameter on: A result builder closure that returns expressions from joined tables.
    /// - Returns: A new select statement with a `DISTINCT ON` clause.
    public func distinct(
        @QueryFragmentBuilder<()>
        on expressions: (From.TableColumns, Joins.TableColumns) -> [QueryFragment]
    ) -> Self where Joins: Table {
        var select = self
        select.distinct = .on(expressions(From.columns, Joins.columns))
        return select
    }
}
