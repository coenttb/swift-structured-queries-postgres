import StructuredQueriesCore

// MARK: - 9.3. Mathematical Functions and Operators

extension QueryExpression where QueryValue: Numeric {
    /// Returns a sum expression that adds two expressions.
    ///
    /// - Parameters:
    ///   - lhs: The first expression to add.
    ///   - rhs: The second expression to add.
    /// - Returns: A sum expression.
    public static func + (
        lhs: Self,
        rhs: some QueryExpression<QueryValue>
    ) -> some QueryExpression<QueryValue> {
        BinaryOperator(lhs: lhs, operator: "+", rhs: rhs)
    }

    /// Returns a difference expression that subtracts two expressions.
    ///
    /// - Parameters:
    ///   - lhs: The first expression to subtract.
    ///   - rhs: The second expression to subtract.
    /// - Returns: A difference expression.
    public static func - (
        lhs: Self,
        rhs: some QueryExpression<QueryValue>
    ) -> some QueryExpression<QueryValue> {
        BinaryOperator(lhs: lhs, operator: "-", rhs: rhs)
    }

    /// Returns a product expression that multiplies two expressions.
    ///
    /// - Parameters:
    ///   - lhs: The first expression to multiply.
    ///   - rhs: The second expression to multiply.
    /// - Returns: A product expression.
    public static func * (
        lhs: Self,
        rhs: some QueryExpression<QueryValue>
    ) -> some QueryExpression<QueryValue> {
        BinaryOperator(lhs: lhs, operator: "*", rhs: rhs)
    }

    /// Returns a quotient expression that divides two expressions.
    ///
    /// - Parameters:
    ///   - lhs: The first expression to divide.
    ///   - rhs: The second expression to divide.
    /// - Returns: A quotient expression.
    public static func / (
        lhs: Self,
        rhs: some QueryExpression<QueryValue>
    ) -> some QueryExpression<QueryValue> {
        BinaryOperator(lhs: lhs, operator: "/", rhs: rhs)
    }

    /// Returns the additive inverse of the specified expression.
    ///
    /// - Parameter expression: A numeric expression.
    /// - Returns: the additive inverse of this expression
    public static prefix func - (expression: Self) -> some QueryExpression<QueryValue> {
        UnaryOperator(operator: "-", base: expression, separator: "")
    }

    /// Returns the additive equivalent to the specified expression.
    ///
    /// - Parameter expression: A numeric expression.
    /// - Returns: the additive equivalent to this expression
    public static prefix func + (expression: Self) -> some QueryExpression<QueryValue> {
        UnaryOperator(operator: "+", base: expression, separator: "")
    }
}

// NB: Testing if overload resolution bug is fixed - changed 'any' to 'some'
@_documentation(visibility: private)
public prefix func - <QueryValue: Numeric>(
    expression: some QueryExpression<QueryValue>
) -> some QueryExpression<QueryValue> {
    SQLQueryExpression(UnaryOperator(operator: "-", base: expression, separator: ""))
}

// NB: Testing if overload resolution bug is fixed - changed 'any' to 'some'
@_documentation(visibility: private)
public prefix func + <QueryValue: Numeric>(
    expression: some QueryExpression<QueryValue>
) -> some QueryExpression<QueryValue> {
    SQLQueryExpression(UnaryOperator(operator: "+", base: expression, separator: ""))
}

extension SQLQueryExpression where QueryValue: Numeric {
    /// Adds to a numeric expression in an update clause.
    ///
    /// - Parameters:
    ///   - lhs: The column to add to.
    ///   - rhs: The expression to add.
    public static func += (lhs: inout Self, rhs: some QueryExpression<QueryValue>) {
        lhs = Self(lhs + rhs)
    }

    /// Subtracts from a numeric expression in an update clause.
    ///
    /// - Parameters:
    ///   - lhs: The column to subtract from.
    ///   - rhs: The expression to subtract.
    public static func -= (lhs: inout Self, rhs: some QueryExpression<QueryValue>) {
        lhs = Self(lhs - rhs)
    }

    /// Multiplies a numeric expression in an update clause.
    ///
    /// - Parameters:
    ///   - lhs: The column to multiply.
    ///   - rhs: The expression multiplier.
    public static func *= (lhs: inout Self, rhs: some QueryExpression<QueryValue>) {
        lhs = Self(lhs * rhs)
    }

