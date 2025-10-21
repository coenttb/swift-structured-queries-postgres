import StructuredQueriesCore

// MARK: - 9.2. Comparison Functions and Operators

extension QueryExpression where QueryValue: QueryRepresentable {
    /// A predicate expression indicating whether two query expressions are equal.
    ///
    /// ```swift
    /// Reminder.where { $0.title == "Buy milk" }
    /// // SELECT … FROM "reminders" WHERE "reminders"."title" = 'Buy milk'
    /// ```
    ///
    /// > Important: Overloaded operators can strain the Swift compiler's type checking ability.
    /// > Consider using ``eq(_:)``, instead.
    ///
    /// - Parameters:
    ///   - lhs: An expression to compare.
    ///   - rhs: Another expression to compare.
    /// - Returns: A predicate expression.
    public static func == (
        lhs: Self,
        rhs: some QueryExpression<QueryValue>
    ) -> some QueryExpression<Bool> {
        lhs.eq(rhs)
    }

    /// A predicate expression indicating whether two query expressions are not equal.
    ///
    /// ```swift
    /// Reminder.where { $0.title != "Buy milk" }
    /// // SELECT … FROM "reminders" WHERE "reminders"."title" <> 'Buy milk'
    /// ```
    ///
    /// > Important: Overloaded operators can strain the Swift compiler's type checking ability.
    /// > Consider using ``neq(_:)``, instead.
    ///
    /// - Parameters:
    ///   - lhs: An expression to compare.
    ///   - rhs: Another expression to compare.
    /// - Returns: A predicate expression.
    public static func != (
        lhs: Self,
        rhs: some QueryExpression<QueryValue>
    ) -> some QueryExpression<Bool> {
        lhs.neq(rhs)
    }

    /// Returns a predicate expression indicating whether two query expressions are equal.
    ///
    /// ```swift
    /// Reminder.where { $0.title.eq("Buy milk") }
    /// // SELECT … FROM "reminders" WHERE "reminders"."title" = 'Buy milk'
    /// ```
    ///
    /// - Parameter other: An expression to compare this one to.
    /// - Returns: A predicate expression.
    public func eq(_ other: some QueryExpression<QueryValue>) -> some QueryExpression<Bool> {
        BinaryOperator(lhs: self, operator: "=", rhs: other)
    }

    /// Returns a predicate expression indicating whether two query expressions are not equal.
    ///
    /// ```swift
    /// Reminder.where { $0.title.neq("Buy milk") }
    /// // SELECT … FROM "reminders" WHERE "reminders"."title" <> 'Buy milk'
    /// ```
    ///
    /// - Parameter other: An expression to compare this one to.
    /// - Returns: A predicate expression.
    public func neq(_ other: some QueryExpression<QueryValue>) -> some QueryExpression<Bool> {
        BinaryOperator(lhs: self, operator: "<>", rhs: other)
    }

    /// Returns a predicate expression indicating whether two query expressions are equal (or are
    /// equal to `NULL`).
    ///
    /// ```swift
    /// Reminder.where { $0.priority.is(nil) }
    /// // SELECT … FROM "reminders" WHERE "reminders"."priority" IS NULL
    /// ```
    ///
    /// - Parameter other: An expression to compare this one to.
    /// - Returns: A predicate expression.
    public func `is`<Other: QueryRepresentable>(
        _ other: some QueryExpression<Other>
    ) -> some QueryExpression<Bool>
    where QueryValue._Optionalized.Wrapped == Other._Optionalized.Wrapped {
        BinaryOperator(lhs: self, operator: "IS", rhs: other)
    }

