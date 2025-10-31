import StructuredQueriesCore

// MARK: - 9.4. String Functions and Operators + 9.7. Pattern Matching

extension QueryExpression where QueryValue == String {
  /// Returns an expression that concatenates two string expressions.
  ///
  /// - Parameters:
  ///   - lhs: The first string expression.
  ///   - rhs: The second string expression.
  /// - Returns: An expression concatenating the first expression with the second.
  public static func + (
    lhs: Self,
    rhs: some QueryExpression<QueryValue>
  ) -> some QueryExpression<QueryValue> {
    BinaryOperator(lhs: lhs, operator: "||", rhs: rhs)
  }

  /// Returns an expression of this expression that is compared using the given collating sequence.
  ///
  /// - Parameter collation: A collating sequence name.
  /// - Returns: An expression that is compared using the given collating sequence.
  public func collate(_ collation: Collation) -> some QueryExpression<QueryValue> {
    SQLQueryExpression("\(self) COLLATE \(collation)")
  }

  /// A predicate expression from this string expression matched against another _via_ the `GLOB`
  /// operator.
  ///
  /// ```swift
  /// Asset.where { $0.path.glob("Resources/*.png") }
  /// // SELECT … FROM "assets" WHERE ("assets"."path" GLOB 'Resources/*.png')
  /// ```
  ///
  /// - Parameter pattern: A string expression describing the `GLOB` pattern.
  /// - Returns: A predicate expression.
  public func glob(_ pattern: some StringProtocol) -> some QueryExpression<Bool> {
    BinaryOperator(lhs: self, operator: "GLOB", rhs: "\(pattern)")
  }

  /// A predicate expression from this string expression matched against another _via_ the `LIKE`
  /// operator.
  ///
  /// ```swift
  /// Reminder.where { $0.title.like("%get%") }
  /// // SELECT … FROM "reminders" WHERE ("reminders"."title" LIKE '%get%')
  /// ```
  ///
  /// - Parameters
  ///   - pattern: A string expression describing the `LIKE` pattern.
  ///   - escape: An optional character for the `ESCAPE` clause.
  /// - Returns: A predicate expression.
  public func like(
    _ pattern: some StringProtocol,
    escape: Character? = nil
  ) -> some QueryExpression<Bool> {
    LikeOperator(string: self, pattern: "\(pattern)", escape: escape)
  }

  /// A predicate expression from this string expression matched against another _via_ the `LIKE`
  /// operator given a prefix.
  ///
  /// ```swift
  /// Reminder.where { $0.title.hasPrefix("get") }
  /// // SELECT … FROM "reminders" WHERE ("reminders"."title" LIKE 'get%')
  /// ```
  ///
  /// - Parameter other: A string expression describing the prefix.
  /// - Returns: A predicate expression.
  public func hasPrefix(_ other: some StringProtocol) -> some QueryExpression<Bool> {
    like("\(other)%")
  }

  /// A predicate expression from this string expression matched against another _via_ the `LIKE`
  /// operator given a suffix.
  ///
  /// ```swift
  /// Reminder.where { $0.title.hasSuffix("get") }
  /// // SELECT … FROM "reminders" WHERE ("reminders"."title" LIKE '%get')
  /// ```
  ///
  /// - Parameter other: A string expression describing the suffix.
  /// - Returns: A predicate expression.
  public func hasSuffix(_ other: some StringProtocol) -> some QueryExpression<Bool> {
    like("%\(other)")
  }

  /// A predicate expression from this string expression matched against another _via_ the `LIKE`
  /// operator given an infix.
  ///
  /// ```swift
  /// Reminder.where { $0.title.contains("get") }
  /// // SELECT … FROM "reminders" WHERE ("reminders"."title" LIKE '%get%')
  /// ```
  ///
  /// - Parameter other: A string expression describing the infix.
  /// - Returns: A predicate expression.
  @_disfavoredOverload
  public func contains(_ other: some StringProtocol) -> some QueryExpression<Bool> {
    like("%\(other)%")
  }
}

extension SQLQueryExpression<String> {
  /// Appends a string expression in an update clause.
  ///
  /// Can be used in an `UPDATE` clause to append an existing column:
  ///
  /// ```swift
  /// Reminder.update { $0.title += " 2" }
  /// // UPDATE "reminders" SET "title" = ("reminders"."title" || " 2")
  /// ```
  ///
  /// - Parameters:
  ///   - lhs: The column to append.
  ///   - rhs: The appended text.
  public static func += (
    lhs: inout Self,
    rhs: some QueryExpression<QueryValue>
  ) {
    lhs = Self(lhs + rhs)
  }

  /// Appends this string expression in an update clause.
  ///
  /// An alias for ``+=(_:_:)``.
  ///
  /// - Parameters other: The text to append.
  public mutating func append(_ other: some QueryExpression<QueryValue>) {
    self += other
  }

  /// Appends this string expression in an update clause.
  ///
  /// An alias for ``+=(_:_:)``.
  ///
  /// - Parameters other: The text to append.
  public mutating func append(contentsOf other: some QueryExpression<QueryValue>) {
    self += other
  }
}
