extension Table {
  /// A where clause filtered by a Boolean key path.
  ///
  /// ```swift
  /// @Table
  /// struct User {
  ///   let id: Int
  ///   var email: String
  /// }
  ///
  /// User.where { $0.id == 1 }
  /// // WHERE ("users"."id" = 1)
  ///
  /// User.where { $0.like("%@pointfree.co") }
  /// // WHERE ("users"."email" LIKE '%@pointfree.co')
  /// ```
  ///
  /// See <doc:WhereClauses> for more.
  ///
  /// - Parameter keyPath: A key path to a Boolean expression to filter by.
  /// - Returns: A `WHERE` clause.
  public static func `where`(
    _ keyPath: KeyPath<TableColumns, some QueryExpression<some _OptionalPromotable<Bool?>>>
  ) -> Where<Self> {
    Where(predicates: [columns[keyPath: keyPath].queryFragment])
  }

  /// A where clause filtered by a predicate expression.
  ///
  /// See <doc:WhereClauses> for more.
  ///
  /// - Parameter predicate: A predicate used to generate the `WHERE` clause.
  /// - Returns: A `WHERE` clause.
  @_disfavoredOverload
  public static func `where`(
    _ predicate: (TableColumns) -> some QueryExpression<some _OptionalPromotable<Bool?>>
  ) -> Where<Self> {
    Where(predicates: [predicate(columns).queryFragment])
  }

  /// A where clause filtered by a predicate expression.
  ///
  /// See <doc:WhereClauses> for more.
  ///
  /// - Parameter predicate: A result builder closure that returns a Boolean expression to filter
  ///   by.
  /// - Returns: A `WHERE` clause.
  public static func `where`(
    @QueryFragmentBuilder<Bool> _ predicate: (TableColumns) -> [QueryFragment]
  ) -> Where<Self> {
    Where(predicates: predicate(columns))
  }
}
