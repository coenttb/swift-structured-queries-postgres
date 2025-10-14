import Foundation
import StructuredQueriesCore

// MARK: - PostgreSQL Exponential and Logarithmic Functions
//
// PostgreSQL Chapter 9.3: Mathematical Functions and Operators
// https://www.postgresql.org/docs/18/functions-math.html
//
// Functions for exponential, power, square root, and logarithmic operations.

extension QueryExpression where QueryValue: Numeric & QueryBindable {
    /// Returns the value raised to the specified power
    ///
    /// PostgreSQL's `power()` function or `^` operator.
    ///
    /// ```swift
    /// Number.select { $0.base.power(2) }
    /// // SELECT power("numbers"."base", 2) FROM "numbers"
    /// ```
    ///
    /// - Parameter exponent: The exponent
    /// - Returns: The value raised to the power
    public func power(_ exponent: QueryValue) -> some QueryExpression<Double> {
        SQLQueryExpression(
            "power(\(self.queryFragment), \(bind: exponent))",
            as: Double.self
        )
    }

    /// Returns the value raised to the specified power (expression)
    ///
    /// PostgreSQL's `power()` function.
    ///
    /// ```swift
    /// Number.select { $0.base.power($0.exponent) }
    /// // SELECT power("numbers"."base", "numbers"."exponent") FROM "numbers"
    /// ```
    public func power(_ exponent: some QueryExpression<QueryValue>) -> some QueryExpression<Double>
    {
        SQLQueryExpression(
            "power(\(self.queryFragment), \(exponent.queryFragment))",
            as: Double.self
        )
    }

    /// Returns the square root
    ///
    /// PostgreSQL's `sqrt()` function.
    ///
    /// ```swift
    /// Geometry.select { $0.area.sqrt() }
    /// // SELECT sqrt("geometry"."area") FROM "geometry"
    /// ```
    public func sqrt() -> some QueryExpression<Double> {
        SQLQueryExpression(
            "sqrt(\(self.queryFragment))",
            as: Double.self
        )
    }

    /// Returns the cube root
    ///
    /// PostgreSQL's `cbrt()` function.
    ///
    /// ```swift
    /// Volume.select { $0.value.cbrt() }
    /// // SELECT cbrt("volumes"."value") FROM "volumes"
    /// ```
    public func cbrt() -> some QueryExpression<Double> {
        SQLQueryExpression(
            "cbrt(\(self.queryFragment))",
            as: Double.self
        )
    }
}

extension QueryExpression where QueryValue == Double {
    /// Returns e raised to the power of the value
    ///
    /// PostgreSQL's `exp()` function.
    ///
    /// ```swift
    /// Calculation.select { $0.exponent.exp() }
    /// // SELECT exp("calculations"."exponent") FROM "calculations"
    /// ```
    public func exp() -> some QueryExpression<Double> {
        SQLQueryExpression(
            "exp(\(self.queryFragment))",
            as: Double.self
        )
    }

    /// Returns the natural logarithm (base e)
    ///
    /// PostgreSQL's `ln()` function.
    ///
    /// ```swift
    /// Measurement.select { $0.value.ln() }
    /// // SELECT ln("measurements"."value") FROM "measurements"
    /// ```
    public func ln() -> some QueryExpression<Double> {
        SQLQueryExpression(
            "ln(\(self.queryFragment))",
            as: Double.self
        )
    }

    /// Returns the base 10 logarithm
    ///
    /// PostgreSQL's `log()` function (single argument).
    ///
    /// ```swift
    /// Measurement.select { $0.value.log10() }
    /// // SELECT log("measurements"."value") FROM "measurements"
    /// ```
    public func log10() -> some QueryExpression<Double> {
        SQLQueryExpression(
            "log(\(self.queryFragment))",
            as: Double.self
        )
    }

    /// Returns the logarithm to the specified base
    ///
    /// PostgreSQL's `log(b, x)` function.
    ///
    /// ```swift
    /// Measurement.select { $0.value.log(base: 2) }
    /// // SELECT log(2, "measurements"."value") FROM "measurements"
    /// ```
    ///
    /// - Parameter base: The logarithm base
    public func log(base: Double) -> some QueryExpression<Double> {
        SQLQueryExpression(
            "log(\(bind: base), \(self.queryFragment))",
            as: Double.self
        )
    }

