import Foundation
import StructuredQueriesCore

// MARK: - Quantified Comparison Extensions

extension QueryExpression where QueryValue: Comparable & QueryBindable {
  // MARK: - ANY Comparisons

  /// Tests if this value is less than any value in the subquery
  ///
  /// PostgreSQL's `< ANY` operator.
  ///
  /// ```swift
  /// Product.where { $0.price.lessThanAny(competitorPrices) }
  /// // WHERE "products"."price" < ANY (SELECT price FROM competitors)
  /// ```
  public func lessThanAny(_ subquery: some QueryExpression<[QueryValue]>) -> some QueryExpression<
    Bool
  > {
    SQLQueryExpression(
      "(\(self.queryFragment) < ANY (\(subquery.queryFragment)))",
      as: Bool.self
    )
  }

  /// Tests if this value is less than or equal to any value in the subquery
  ///
  /// PostgreSQL's `<= ANY` operator.
  public func lessThanOrEqualToAny(_ subquery: some QueryExpression<[QueryValue]>)
    -> some QueryExpression<Bool>
  {
    SQLQueryExpression(
      "(\(self.queryFragment) <= ANY (\(subquery.queryFragment)))",
      as: Bool.self
    )
  }

  /// Tests if this value is greater than any value in the subquery
  ///
  /// PostgreSQL's `> ANY` operator.
  ///
  /// ```swift
  /// User.where { $0.score.greaterThanAny(benchmarkScores) }
  /// // WHERE "users"."score" > ANY (SELECT score FROM benchmarks)
  /// ```
  public func greaterThanAny(_ subquery: some QueryExpression<[QueryValue]>)
    -> some QueryExpression<Bool>
  {
    SQLQueryExpression(
      "(\(self.queryFragment) > ANY (\(subquery.queryFragment)))",
      as: Bool.self
    )
  }

  /// Tests if this value is greater than or equal to any value in the subquery
  ///
  /// PostgreSQL's `>= ANY` operator.
  public func greaterThanOrEqualToAny(_ subquery: some QueryExpression<[QueryValue]>)
    -> some QueryExpression<Bool>
  {
    SQLQueryExpression(
      "(\(self.queryFragment) >= ANY (\(subquery.queryFragment)))",
      as: Bool.self
    )
  }

  // MARK: - ALL Comparisons

  /// Tests if this value is less than all values in the subquery
  ///
  /// PostgreSQL's `< ALL` operator.
  ///
  /// ```swift
  /// Product.where { $0.price.lessThanAll(competitorPrices) }
  /// // WHERE "products"."price" < ALL (SELECT price FROM competitors)
  /// ```
  public func lessThanAll(_ subquery: some QueryExpression<[QueryValue]>) -> some QueryExpression<
    Bool
  > {
    SQLQueryExpression(
      "(\(self.queryFragment) < ALL (\(subquery.queryFragment)))",
      as: Bool.self
    )
  }

  /// Tests if this value is less than or equal to all values in the subquery
  ///
  /// PostgreSQL's `<= ALL` operator.
  public func lessThanOrEqualToAll(_ subquery: some QueryExpression<[QueryValue]>)
    -> some QueryExpression<Bool>
  {
    SQLQueryExpression(
      "(\(self.queryFragment) <= ALL (\(subquery.queryFragment)))",
      as: Bool.self
    )
  }

  /// Tests if this value is greater than all values in the subquery
  ///
  /// PostgreSQL's `> ALL` operator.
  ///
  /// ```swift
  /// User.where { $0.score.greaterThanAll(teamScores) }
  /// // WHERE "users"."score" > ALL (SELECT score FROM team_members)
  /// ```
  public func greaterThanAll(_ subquery: some QueryExpression<[QueryValue]>)
    -> some QueryExpression<Bool>
  {
    SQLQueryExpression(
      "(\(self.queryFragment) > ALL (\(subquery.queryFragment)))",
      as: Bool.self
    )
  }

  /// Tests if this value is greater than or equal to all values in the subquery
  ///
  /// PostgreSQL's `>= ALL` operator.
  public func greaterThanOrEqualToAll(_ subquery: some QueryExpression<[QueryValue]>)
    -> some QueryExpression<Bool>
  {
    SQLQueryExpression(
      "(\(self.queryFragment) >= ALL (\(subquery.queryFragment)))",
      as: Bool.self
    )
  }

  // MARK: - SOME Comparisons (synonyms for ANY)

  /// Tests if this value is less than some value in the subquery
  ///
  /// PostgreSQL's `< SOME` operator (synonym for `< ANY`).
  public func lessThanSome(_ subquery: some QueryExpression<[QueryValue]>)
    -> some QueryExpression<Bool>
  {
    SQLQueryExpression(
      "(\(self.queryFragment) < SOME (\(subquery.queryFragment)))",
      as: Bool.self
    )
  }