    /// Returns a predicate expression indicating whether two query expressions are not equal (or are
    /// not equal to `NULL`).
    ///
    /// ```swift
    /// Reminder.where { $0.priority.isNot(nil) }
    /// // SELECT … FROM "reminders" WHERE "reminders"."priority" IS NOT NULL
    /// ```
    ///
    /// - Parameter other: An expression to compare this one to.
    /// - Returns: A predicate expression.
    public func isNot<Other: QueryRepresentable>(
        _ other: some QueryExpression<QueryValue._Optionalized>
    ) -> some QueryExpression<Bool>
    where QueryValue._Optionalized.Wrapped == Other._Optionalized.Wrapped {
        BinaryOperator(lhs: self, operator: "IS NOT", rhs: other)
    }
}

extension QueryExpression where QueryValue: QueryRepresentable & QueryExpression {
    @_documentation(visibility: private)
    public func `is`(
        _ other: _Null<QueryValue>
    ) -> some QueryExpression<Bool> {
        BinaryOperator(lhs: self, operator: "IS", rhs: other)
    }

    @_documentation(visibility: private)
    public func isNot(
        _ other: _Null<QueryValue>
    ) -> some QueryExpression<Bool> {
        BinaryOperator(lhs: self, operator: "IS NOT", rhs: other)
    }
}

// swiftlint:disable:next todo
// TODO: Remove this when we correctly unwrap `TableColumns` in `join` conditions.
extension QueryExpression where QueryValue: QueryRepresentable & _OptionalProtocol {
    @_documentation(visibility: private)
    public func eq(_ other: some QueryExpression<QueryValue.Wrapped>) -> some QueryExpression<Bool>
    {
        BinaryOperator(lhs: self, operator: "=", rhs: other)
    }

    @_documentation(visibility: private)
    public func neq(_ other: some QueryExpression<QueryValue.Wrapped>) -> some QueryExpression<Bool>
    {
        BinaryOperator(lhs: self, operator: "<>", rhs: other)
    }

    @_documentation(visibility: private)
    public func eq(_ other: some QueryExpression<QueryValue>) -> some QueryExpression<Bool> {
        BinaryOperator(lhs: self, operator: "=", rhs: other)
    }

    @_documentation(visibility: private)
    public func neq(_ other: some QueryExpression<QueryValue>) -> some QueryExpression<Bool> {
        BinaryOperator(lhs: self, operator: "<>", rhs: other)
    }

    @_documentation(visibility: private)
    public func `is`(
        _ other: some QueryExpression<QueryValue>
    ) -> some QueryExpression<Bool> {
        BinaryOperator(lhs: self, operator: "IS", rhs: other)
    }

    @_documentation(visibility: private)
    public func isNot(
        _ other: some QueryExpression<QueryValue>
    ) -> some QueryExpression<Bool> {
        BinaryOperator(lhs: self, operator: "IS NOT", rhs: other)
    }

    // MARK: - Comparison Operators with Optional/Non-Optional Support

    @_documentation(visibility: private)
    public func gt(_ other: some QueryExpression<QueryValue.Wrapped>) -> some QueryExpression<Bool> {
        BinaryOperator(lhs: self, operator: ">", rhs: other)
    }

    @_documentation(visibility: private)
    public func lt(_ other: some QueryExpression<QueryValue.Wrapped>) -> some QueryExpression<Bool> {
        BinaryOperator(lhs: self, operator: "<", rhs: other)
    }

    @_documentation(visibility: private)
    public func gte(_ other: some QueryExpression<QueryValue.Wrapped>) -> some QueryExpression<Bool>
    {
        BinaryOperator(lhs: self, operator: ">=", rhs: other)
    }

    @_documentation(visibility: private)
    public func lte(_ other: some QueryExpression<QueryValue.Wrapped>) -> some QueryExpression<Bool>
    {
        BinaryOperator(lhs: self, operator: "<=", rhs: other)
    }