    /// Returns the base 2 logarithm
    ///
    /// PostgreSQL's `log2()` function.
    ///
    /// ```swift
    /// Bits.select { $0.value.log2() }
    /// // SELECT log2("bits"."value") FROM "bits"
    /// ```
    public func log2() -> some QueryExpression<Double> {
        SQLQueryExpression(
            "log2(\(self.queryFragment))",
            as: Double.self
        )
    }
}

// MARK: - Factorial

extension QueryExpression where QueryValue == Int {
    /// Returns the factorial
    ///
    /// PostgreSQL's `factorial()` function.
    ///
    /// ```swift
    /// Number.select { $0.value.factorial() }
    /// // SELECT factorial("numbers"."value") FROM "numbers"
    /// ```
    ///
    /// > Note: PostgreSQL also supports the `!` postfix operator for factorial,
    /// > but this function syntax is more explicit.
    public func factorial() -> some QueryExpression<Int> {
        SQLQueryExpression(
            "factorial(\(self.queryFragment))",
            as: Int.self
        )
    }
}

// MARK: - Random Functions

/// Returns a random value between 0.0 and 1.0
///
/// PostgreSQL's `random()` function.
///
/// ```swift
/// Post.select { random() }
/// // SELECT random() FROM "posts"
/// ```
///
/// > Note: This generates a new random value for each row.
public func random() -> some QueryExpression<Double> {
    SQLQueryExpression("random()", as: Double.self)
}

/// Sets the seed for subsequent `random()` calls
///
/// PostgreSQL's `setseed()` function.
///
/// ```swift
/// // Set seed for reproducible random sequences
/// setseed(0.5)
/// // SELECT setseed(0.5)
/// ```
///
/// - Parameter seed: A value between -1.0 and 1.0
///
/// > Note: This affects the session's random number generator state.
/// > Useful for reproducible test data.
public func setseed(_ seed: Double) -> some QueryExpression<Void> {
    SQLQueryExpression("setseed(\(bind: seed))", as: Void.self)
}

// MARK: - Scale and Precision

extension QueryExpression where QueryValue: Numeric & QueryBindable {
    /// Returns the minimum scale (number of decimal digits) needed to represent the value
    ///
    /// PostgreSQL's `min_scale()` function.
    ///
    /// ```swift
    /// Decimal.select { $0.value.minScale() }
    /// // SELECT min_scale("decimals"."value") FROM "decimals"
    /// ```
    public func minScale() -> some QueryExpression<Int> {
        SQLQueryExpression(
            "min_scale(\(self.queryFragment))",
            as: Int.self
        )
    }

    /// Reduces the scale by removing trailing zeroes
    ///
    /// PostgreSQL's `trim_scale()` function.
    ///
    /// ```swift
    /// Decimal.select { $0.value.trimScale() }
    /// // SELECT trim_scale("decimals"."value") FROM "decimals"
    /// ```
    public func trimScale() -> some QueryExpression<QueryValue> {
        SQLQueryExpression(
            "trim_scale(\(self.queryFragment))",
            as: QueryValue.self
        )
    }
}

// MARK: - Degrees and Radians

extension QueryExpression where QueryValue == Double {
    /// Converts radians to degrees
    ///
    /// PostgreSQL's `degrees()` function.
    ///
    /// ```swift
    /// Angle.select { $0.radians.degrees() }
    /// // SELECT degrees("angles"."radians") FROM "angles"
    /// ```
    public func degrees() -> some QueryExpression<Double> {
        SQLQueryExpression(
            "degrees(\(self.queryFragment))",
            as: Double.self
        )
    }

    /// Converts degrees to radians
    ///
    /// PostgreSQL's `radians()` function.
    ///
    /// ```swift
    /// Angle.select { $0.degrees.radians() }
    /// // SELECT radians("angles"."degrees") FROM "angles"
    /// ```
    public func radians() -> some QueryExpression<Double> {
        SQLQueryExpression(
            "radians(\(self.queryFragment))",
            as: Double.self
        )
    }
}

// MARK: - Pi Constant

/// Returns the constant π (pi)
///
/// PostgreSQL's `pi()` function.
///
/// ```swift
/// Circle.select { pi() * $0.radius.power(2) }
/// // SELECT pi() * power("circles"."radius", 2) FROM "circles"
/// ```
public func pi() -> some QueryExpression<Double> {
    SQLQueryExpression("pi()", as: Double.self)
}
