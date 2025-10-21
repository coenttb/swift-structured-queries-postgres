import Foundation
import StructuredQueriesCore

// MARK: - Math Namespace
//
// PostgreSQL Chapter 9.3: Mathematical Functions and Operators
// https://www.postgresql.org/docs/current/functions-math.html
//
// This namespace provides type-safe access to PostgreSQL's mathematical functions,
// organized to match the official PostgreSQL documentation structure.
//
// ## Organization
//
// Functions are grouped into categories matching PostgreSQL's Table 9.5-9.8:
//
// - **Rounding**: ceil, floor, round, trunc (Math+Rounding.swift)
// - **Sign Operations**: abs, sign (Math+Sign.swift)
// - **Division**: mod, div (Math+Division.swift)
// - **Number Theory**: gcd, lcm, factorial (Math+NumberTheory.swift)
// - **Comparison**: min, max, least, greatest (Math+Comparison.swift)
// - **Exponential/Logarithmic**: power, sqrt, exp, ln, log (Math+Exponential.swift)
// - **Trigonometric**: sin, cos, tan, asin, acos, atan (Math+Trigonometric.swift)
// - **Random**: random, setseed (Math+Random.swift)
//
// ## Usage
//
// Functions are available in two forms:
//
// ```swift
// // 1. Namespace style (explicit)
// Math.ceil($0.price)
// Math.abs($0.amount)
//
// // 2. Method style (fluent)
// $0.price.ceil()
// $0.amount.abs()
// ```
//
// Both forms generate identical SQL and provide the same type safety.

/// Namespace for PostgreSQL mathematical functions
///
/// Provides type-safe access to PostgreSQL's comprehensive mathematical function library,
/// organized to match the official PostgreSQL documentation (Chapter 9.3).
public enum Math {}