    /// A predicate expression indicating whether an optional value is greater than a non-optional
    /// value.
    ///
    /// This overload enables comparing optional aggregate results with non-optional values:
    /// ```swift
    /// Order.group(by: \.customerID)
    ///   .having { $0.amount.sum() > 1000 }
    /// // SELECT ... HAVING SUM("orders"."amount") > (1000)
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: An optional expression to compare.
    ///   - rhs: A non-optional expression to compare.
    /// - Returns: A predicate expression.
    public static func > (
        lhs: Self,
        rhs: some QueryExpression<QueryValue.Wrapped>
    ) -> some QueryExpression<Bool> {
        lhs.gt(rhs)
    }

    /// A predicate expression indicating whether an optional value is less than a non-optional
    /// value.
    ///
    /// - Parameters:
    ///   - lhs: An optional expression to compare.
    ///   - rhs: A non-optional expression to compare.
    /// - Returns: A predicate expression.
    public static func < (
        lhs: Self,
        rhs: some QueryExpression<QueryValue.Wrapped>
    ) -> some QueryExpression<Bool> {
        lhs.lt(rhs)
    }

    /// A predicate expression indicating whether an optional value is greater than or equal to a
    /// non-optional value.
    ///
    /// - Parameters:
    ///   - lhs: An optional expression to compare.
    ///   - rhs: A non-optional expression to compare.
    /// - Returns: A predicate expression.
    public static func >= (
        lhs: Self,
        rhs: some QueryExpression<QueryValue.Wrapped>
    ) -> some QueryExpression<Bool> {
        lhs.gte(rhs)
    }

    /// A predicate expression indicating whether an optional value is less than or equal to a
    /// non-optional value.
    ///
    /// - Parameters:
    ///   - lhs: An optional expression to compare.
    ///   - rhs: A non-optional expression to compare.
    /// - Returns: A predicate expression.
    public static func <= (
        lhs: Self,
        rhs: some QueryExpression<QueryValue.Wrapped>
    ) -> some QueryExpression<Bool> {
        lhs.lte(rhs)
    }
}

// NB: This overload is required due to an overload resolution bug of 'Updates[dynamicMember:]'.
// swiftlint:disable:next prefer_some_over_any
@_disfavoredOverload
@_documentation(visibility: private)
public func == <QueryValue>(
    lhs: any QueryExpression<QueryValue>,
    rhs: some QueryExpression<QueryValue?>
) -> some QueryExpression<Bool> {
    BinaryOperator(lhs: lhs, operator: isNull(rhs) ? "IS" : "=", rhs: rhs)
}

// NB: This overload is required due to an overload resolution bug of 'Updates[dynamicMember:]'.
// swiftlint:disable:next prefer_some_over_any
@_disfavoredOverload
@_documentation(visibility: private)
public func != <QueryValue>(
    lhs: any QueryExpression<QueryValue>,
    rhs: some QueryExpression<QueryValue?>
) -> some QueryExpression<Bool> {
    BinaryOperator(lhs: lhs, operator: isNull(rhs) ? "IS NOT" : "<>", rhs: rhs)
}

// NB: This overload is required due to an overload resolution bug of 'Updates[dynamicMember:]'.
// swiftlint:disable:next prefer_some_over_any
@_documentation(visibility: private)
@_disfavoredOverload
public func == <QueryValue: _OptionalProtocol>(
    lhs: any QueryExpression<QueryValue>,
    rhs: some QueryExpression<QueryValue.Wrapped>
) -> some QueryExpression<Bool> {
    BinaryOperator(lhs: lhs, operator: "=", rhs: rhs)
}

// NB: This overload is required due to an overload resolution bug of 'Updates[dynamicMember:]'.
// swiftlint:disable:next prefer_some_over_any
@_documentation(visibility: private)
@_disfavoredOverload
public func != <QueryValue: _OptionalProtocol>(
    lhs: any QueryExpression<QueryValue>,
    rhs: some QueryExpression<QueryValue.Wrapped>
) -> some QueryExpression<Bool> {
    BinaryOperator(lhs: lhs, operator: "<>", rhs: rhs)
}

