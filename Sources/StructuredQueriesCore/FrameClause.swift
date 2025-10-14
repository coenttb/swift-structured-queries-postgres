/// Frame bounds for window function frame clauses
///
/// Frame bounds specify the starting or ending point of a window frame.
/// They can be used with ROWS, RANGE, or GROUPS frame types.
///
/// ## Example Usage
///
/// ```swift
/// // Preceding bounds
/// .rows(between: .unboundedPreceding, and: .currentRow)
/// .rows(between: .preceding(3), and: .currentRow)
///
/// // Following bounds
/// .rows(between: .currentRow, and: .following(2))
/// .rows(between: .currentRow, and: .unboundedFollowing)
/// ```
public enum FrameBound: Sendable {
    /// Start of the partition
    case unboundedPreceding

    /// N rows/values/groups before the current row
    case preceding(Int)

    /// The current row
    case currentRow

    /// N rows/values/groups after the current row
    case following(Int)

    /// End of the partition
    case unboundedFollowing

    /// Generate SQL fragment for this frame bound
    internal var queryFragment: QueryFragment {
        switch self {
        case .unboundedPreceding:
            return "UNBOUNDED PRECEDING"
        case .preceding(let offset):
            precondition(offset > 0, "PRECEDING offset must be positive, got \(offset)")
            return "\(raw: String(offset)) PRECEDING"
        case .currentRow:
            return "CURRENT ROW"
        case .following(let offset):
            precondition(offset > 0, "FOLLOWING offset must be positive, got \(offset)")
            return "\(raw: String(offset)) FOLLOWING"
        case .unboundedFollowing:
            return "UNBOUNDED FOLLOWING"
        }
    }
}

/// Frame bounds specification for window functions
///
/// Defines either a BETWEEN...AND range or a shorthand single bound.
public enum FrameBounds: Sendable {
    /// Full BETWEEN...AND specification
    /// - Parameters:
    ///   - start: Starting frame bound
    ///   - end: Ending frame bound
    case between(FrameBound, FrameBound)

    /// Shorthand for BETWEEN <bound> AND CURRENT ROW
    /// - Parameter bound: The starting frame bound (ending is implicitly CURRENT ROW)
    case start(FrameBound)

    /// Generate SQL fragment for these frame bounds
    internal func queryFragment(frameType: String) -> QueryFragment {
        switch self {
        case .between(let start, let end):
            return "\(raw: frameType) BETWEEN \(start.queryFragment) AND \(end.queryFragment)"
        case .start(let bound):
            // Shorthand: ROWS <bound> is same as ROWS BETWEEN <bound> AND CURRENT ROW
            return "\(raw: frameType) \(bound.queryFragment)"
        }
    }
}

// MARK: - WindowSpec Frame Extensions

extension WindowSpec {
    /// Add a ROWS frame clause to this window specification
    ///
    /// ROWS frame type uses physical row positions relative to the current row.
    /// This is the most intuitive frame type for most use cases.
    ///
    /// ## Moving Average Example
    ///
    /// ```swift
    /// Employee.select {
    ///     ($0.name, $0.salary.avg().over {
    ///         $0.partition(by: $0.department)
    ///           .order(by: $0.hireDate)
    ///           .rows(between: .preceding(2), and: .currentRow)
    ///     })
    ///  }
    /// // SQL: AVG(salary) OVER (
    /// //        PARTITION BY department
    /// //        ORDER BY hire_date
    /// //        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    /// //      )
    /// ```
    ///
    /// ## Running Total Example
    ///
    /// ```swift
    /// Employee.select {
    ///     ($0.name, $0.salary.sum().over {
    ///         $0.partition(by: $0.department)
    ///           .order(by: $0.hireDate)
    ///           .rows(between: .unboundedPreceding, and: .currentRow)
    ///     })
    /// }
    /// // SQL: SUM(salary) OVER (
    /// //        PARTITION BY department
    /// //        ORDER BY hire_date
    /// //        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    /// //      )
    /// ```
    ///
    /// - Parameters:
    ///   - start: Starting frame bound
    ///   - end: Ending frame bound
    /// - Returns: A new WindowSpec with the ROWS frame clause
    public func rows(between start: FrameBound, and end: FrameBound) -> WindowSpec {
        var copy = self
        copy.frameClause = FrameBounds.between(start, end).queryFragment(frameType: "ROWS")
        return copy
    }

