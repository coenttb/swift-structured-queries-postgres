import Foundation

/// Namespace for Common Table Expression (CTE) types.
///
/// Common table expressions allow you to factor subqueries or create
/// recursive queries of trees and graphs.
///
/// Use the global ``With`` typealias for cleaner syntax:
///
/// ```swift
/// With {
///     Stats.all
/// } query: {
///     Stats.all
/// }
/// ```
///
/// See <doc:CommonTableExpressions> for more information.
public enum CTE {}

/// A convenient typealias for ``CTE/With``.
///
/// Creates a common table expression for factoring subqueries or recursive queries.
public typealias With = CTE.With
