import StructuredQueriesCore

// MARK: - 12.9.3: Ranking Search Results (ts_rank, ts_rank_cd)

extension TableDefinition where QueryValue: FullTextSearchable {
  /// An expression representing the search result's relevance rank.
  ///
  /// Uses PostgreSQL's `ts_rank()` function to calculate relevance score.
  /// Higher scores indicate better matches.
  ///
  /// ```swift
  /// Article.where { $0.match("swift") }
  ///   .select { ($0, $0.rank(by: "swift")) }
  ///   .order(by: \.1.desc())
  /// // SELECT *, ts_rank("searchVector", to_tsquery('english', 'swift'))
  /// // FROM "articles"
  /// // WHERE "articles"."searchVector" @@ to_tsquery('english', 'swift')
  /// // ORDER BY ts_rank(...) DESC
  /// ```
  ///
  /// ## Normalization
  ///
  /// The `normalization` parameter controls how document length affects ranking:
  ///
  /// ```swift
  /// Article.rank(by: "swift", normalization: .divideByLogLength)
  /// Article.rank(by: "swift", normalization: [.divideByLogLength, .divideByUniqueWordCount])
  /// ```
  ///
  /// - Parameters:
  ///   - query: The tsquery string to rank against
  ///   - language: Text search configuration (default: "english")
  ///   - normalization: Normalization options (default: .none)
  /// - Returns: A numeric expression representing relevance score
  public func rank(
    by query: some StringProtocol,
    language: String = "english",
    normalization: TextSearch.RankNormalization = .none
  ) -> some QueryExpression<Double> {
    var fragment: QueryFragment = "ts_rank("
    fragment.append("\(quote: QueryValue.tableName).\(quote: QueryValue.searchVectorColumn), ")
    fragment.append(
      "to_tsquery(\(raw: language.quoted(.text))::regconfig, \(bind: "\(query)"))")
    if normalization != .none {
      fragment.append(", \(raw: String(normalization.rawValue))")
    }
    fragment.append(")")
    return SQLQueryExpression(fragment, as: Double.self)
  }

  /// An expression representing the search result's coverage-based rank.
  ///
  /// Uses `ts_rank_cd()` which considers proximity and coverage of query terms.
  /// Generally produces better results than `ts_rank()` for phrase searches.
  ///
  /// ```swift
  /// Article.where { $0.match("quick <-> brown <-> fox") }
  ///   .select { ($0, $0.rank(byCoverage: "quick <-> brown <-> fox")) }
  ///   .order(by: \.1.desc())
  /// ```
  ///
  /// - Parameters:
  ///   - query: The tsquery string to rank against
  ///   - language: Text search configuration (default: "english")
  ///   - normalization: Normalization options (default: .none)
  /// - Returns: A numeric expression representing coverage-based rank
  public func rank(
    byCoverage query: some StringProtocol,
    language: String = "english",
    normalization: TextSearch.RankNormalization = .none
  ) -> some QueryExpression<Double> {
    var fragment: QueryFragment = "ts_rank_cd("
    fragment.append("\(quote: QueryValue.tableName).\(quote: QueryValue.searchVectorColumn), ")
    fragment.append(
      "to_tsquery(\(raw: language.quoted(.text))::regconfig, \(bind: "\(query)"))")
    if normalization != .none {
      fragment.append(", \(raw: String(normalization.rawValue))")
    }
    fragment.append(")")
    return SQLQueryExpression(fragment, as: Double.self)
  }

  /// An expression representing the search result's weighted relevance rank.
  ///
  /// Uses PostgreSQL's `ts_rank()` with weight array for per-position weighting.
  /// Weights correspond to D, C, B, A positions in that order.
  ///
  /// ```swift
  /// // Weight A positions 10x more than D positions
  /// Article.where { $0.match("swift") }
  ///   .select { ($0, $0.rank(by: "swift", weights: [0.1, 0.2, 0.4, 1.0])) }
  ///   .order(by: \.1.desc())
  /// // SELECT *, ts_rank('{0.1, 0.2, 0.4, 1.0}', "searchVector", to_tsquery('swift'))
  /// ```
  ///
  /// ## Weight Array Format
  ///
  /// The weights array has 4 elements corresponding to:
  /// - `[0]` - D weight (lowest priority, typically body text)
  /// - `[1]` - C weight (medium-low priority)
  /// - `[2]` - B weight (medium-high priority)
  /// - `[3]` - A weight (highest priority, typically titles)
  ///
  /// Default PostgreSQL weights: `[0.1, 0.2, 0.4, 1.0]`
  ///
  /// ## Example: Title Priority
  ///
  /// ```swift
  /// // Make title matches 20x more important than body
  /// Article.select {
  ///   $0.rank(by: "swift", weights: [0.05, 0.1, 0.2, 1.0])
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - query: The tsquery string to rank against
  ///   - weights: Weight array [D, C, B, A] for position importance
  ///   - language: Text search configuration (default: "english")
  ///   - normalization: Normalization options (default: .none)
  /// - Returns: A numeric expression representing weighted relevance score
  public func rank(
    by query: some StringProtocol,
    weights: [Double],
    language: String = "english",
    normalization: TextSearch.RankNormalization = .none
  ) -> some QueryExpression<Double> {
    precondition(weights.count == 4, "Weights array must have exactly 4 elements [D, C, B, A]")

    var fragment: QueryFragment = "ts_rank("

    // Weight array as PostgreSQL array constructor: ARRAY[0.1, 0.2, 0.4, 1.0]
    let weightsStr: String = weights.map { String($0) }.joined(separator: ", ")
    fragment.append("ARRAY[\(raw: weightsStr)], ")

    // Vector and query
    fragment.append("\(quote: QueryValue.tableName).\(quote: QueryValue.searchVectorColumn), ")
    fragment.append(
      "to_tsquery(\(raw: language.quoted(.text))::regconfig, \(bind: "\(query)"))")

    // Optional normalization
    if normalization != .none {
      fragment.append(", \(raw: String(normalization.rawValue))")
    }
    fragment.append(")")

    return SQLQueryExpression(fragment, as: Double.self)
  }

