import Foundation
import StructuredQueriesCore

// MARK: - PostgreSQL Subquery Expressions
//
// PostgreSQL Chapter 9.24: Subquery Expressions
// https://www.postgresql.org/docs/current/functions-subquery.html
//
// Quantified comparison operators for comparing a value against a set of values from a subquery.
// Syntax: expression operator ANY/ALL/SOME (subquery)

/// Namespace for PostgreSQL subquery expression types.
///
/// Contains quantified comparison operators (ANY, ALL, SOME) for subquery operations.
///
/// See <doc:SubqueryExpressions> for more information.
public enum Subquery {}

// MARK: - Convenience Typealiases

/// Convenience typealias for `Subquery.`Any`<Value>`
public typealias SubqueryAny<Value: QueryBindable> = Subquery.`Any`<Value>

/// Convenience typealias for `Subquery.`All`<Value>`
public typealias SubqueryAll<Value: QueryBindable> = Subquery.`All`<Value>

/// Convenience typealias for `Subquery.`Some`<Value>`
public typealias SubquerySome<Value: QueryBindable> = Subquery.`Some`<Value>
