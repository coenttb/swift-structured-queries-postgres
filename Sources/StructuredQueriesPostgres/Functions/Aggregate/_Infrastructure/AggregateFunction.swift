import StructuredQueriesCore

/// A query expression of an aggregate function.
public struct AggregateFunction<QueryValue>: QueryExpression, Sendable {
  var name: QueryFragment
  var isDistinct: Bool
  var arguments: [QueryFragment]
  var order: QueryFragment?
  var filter: QueryFragment?

  package init(
    _ name: QueryFragment,
    isDistinct: Bool = false,
    _ arguments: [QueryFragment] = [],
    order: QueryFragment? = nil,
    filter: QueryFragment? = nil
  ) {
    self.name = name
    self.isDistinct = isDistinct
    self.arguments = arguments
    self.order = order
    self.filter = filter
  }

  public var queryFragment: QueryFragment {
    var query: QueryFragment = "\(name)("
    if isDistinct {
      query.append("DISTINCT ")
    }
    query.append(arguments.joined(separator: ", "))
    if let order {
      query.append(" ORDER BY \(order)")
    }
    query.append(")")
    if let filter {
      query.append(" FILTER (WHERE \(filter))")
    }
    return query
  }
}