  /// An expression representing the search result's weighted coverage-based rank.
  ///
  /// Uses `ts_rank_cd()` with weight array. Better for phrase searches with importance weighting.
  ///
  /// ```swift
  /// Article.where { $0.match("quick <-> brown") }
  ///   .select { ($0, $0.rank(byCoverage: "quick <-> brown", weights: [0.1, 0.2, 0.4, 1.0])) }
  /// ```
  ///
  /// - Parameters:
  ///   - query: The tsquery string to rank against
  ///   - weights: Weight array [D, C, B, A] for position importance
  ///   - language: Text search configuration (default: "english")
  ///   - normalization: Normalization options (default: .none)
  /// - Returns: A numeric expression representing weighted coverage rank
  public func rank(
    byCoverage query: some StringProtocol,
    weights: [Double],
    language: String = "english",
    normalization: TextSearch.RankNormalization = .none
  ) -> some QueryExpression<Double> {
    precondition(weights.count == 4, "Weights array must have exactly 4 elements [D, C, B, A]")

    var fragment: QueryFragment = "ts_rank_cd("

    // Weight array as PostgreSQL array constructor: ARRAY[0.1, 0.2, 0.4, 1.0]
    let weightsStr: String = weights.map { String($0) }.joined(separator: ", ")
    fragment.append("ARRAY[\(raw: weightsStr)], ")

    // Vector and query
    fragment.append("\(quote: QueryValue.tableName).\(quote: QueryValue.searchVectorColumn), ")
    fragment.append(
      "to_tsquery(\(raw: language.quoted(.text))::regconfig, \(bind: "\(query)"))")

    // Optional normalization
    if normalization != .none {
      fragment.append(", \(raw: String(normalization.rawValue))")
    }
    fragment.append(")")

    return SQLQueryExpression(fragment, as: Double.self)
  }
}

extension TableColumnExpression where Value == TextSearch.Vector {
  /// Calculate relevance rank for tsvector column.
  ///
  /// Uses PostgreSQL's `ts_rank()` function to calculate relevance score.
  ///
  /// ```swift
  /// Article.where { $0.searchVector.match("swift") }
  ///   .select { ($0, $0.searchVector.rank(by: "swift")) }
  ///   .order(by: \.1.desc())
  /// ```
  ///
  /// - Parameters:
  ///   - query: The tsquery string to rank against
  ///   - language: Text search configuration (default: "english")
  ///   - normalization: Normalization options (default: .none)
  /// - Returns: A numeric expression representing relevance score
  public func rank(
    by query: some StringProtocol,
    language: String = "english",
    normalization: TextSearch.RankNormalization = .none
  ) -> some QueryExpression<Double> {
    var fragment: QueryFragment = "ts_rank("
    fragment.append("\(self.queryFragment), ")
    fragment.append(
      "to_tsquery(\(raw: language.quoted(.text))::regconfig, \(bind: "\(query)"))")
    if normalization != .none {
      fragment.append(", \(raw: String(normalization.rawValue))")
    }
    fragment.append(")")
    return SQLQueryExpression(fragment, as: Double.self)
  }

  /// Calculate weighted relevance rank for tsvector column.
  ///
  /// Uses PostgreSQL's `ts_rank()` with weight array for per-position weighting.
  ///
  /// ```swift
  /// Article.where { $0.searchVector.match("swift") }
  ///   .select { ($0, $0.searchVector.rank(by: "swift", weights: [0.1, 0.2, 0.4, 1.0])) }
  /// ```
  ///
  /// - Parameters:
  ///   - query: The tsquery string to rank against
  ///   - weights: Weight array [D, C, B, A] for position importance
  ///   - language: Text search configuration (default: "english")
  ///   - normalization: Normalization options (default: .none)
  /// - Returns: A numeric expression representing weighted relevance score
  public func rank(
    by query: some StringProtocol,
    weights: [Double],
    language: String = "english",
    normalization: TextSearch.RankNormalization = .none
  ) -> some QueryExpression<Double> {
    precondition(weights.count == 4, "Weights array must have exactly 4 elements [D, C, B, A]")

    var fragment: QueryFragment = "ts_rank("

    // Weight array as PostgreSQL array constructor: ARRAY[0.1, 0.2, 0.4, 1.0]
    let weightsStr: String = weights.map { String($0) }.joined(separator: ", ")
    fragment.append("ARRAY[\(raw: weightsStr)], ")

    // Vector and query
    fragment.append("\(self.queryFragment), ")
    fragment.append(
      "to_tsquery(\(raw: language.quoted(.text))::regconfig, \(bind: "\(query)"))")

    // Optional normalization
    if normalization != .none {
      fragment.append(", \(raw: String(normalization.rawValue))")
    }
    fragment.append(")")

    return SQLQueryExpression(fragment, as: Double.self)
  }
}