    /// Add a ROWS frame clause using shorthand syntax
    ///
    /// This is shorthand for ROWS BETWEEN <bound> AND CURRENT ROW.
    ///
    /// ## Example
    ///
    /// ```swift
    /// Employee.select {
    ///     $0.salary.avg().over {
    ///         $0.order(by: $0.hireDate)
    ///           .rows(.preceding(5))
    ///     }
    /// }
    /// // SQL: AVG(salary) OVER (
    /// //        ORDER BY hire_date
    /// //        ROWS 5 PRECEDING
    /// //      )
    /// // Equivalent to: ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
    /// ```
    ///
    /// - Parameter bound: The starting frame bound (ending is implicitly CURRENT ROW)
    /// - Returns: A new WindowSpec with the ROWS frame clause
    public func rows(_ bound: FrameBound) -> WindowSpec {
        var copy = self
        copy.frameClause = FrameBounds.start(bound).queryFragment(frameType: "ROWS")
        return copy
    }

    /// Add a RANGE frame clause to this window specification
    ///
    /// RANGE frame type uses logical value ranges based on the ORDER BY column.
    /// Rows with equal ORDER BY values are treated as peers.
    ///
    /// This is PostgreSQL's default frame type when ORDER BY is specified.
    ///
    /// ## Example
    ///
    /// ```swift
    /// Sales.select {
    ///     ($0.date, $0.amount.sum().over {
    ///         $0.order(by: $0.date)
    ///           .range(between: .unboundedPreceding, and: .currentRow)
    ///     })
    /// }
    /// // SQL: SUM(amount) OVER (
    /// //        ORDER BY date
    /// //        RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    /// //      )
    /// ```
    ///
    /// - Parameters:
    ///   - start: Starting frame bound
    ///   - end: Ending frame bound
    /// - Returns: A new WindowSpec with the RANGE frame clause
    public func range(between start: FrameBound, and end: FrameBound) -> WindowSpec {
        var copy = self
        copy.frameClause = FrameBounds.between(start, end).queryFragment(frameType: "RANGE")
        return copy
    }

    /// Add a RANGE frame clause using shorthand syntax
    ///
    /// This is shorthand for RANGE BETWEEN <bound> AND CURRENT ROW.
    ///
    /// - Parameter bound: The starting frame bound (ending is implicitly CURRENT ROW)
    /// - Returns: A new WindowSpec with the RANGE frame clause
    public func range(_ bound: FrameBound) -> WindowSpec {
        var copy = self
        copy.frameClause = FrameBounds.start(bound).queryFragment(frameType: "RANGE")
        return copy
    }

    /// Add a GROUPS frame clause to this window specification
    ///
    /// GROUPS frame type operates on peer groups - sets of rows with equal ORDER BY values.
    /// This is useful when you want to include or exclude entire groups of tied rows.
    ///
    /// ## Example
    ///
    /// ```swift
    /// Leaderboard.select {
    ///     ($0.player, $0.score, $0.score.count().over {
    ///         $0.order(by: $0.score, .desc)
    ///           .groups(between: .currentRow, and: .unboundedFollowing)
    ///     })
    /// }
    /// // SQL: COUNT(score) OVER (
    /// //        ORDER BY score DESC
    /// //        GROUPS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
    /// //      )
    /// ```
    ///
    /// - Parameters:
    ///   - start: Starting frame bound
    ///   - end: Ending frame bound
    /// - Returns: A new WindowSpec with the GROUPS frame clause
    public func groups(between start: FrameBound, and end: FrameBound) -> WindowSpec {
        var copy = self
        copy.frameClause = FrameBounds.between(start, end).queryFragment(frameType: "GROUPS")
        return copy
    }

    /// Add a GROUPS frame clause using shorthand syntax
    ///
    /// This is shorthand for GROUPS BETWEEN <bound> AND CURRENT ROW.
    ///
    /// - Parameter bound: The starting frame bound (ending is implicitly CURRENT ROW)
    /// - Returns: A new WindowSpec with the GROUPS frame clause
    public func groups(_ bound: FrameBound) -> WindowSpec {
        var copy = self
        copy.frameClause = FrameBounds.start(bound).queryFragment(frameType: "GROUPS")
        return copy
    }
}
