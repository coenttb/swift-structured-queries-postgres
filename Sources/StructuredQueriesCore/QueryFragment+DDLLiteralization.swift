import Foundation

extension QueryFragment {
    /// Renders this fragment as self-contained SQL text with every bind parameter
    /// literalized in place, for embedding in DDL contexts that cannot accept bind
    /// parameters (for example, `CREATE TRIGGER` `WHEN` clauses and dollar-quoted
    /// PL/pgSQL function bodies).
    ///
    /// PostgreSQL does not substitute bind parameters (`$1`, `$2`, ...) inside DDL —
    /// a placeholder left in a `WHEN` clause or a PL/pgSQL body either fails outright
    /// or, worse, is reinterpreted by PL/pgSQL as a positional argument reference,
    /// silently changing behavior. Routing a fragment through `literalizedForDDL()`
    /// before it is embedded in DDL guarantees every value is rendered as literal SQL
    /// text instead of left as an unresolved binding.
    ///
    /// Each binding is rendered using the same quoting and escaping that
    /// ``QueryBinding/debugDescription`` already applies (single-quote-doubling for
    /// text, `ARRAY[...]` construction for arrays, ISO-8601 for dates, and so on), so
    /// this reuses the exact literal representation already exercised by every SQL
    /// snapshot test in the suite rather than introducing new escaping logic.
    ///
    /// A binding that failed upstream (``QueryBinding/invalid(_:)``) is rendered as
    /// its `<invalid: ...>` debug placeholder, which is not valid PostgreSQL syntax in
    /// any position. This guarantees the resulting DDL fails loudly with a syntax
    /// error at execution time rather than silently embedding an unescaped or
    /// partially-formed value.
    ///
    /// - Returns: A `QueryFragment` containing no `.binding` segments.
    package func literalizedForDDL() -> QueryFragment {
        var result = QueryFragment()
        for segment in segments {
            switch segment {
            case .sql(let sql):
                result.append(QueryFragment(stringLiteral: sql))
            case .binding(let binding):
                result.append(QueryFragment(stringLiteral: binding.debugDescription))
            }
        }
        return result
    }
}