// NB: This overload is required due to an overload resolution bug of 'Updates[dynamicMember:]'.
// swiftlint:disable:next prefer_some_over_any
@_documentation(visibility: private)
public func == <QueryValue: _OptionalProtocol>(
    lhs: any QueryExpression<QueryValue>,
    rhs: some QueryExpression<QueryValue>
) -> some QueryExpression<Bool> {
    BinaryOperator(lhs: lhs, operator: isNull(rhs) ? "IS" : "=", rhs: rhs)
}

// NB: This overload is required due to an overload resolution bug of 'Updates[dynamicMember:]'.
// swiftlint:disable:next prefer_some_over_any
@_documentation(visibility: private)
public func != <QueryValue: _OptionalProtocol>(
    lhs: any QueryExpression<QueryValue>,
    rhs: some QueryExpression<QueryValue>
) -> some QueryExpression<Bool> {
    BinaryOperator(lhs: lhs, operator: isNull(rhs) ? "IS NOT" : "<>", rhs: rhs)
}

// NB: This overload is required due to an overload resolution bug of 'Updates[dynamicMember:]'.
// swiftlint:disable:next prefer_some_over_any
@_documentation(visibility: private)
public func == <QueryValue: QueryBindable>(
    lhs: any QueryExpression<QueryValue>,
    rhs: _Null<QueryValue>
) -> some QueryExpression<Bool> {
    SQLQueryExpression(lhs).is(rhs)
}

// NB: This overload is required due to an overload resolution bug of 'Updates[dynamicMember:]'.
// swiftlint:disable:next prefer_some_over_any
@_documentation(visibility: private)
public func != <QueryValue: QueryBindable>(
    lhs: any QueryExpression<QueryValue>,
    rhs: _Null<QueryValue>
) -> some QueryExpression<Bool> {
    SQLQueryExpression(lhs).isNot(rhs)
}

// Symmetric overloads for when nil is on the LEFT side
// NB: This overload is required due to an overload resolution bug of 'Updates[dynamicMember:]'.
// swiftlint:disable:next prefer_some_over_any
@_documentation(visibility: private)
public func == <QueryValue: QueryBindable>(
    lhs: _Null<QueryValue>,
    rhs: any QueryExpression<QueryValue>
) -> some QueryExpression<Bool> {
    SQLQueryExpression(rhs).is(lhs)
}

// swiftlint:disable:next prefer_some_over_any
@_documentation(visibility: private)
public func != <QueryValue: QueryBindable>(
    lhs: _Null<QueryValue>,
    rhs: any QueryExpression<QueryValue>
) -> some QueryExpression<Bool> {
    SQLQueryExpression(rhs).isNot(lhs)
}

extension QueryExpression where QueryValue: _OptionalPromotable {
    /// Returns a predicate expression indicating whether the value of the first expression is less
    /// than that of the second expression.
    ///
    /// > Important: Overloaded operators can strain the Swift compiler's type checking ability.
    /// > Consider using ``lt(_:)``, instead.
    ///
    /// - Parameters:
    ///   - lhs: An expression to compare.
    ///   - rhs: Another expression to compare.
    /// - Returns: A predicate expression.
    public static func < (
        lhs: Self,
        rhs: some QueryExpression<QueryValue>
    ) -> some QueryExpression<Bool> {
        lhs.lt(rhs)
    }

    /// Returns a predicate expression indicating whether the value of the first expression is greater
    /// than that of the second expression.
    ///
    /// > Important: Overloaded operators can strain the Swift compiler's type checking ability.
    /// > Consider using ``gt(_:)``, instead.
    ///
    /// - Parameters:
    ///   - lhs: An expression to compare.
    ///   - rhs: Another expression to compare.
    /// - Returns: A predicate expression.
    public static func > (
        lhs: Self,
        rhs: some QueryExpression<QueryValue>
    ) -> some QueryExpression<Bool> {
        lhs.gt(rhs)
    }

