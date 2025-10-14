import Foundation
import StructuredQueriesCore

// MARK: - PostgreSQL Trigonometric Functions
//
// PostgreSQL Chapter 9.3: Mathematical Functions and Operators
// https://www.postgresql.org/docs/18/functions-math.html
//
// Trigonometric functions for sine, cosine, tangent, and their inverses.
// All angle arguments/returns are in radians.

extension QueryExpression where QueryValue == Double {
    // MARK: - Basic Trigonometric Functions

    /// Returns the sine of the value (in radians)
    ///
    /// PostgreSQL's `sin()` function.
    ///
    /// ```swift
    /// Angle.select { $0.radians.sin() }
    /// // SELECT sin("angles"."radians") FROM "angles"
    /// ```
    public func sin() -> some QueryExpression<Double> {
        SQLQueryExpression(
            "sin(\(self.queryFragment))",
            as: Double.self
        )
    }

    /// Returns the cosine of the value (in radians)
    ///
    /// PostgreSQL's `cos()` function.
    ///
    /// ```swift
    /// Angle.select { $0.radians.cos() }
    /// // SELECT cos("angles"."radians") FROM "angles"
    /// ```
    public func cos() -> some QueryExpression<Double> {
        SQLQueryExpression(
            "cos(\(self.queryFragment))",
            as: Double.self
        )
    }

    /// Returns the tangent of the value (in radians)
    ///
    /// PostgreSQL's `tan()` function.
    ///
    /// ```swift
    /// Angle.select { $0.radians.tan() }
    /// // SELECT tan("angles"."radians") FROM "angles"
    /// ```
    public func tan() -> some QueryExpression<Double> {
        SQLQueryExpression(
            "tan(\(self.queryFragment))",
            as: Double.self
        )
    }

    /// Returns the cotangent of the value (in radians)
    ///
    /// PostgreSQL's `cot()` function.
    ///
    /// ```swift
    /// Angle.select { $0.radians.cot() }
    /// // SELECT cot("angles"."radians") FROM "angles"
    /// ```
    public func cot() -> some QueryExpression<Double> {
        SQLQueryExpression(
            "cot(\(self.queryFragment))",
            as: Double.self
        )
    }

    // MARK: - Inverse Trigonometric Functions

    /// Returns the arcsine (inverse sine) in radians
    ///
    /// PostgreSQL's `asin()` function.
    ///
    /// ```swift
    /// Value.select { $0.sinValue.asin() }
    /// // SELECT asin("values"."sinValue") FROM "values"
    /// ```
    ///
    /// - Returns: Result in radians, range [-π/2, π/2]
    public func asin() -> some QueryExpression<Double> {
        SQLQueryExpression(
            "asin(\(self.queryFragment))",
            as: Double.self
        )
    }

    /// Returns the arccosine (inverse cosine) in radians
    ///
    /// PostgreSQL's `acos()` function.
    ///
    /// ```swift
    /// Value.select { $0.cosValue.acos() }
    /// // SELECT acos("values"."cosValue") FROM "values"
    /// ```
    ///
    /// - Returns: Result in radians, range [0, π]
    public func acos() -> some QueryExpression<Double> {
        SQLQueryExpression(
            "acos(\(self.queryFragment))",
            as: Double.self
        )
    }

    /// Returns the arctangent (inverse tangent) in radians
    ///
    /// PostgreSQL's `atan()` function.
    ///
    /// ```swift
    /// Value.select { $0.tanValue.atan() }
    /// // SELECT atan("values"."tanValue") FROM "values"
    /// ```
    ///
    /// - Returns: Result in radians, range [-π/2, π/2]
    public func atan() -> some QueryExpression<Double> {
        SQLQueryExpression(
            "atan(\(self.queryFragment))",
            as: Double.self
        )
    }

    /// Returns the arctangent of y/x in radians
    ///
    /// PostgreSQL's `atan2(y, x)` function.
    ///
    /// ```swift
    /// Point.select { $0.y.atan2($0.x) }
    /// // SELECT atan2("points"."y", "points"."x") FROM "points"
    /// ```
    ///
    /// - Parameter x: The x coordinate
    /// - Returns: Result in radians, range [-π, π]
    ///
    /// > Note: This function properly handles the signs of both arguments
    /// > to determine the quadrant of the result.
    public func atan2(_ x: Double) -> some QueryExpression<Double> {
        SQLQueryExpression(
            "atan2(\(self.queryFragment), \(bind: x))",
            as: Double.self
        )
    }

    /// Returns the arctangent of y/x in radians (expression)
    ///
    /// PostgreSQL's `atan2(y, x)` function.
    ///
    /// ```swift
    /// Point.select { $0.y.atan2($0.x) }
    /// // SELECT atan2("points"."y", "points"."x") FROM "points"
    /// ```
    public func atan2(_ x: some QueryExpression<Double>) -> some QueryExpression<Double> {
        SQLQueryExpression(
            "atan2(\(self.queryFragment), \(x.queryFragment))",
            as: Double.self
        )
    }

    /// Returns the arccotangent (inverse cotangent) in radians
    ///
    /// PostgreSQL's `acot()` function.
    ///
    /// ```swift
    /// Value.select { $0.cotValue.acot() }
    /// // SELECT acot("values"."cotValue") FROM "values"
    /// ```
    ///
    /// - Returns: Result in radians, range [0, π]
    public func acot() -> some QueryExpression<Double> {
        SQLQueryExpression(
            "acot(\(self.queryFragment))",
            as: Double.self
        )
    }