  /// Tests if this value is greater than some value in the subquery
  ///
  /// PostgreSQL's `> SOME` operator (synonym for `> ANY`).
  public func greaterThanSome(_ subquery: some QueryExpression<[QueryValue]>)
    -> some QueryExpression<Bool>
  {
    SQLQueryExpression(
      "(\(self.queryFragment) > SOME (\(subquery.queryFragment)))",
      as: Bool.self
    )
  }
}

// MARK: - Equality Comparisons with Quantifiers

extension QueryExpression where QueryValue: Equatable & QueryBindable {
  /// Tests if this value equals any value in the subquery
  ///
  /// PostgreSQL's `= ANY` operator (equivalent to IN).
  ///
  /// ```swift
  /// User.where { $0.role.equalsAny(adminRoles) }
  /// // WHERE "users"."role" = ANY (SELECT role FROM admin_roles)
  /// ```
  ///
  /// > Note: This is equivalent to using IN, but may be clearer in some contexts.
  public func equalsAny(_ subquery: some QueryExpression<[QueryValue]>) -> some QueryExpression<
    Bool
  > {
    SQLQueryExpression(
      "(\(self.queryFragment) = ANY (\(subquery.queryFragment)))",
      as: Bool.self
    )
  }

  /// Tests if this value does not equal any value in the subquery
  ///
  /// PostgreSQL's `<> ANY` operator.
  ///
  /// ```swift
  /// User.where { $0.status.notEqualsAny(blockedStatuses) }
  /// // WHERE "users"."status" <> ANY (SELECT status FROM blocked_statuses)
  /// ```
  ///
  /// > Note: Returns true if the value differs from at least one value in the subquery.
  public func notEqualsAny(_ subquery: some QueryExpression<[QueryValue]>)
    -> some QueryExpression<Bool>
  {
    SQLQueryExpression(
      "(\(self.queryFragment) <> ANY (\(subquery.queryFragment)))",
      as: Bool.self
    )
  }

  /// Tests if this value equals all values in the subquery
  ///
  /// PostgreSQL's `= ALL` operator.
  ///
  /// ```swift
  /// User.where { $0.permission.equalsAll(requiredPermissions) }
  /// // WHERE "users"."permission" = ALL (SELECT permission FROM required_permissions)
  /// ```
  ///
  /// > Note: Only returns true if all values in the subquery are equal to this value.
  public func equalsAll(_ subquery: some QueryExpression<[QueryValue]>) -> some QueryExpression<
    Bool
  > {
    SQLQueryExpression(
      "(\(self.queryFragment) = ALL (\(subquery.queryFragment)))",
      as: Bool.self
    )
  }

  /// Tests if this value does not equal all values in the subquery
  ///
  /// PostgreSQL's `<> ALL` operator (equivalent to NOT IN).
  ///
  /// ```swift
  /// User.where { $0.role.notEqualsAll(bannedRoles) }
  /// // WHERE "users"."role" <> ALL (SELECT role FROM banned_roles)
  /// ```
  ///
  /// > Note: This is equivalent to using NOT IN.
  public func notEqualsAll(_ subquery: some QueryExpression<[QueryValue]>)
    -> some QueryExpression<Bool>
  {
    SQLQueryExpression(
      "(\(self.queryFragment) <> ALL (\(subquery.queryFragment)))",
      as: Bool.self
    )
  }
}

// MARK: - Convenience Functions

/// Creates an ANY quantifier from a subquery
///
/// ```swift
/// Product.where { $0.price < any(competitorPrices) }
/// // WHERE "products"."price" < ANY (SELECT price FROM competitors)
/// ```
public func any<Value: QueryBindable, Q: QueryExpression>(_ subquery: Q) -> Subquery.`Any`<Value>
where Q.QueryValue == [Value] {
  Subquery.`Any`(subquery)
}

/// Creates an ALL quantifier from a subquery
///
/// ```swift
/// User.where { $0.score > all(teamScores) }
/// // WHERE "users"."score" > ALL (SELECT score FROM team_members)
/// ```
public func all<Value: QueryBindable, Q: QueryExpression>(_ subquery: Q) -> Subquery.`All`<Value>
where Q.QueryValue == [Value] {
  Subquery.`All`(subquery)
}

/// Creates a SOME quantifier from a subquery (synonym for ANY)
///
/// ```swift
/// Product.where { $0.price < some(competitorPrices) }
/// // WHERE "products"."price" < SOME (SELECT price FROM competitors)
/// ```
public func some<Value: QueryBindable, Q: QueryExpression>(_ subquery: Q) -> Subquery.`Some`<Value>
where Q.QueryValue == [Value] {
  Subquery.`Some`(subquery)
}