    /// Returns a predicate expression indicating whether the value of the first expression is less
    /// than or equal to that of the second expression.
    ///
    /// > Important: Overloaded operators can strain the Swift compiler's type checking ability.
    /// > Consider using ``lte(_:)``, instead.
    ///
    /// - Parameters:
    ///   - lhs: An expression to compare.
    ///   - rhs: Another expression to compare.
    /// - Returns: A predicate expression.
    public static func <= (
        lhs: Self,
        rhs: some QueryExpression<QueryValue>
    ) -> some QueryExpression<Bool> {
        lhs.lte(rhs)
    }

    /// Returns a predicate expression indicating whether the value of the first expression is greater
    /// than or equal to that of the second expression.
    ///
    /// > Important: Overloaded operators can strain the Swift compiler's type checking ability.
    /// > Consider using ``gte(_:)``, instead.
    ///
    /// - Parameters:
    ///   - lhs: An expression to compare.
    ///   - rhs: Another expression to compare.
    /// - Returns: A predicate expression.
    public static func >= (
        lhs: Self,
        rhs: some QueryExpression<QueryValue>
    ) -> some QueryExpression<Bool> {
        lhs.gte(rhs)
    }

    /// Returns a predicate expression indicating whether the value of the first expression is less
    /// than that of the second expression.
    ///
    /// - Parameter other: An expression to compare this one to.
    /// - Returns: A predicate expression.
    public func lt(
        _ other: some QueryExpression<QueryValue>
    ) -> some QueryExpression<Bool> {
        BinaryOperator(lhs: self, operator: "<", rhs: other)
    }

    /// Returns a predicate expression indicating whether the value of the first expression is greater
    /// than that of the second expression.
    ///
    /// - Parameter other: An expression to compare this one to.
    /// - Returns: A predicate expression.
    public func gt(
        _ other: some QueryExpression<QueryValue>
    ) -> some QueryExpression<Bool> {
        BinaryOperator(lhs: self, operator: ">", rhs: other)
    }

    /// Returns a predicate expression indicating whether the value of the first expression is less
    /// than or equal to that of the second expression.
    ///
    /// - Parameter other: An expression to compare this one to.
    /// - Returns: A predicate expression.
    public func lte(
        _ other: some QueryExpression<QueryValue>
    ) -> some QueryExpression<Bool> {
        BinaryOperator(lhs: self, operator: "<=", rhs: other)
    }

    /// Returns a predicate expression indicating whether the value of the first expression is greater
    /// than or equal to that of the second expression.
    ///
    /// - Parameter other: An expression to compare this one to.
    /// - Returns: A predicate expression.
    public func gte(
        _ other: some QueryExpression<QueryValue>
    ) -> some QueryExpression<Bool> {
        BinaryOperator(lhs: self, operator: ">=", rhs: other)
    }
}

extension QueryExpression where QueryValue: QueryExpression {
    /// Returns a predicate expression indicating whether the expression is between a lower and upper
    /// bound.
    ///
    /// - Parameters:
    ///   - lowerBound: An expression representing the lower bound.
    ///   - upperBound: An expression representing the upper bound.
    /// - Returns: A predicate expression indicating whether this expression is between the given
    ///   bounds.
    public func between(
        _ lowerBound: some QueryExpression<QueryValue>,
        and upperBound: some QueryExpression<QueryValue>
    ) -> some QueryExpression<Bool> {
        SQLQueryExpression("\(self) BETWEEN \(lowerBound) AND \(upperBound)")
    }
}

extension ClosedRange where Bound: QueryBindable {
    /// Returns a predicate expression indicating whether the given expression is contained within
    /// this range.
    ///
    /// An alias for ``QueryExpression/between(_:and:)``, flipped.
    ///
    /// - Parameter element: An element.
    /// - Returns: A predicate expression indicating whether the given element is between this range's
    ///   bounds.
    public func contains(
        _ element: some QueryExpression<Bound.QueryValue>
    ) -> some QueryExpression<Bool> {
        element.between(lowerBound, and: upperBound)
    }
}
