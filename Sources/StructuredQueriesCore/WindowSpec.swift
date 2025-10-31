/// Type-safe builder for window specifications (OVER clause)
///
/// Window specifications define how to partition and order data for window functions.
/// This is a database-agnostic type that can be used across different SQL databases.
///
/// ## Example Usage
///
/// ```swift
/// WindowSpec()
///     .partition(by: columns.category)
///     .order(by: columns.price.desc())
/// ```
public struct WindowSpec: Sendable {
  public var partitions: [QueryFragment] = []
  public var orderings: [QueryFragment] = []
  public var frameClause: QueryFragment?

  public init() {}

  public init(
    partitions: [QueryFragment] = [], orderings: [QueryFragment] = [],
    frameClause: QueryFragment? = nil
  ) {
    self.partitions = partitions
    self.orderings = orderings
    self.frameClause = frameClause
  }

  /// Add a partition expression using a single QueryExpression
  public func partition(by expression: some QueryExpression) -> WindowSpec {
    var copy = self
    copy.partitions.append(expression.queryFragment)
    return copy
  }

  /// Add partition expressions using a result builder closure
  public func partition(
    @QueryFragmentBuilder<()>
    by expressions: () -> [QueryFragment]
  ) -> WindowSpec {
    var copy = self
    copy.partitions.append(contentsOf: expressions())
    return copy
  }

  /// Add an ordering expression
  ///
  /// Use `.asc()` or `.desc()` on the expression to specify direction:
  /// ```swift
  /// WindowSpec().order(by: columns.price.desc())
  /// ```
  public func order(
    by expression: some QueryExpression
  ) -> WindowSpec {
    var copy = self
    copy.orderings.append(expression.queryFragment)
    return copy
  }

  /// Add ordering expressions using a result builder closure
  public func order(
    @QueryFragmentBuilder<()>
    by orderings: () -> [QueryFragment]
  ) -> WindowSpec {
    var copy = self
    copy.orderings.append(contentsOf: orderings())
    return copy
  }

  /// Generate the window specification fragment (without "OVER" wrapper)
  /// Used for WINDOW clause definitions
  public func generateSpecificationFragment() -> QueryFragment {
    var fragment: QueryFragment = ""

    if !partitions.isEmpty {
      fragment.append("PARTITION BY ")
      fragment.append(partitions.joined(separator: ", "))
      if !orderings.isEmpty || frameClause != nil {
        fragment.append(" ")
      }
    }

    if !orderings.isEmpty {
      fragment.append("ORDER BY ")
      fragment.append(orderings.joined(separator: ", "))
      if frameClause != nil {
        fragment.append(" ")
      }
    }

    if let frameClause {
      fragment.append(frameClause)
    }

    return fragment
  }

  /// Generate the complete OVER clause SQL (with "OVER" wrapper)
  /// Used for inline window function specifications
  public func generateOverClause() -> QueryFragment {
    var fragment: QueryFragment = "OVER ("

    if !partitions.isEmpty {
      fragment.append("PARTITION BY ")
      fragment.append(partitions.joined(separator: ", "))
      if !orderings.isEmpty {
        fragment.append(" ")
      }
    }

    if !orderings.isEmpty {
      fragment.append("ORDER BY ")
      fragment.append(orderings.joined(separator: ", "))
    }

    if let frameClause {
      if !partitions.isEmpty || !orderings.isEmpty {
        fragment.append(" ")
      }
      fragment.append(frameClause)
    }

    fragment.append(")")
    return fragment
  }
}

/// Order direction for window function ordering
public enum OrderDirection: Sendable {
  case asc
  case desc
}