    /// Divides a numeric expression in an update clause.
    ///
    /// - Parameters:
    ///   - lhs: The column to divide.
    ///   - rhs: The expression divisor.
    public static func /= (lhs: inout Self, rhs: some QueryExpression<QueryValue>) {
        lhs = Self(lhs / rhs)
    }

    /// Negates a numeric expression in an update clause.
    public mutating func negate() {
        self = Self(-self)
    }
}

extension QueryExpression where QueryValue: BinaryInteger {
    /// Returns the remainder expression of dividing the first expression by the second.
    ///
    /// - Parameters:
    ///   - lhs: The expression to divide.
    ///   - rhs: The value to divide `lhs` by.
    /// - Returns: An expression representing the remainder, or `NULL` if `rhs` is zero.
    public static func % (
        lhs: Self,
        rhs: some QueryExpression<QueryValue>
    ) -> some QueryExpression<QueryValue?> {
        BinaryOperator(lhs: lhs, operator: "%", rhs: rhs)
    }

    /// Returns the expression of performing a bitwise AND operation on the two given expressions.
    ///
    /// - Parameters:
    ///   - lhs: An integer expression.
    ///   - rhs: Another integer expression.
    /// - Returns: An expression representing a bitwise AND operation on the two given expressions.
    public static func & (
        lhs: Self,
        rhs: some QueryExpression<QueryValue>
    ) -> some QueryExpression<QueryValue> {
        BinaryOperator(lhs: lhs, operator: "&", rhs: rhs)
    }

    /// Returns the expression of performing a bitwise OR operation on the two given expressions.
    ///
    /// - Parameters:
    ///   - lhs: An integer expression.
    ///   - rhs: Another integer expression.
    /// - Returns: An expression representing a bitwise OR operation on the two given expressions.
    public static func | (
        lhs: Self,
        rhs: some QueryExpression<QueryValue>
    ) -> some QueryExpression<QueryValue> {
        BinaryOperator(lhs: lhs, operator: "|", rhs: rhs)
    }

    /// Returns an expression representing the result of shifting an expression's binary
    /// representation the specified expression of digits to the left.
    ///
    /// - Parameters:
    ///   - lhs: An integer expression.
    ///   - rhs: Another integer expression.
    /// - Returns: An expression representing a left bitshift operation on the two given expressions.
    public static func << (
        lhs: Self,
        rhs: some QueryExpression<QueryValue>
    ) -> some QueryExpression<QueryValue> {
        BinaryOperator(lhs: lhs, operator: "<<", rhs: rhs)
    }

    /// Returns an expression representing the result of shifting an expression's binary
    /// representation the specified expression of digits to the right.
    ///
    /// - Parameters:
    ///   - lhs: An integer expression.
    ///   - rhs: Another integer expression.
    /// - Returns: An expression representing a right bitshift operation on the two given expressions.
    public static func >> (
        lhs: Self,
        rhs: some QueryExpression<QueryValue>
    ) -> some QueryExpression<QueryValue> {
        BinaryOperator(lhs: lhs, operator: ">>", rhs: rhs)
    }

    /// Returns the inverse expression of the bits set in the argument.
    ///
    /// - Parameter expression: An integer expression.
    /// - Returns: An expression representing the inverse bits of the given expression.
    public static prefix func ~ (expression: Self) -> some QueryExpression<QueryValue> {
        UnaryOperator(operator: "~", base: expression, separator: "")
    }
}

// NB: Testing if overload resolution bug is fixed - changed 'any' to 'some'
@_documentation(visibility: private)
public prefix func ~ <QueryValue: BinaryInteger>(
    expression: some QueryExpression<QueryValue>
) -> some QueryExpression<QueryValue> {
    SQLQueryExpression(UnaryOperator(operator: "~", base: expression, separator: ""))
}

extension SQLQueryExpression where QueryValue: BinaryInteger {
    public static func &= (lhs: inout Self, rhs: some QueryExpression<QueryValue>) {
        lhs = Self(lhs & rhs)
    }

    public static func |= (lhs: inout Self, rhs: some QueryExpression<QueryValue>) {
        lhs = Self(lhs | rhs)
    }

    public static func <<= (lhs: inout Self, rhs: some QueryExpression<QueryValue>) {
        lhs = Self(lhs << rhs)
    }

    public static func >>= (lhs: inout Self, rhs: some QueryExpression<QueryValue>) {
        lhs = Self(lhs >> rhs)
    }
}