    // MARK: - Hyperbolic Functions

    /// Returns the hyperbolic sine
    ///
    /// PostgreSQL's `sinh()` function.
    ///
    /// ```swift
    /// Value.select { $0.x.sinh() }
    /// // SELECT sinh("values"."x") FROM "values"
    /// ```
    public func sinh() -> some QueryExpression<Double> {
        SQLQueryExpression(
            "sinh(\(self.queryFragment))",
            as: Double.self
        )
    }

    /// Returns the hyperbolic cosine
    ///
    /// PostgreSQL's `cosh()` function.
    ///
    /// ```swift
    /// Value.select { $0.x.cosh() }
    /// // SELECT cosh("values"."x") FROM "values"
    /// ```
    public func cosh() -> some QueryExpression<Double> {
        SQLQueryExpression(
            "cosh(\(self.queryFragment))",
            as: Double.self
        )
    }

    /// Returns the hyperbolic tangent
    ///
    /// PostgreSQL's `tanh()` function.
    ///
    /// ```swift
    /// Value.select { $0.x.tanh() }
    /// // SELECT tanh("values"."x") FROM "values"
    /// ```
    public func tanh() -> some QueryExpression<Double> {
        SQLQueryExpression(
            "tanh(\(self.queryFragment))",
            as: Double.self
        )
    }

    /// Returns the hyperbolic cotangent
    ///
    /// PostgreSQL's `coth()` function.
    ///
    /// ```swift
    /// Value.select { $0.x.coth() }
    /// // SELECT coth("values"."x") FROM "values"
    /// ```
    public func coth() -> some QueryExpression<Double> {
        SQLQueryExpression(
            "coth(\(self.queryFragment))",
            as: Double.self
        )
    }

    // MARK: - Inverse Hyperbolic Functions

    /// Returns the inverse hyperbolic sine
    ///
    /// PostgreSQL's `asinh()` function.
    ///
    /// ```swift
    /// Value.select { $0.x.asinh() }
    /// // SELECT asinh("values"."x") FROM "values"
    /// ```
    public func asinh() -> some QueryExpression<Double> {
        SQLQueryExpression(
            "asinh(\(self.queryFragment))",
            as: Double.self
        )
    }

    /// Returns the inverse hyperbolic cosine
    ///
    /// PostgreSQL's `acosh()` function.
    ///
    /// ```swift
    /// Value.select { $0.x.acosh() }
    /// // SELECT acosh("values"."x") FROM "values"
    /// ```
    public func acosh() -> some QueryExpression<Double> {
        SQLQueryExpression(
            "acosh(\(self.queryFragment))",
            as: Double.self
        )
    }

    /// Returns the inverse hyperbolic tangent
    ///
    /// PostgreSQL's `atanh()` function.
    ///
    /// ```swift
    /// Value.select { $0.x.atanh() }
    /// // SELECT atanh("values"."x") FROM "values"
    /// ```
    public func atanh() -> some QueryExpression<Double> {
        SQLQueryExpression(
            "atanh(\(self.queryFragment))",
            as: Double.self
        )
    }

    /// Returns the inverse hyperbolic cotangent
    ///
    /// PostgreSQL's `acoth()` function.
    ///
    /// ```swift
    /// Value.select { $0.x.acoth() }
    /// // SELECT acoth("values"."x") FROM "values"
    /// ```
    public func acoth() -> some QueryExpression<Double> {
        SQLQueryExpression(
            "acoth(\(self.queryFragment))",
            as: Double.self
        )
    }
}

// MARK: - Secant and Cosecant (Less Common)

extension QueryExpression where QueryValue == Double {
    /// Returns the secant (1/cos)
    ///
    /// PostgreSQL's `sec()` function.
    ///
    /// ```swift
    /// Angle.select { $0.radians.sec() }
    /// // SELECT sec("angles"."radians") FROM "angles"
    /// ```
    public func sec() -> some QueryExpression<Double> {
        SQLQueryExpression(
            "sec(\(self.queryFragment))",
            as: Double.self
        )
    }

    /// Returns the cosecant (1/sin)
    ///
    /// PostgreSQL's `csc()` function.
    ///
    /// ```swift
    /// Angle.select { $0.radians.csc() }
    /// // SELECT csc("angles"."radians") FROM "angles"
    /// ```
    public func csc() -> some QueryExpression<Double> {
        SQLQueryExpression(
            "csc(\(self.queryFragment))",
            as: Double.self
        )
    }

    /// Returns the arcsecant (inverse secant)
    ///
    /// PostgreSQL's `asec()` function.
    ///
    /// ```swift
    /// Value.select { $0.secValue.asec() }
    /// // SELECT asec("values"."secValue") FROM "values"
    /// ```
    public func asec() -> some QueryExpression<Double> {
        SQLQueryExpression(
            "asec(\(self.queryFragment))",
            as: Double.self
        )
    }

    /// Returns the arccosecant (inverse cosecant)
    ///
    /// PostgreSQL's `acsc()` function.
    ///
    /// ```swift
    /// Value.select { $0.cscValue.acsc() }
    /// // SELECT acsc("values"."cscValue") FROM "values"
    /// ```
    public func acsc() -> some QueryExpression<Double> {
        SQLQueryExpression(
            "acsc(\(self.queryFragment))",
            as: Double.self
        )
    }
}
