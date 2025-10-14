import StructuredQueriesCore
import StructuredQueriesPostgresSupport

// MARK: - 12.9.5: Manipulating Documents (setweight, length, strip)

// MARK: - Vector Manipulation Functions

extension QueryExpression where QueryValue == String {
    /// Assign a weight label to all positions in a tsvector.
    ///
    /// Weights are used during ranking to give different importance to different
    /// parts of a document (e.g., title vs body).
    ///
    /// ```swift
    /// // Combine weighted title and body
    /// Article.select {
    ///   $0.title.searchVector().weighted(.A)
    ///     .concat($0.body.searchVector().weighted(.B))
    /// }
    /// // SELECT setweight(to_tsvector('english', "title"), 'A') ||
    /// //        setweight(to_tsvector('english', "body"), 'B')
    /// ```
    ///
    /// ## Weight Meanings
    ///
    /// - `.A` - Highest importance (typically titles, headings)
    /// - `.B` - High importance (typically subtitles, emphasized text)
    /// - `.C` - Medium importance (typically abstracts, summaries)
    /// - `.D` - Lowest importance (typically body text, default)
    ///
    /// - Parameter weight: The weight label to assign
    /// - Returns: A tsvector expression with weighted positions
    public func weighted(_ weight: TextSearch.Weight) -> some QueryExpression<String> {
        SQLQueryExpression(
            "setweight(\(self.queryFragment), \(bind: weight.rawValue))",
            as: String.self
        )
    }

    /// The number of lexemes in a tsvector.
    ///
    /// ```swift
    /// Article.select { $0.searchVector.lexemeCount }
    /// // SELECT length("articles"."search_vector")
    /// ```
    public var lexemeCount: some QueryExpression<Int> {
        SQLQueryExpression(
            "length(\(self.queryFragment))",
            as: Int.self
        )
    }

    /// Remove position and weight information from a tsvector.
    ///
    /// Reduces the vector to just lexemes, making it smaller but less useful
    /// for ranking and phrase searches.
    ///
    /// ```swift
    /// Article.select { $0.searchVector.stripped() }
    /// // SELECT strip("articles"."search_vector")
    /// ```
    ///
    /// **Warning**: Stripping removes information needed for:
    /// - Position-based ranking (ts_rank_cd)
    /// - Phrase searches (<-> operator)
    /// - Weighted ranking
    ///
    /// - Returns: A stripped tsvector expression
    public func stripped() -> some QueryExpression<String> {
        SQLQueryExpression(
            "strip(\(self.queryFragment))",
            as: String.self
        )
    }
}
