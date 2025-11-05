import StructuredQueriesCore

// MARK: - 12.9.1 & 12.9.2: Text Search Parsing (to_tsvector, to_tsquery, @@)

extension TableDefinition where QueryValue: FullTextSearchable {
    /// A predicate expression matching the table's search vector against a tsquery.
    ///
    /// This uses PostgreSQL's `@@` match operator to search the tsvector column.
    ///
    /// ```swift
    /// Article.where { $0.match("swift & postgresql") }
    /// // WHERE "articles"."searchVector" @@ to_tsquery('english', 'swift & postgresql')
    ///
    /// Article.where { $0.match("quick brown fox", language: "simple") }
    /// // WHERE "articles"."searchVector" @@ to_tsquery('simple', 'quick brown fox')
    /// ```
    ///
    /// ## Query Syntax
    ///
    /// PostgreSQL tsquery supports operators:
    /// - `&` - AND (both terms must match)
    /// - `|` - OR (either term can match)
    /// - `!` - NOT (term must not match)
    /// - `<->` - Phrase (terms must be adjacent)
    /// - `<N>` - Near (terms within N words)
    ///
    /// Examples:
    /// - `"swift & postgresql"` - Must contain both words
    /// - `"swift | rust"` - Must contain either word
    /// - `"swift & !objective"` - Must contain swift but not objective
    /// - `"quick <-> brown"` - Words must be adjacent
    ///
    /// ## Important
    ///
    /// User input should be properly escaped to avoid syntax errors. Consider using
    /// `plainto_tsquery()` or `websearch_to_tsquery()` for user-entered queries.
    ///
    /// - Parameters:
    ///   - query: A tsquery string with search terms and operators
    ///   - language: Text search configuration (default: "english")
    /// - Returns: A boolean predicate expression
    public func match(
        _ query: some StringProtocol,
        language: String = "english"
    ) -> some QueryExpression<Bool> {
        SQLQueryExpression(
            """
            \(quote: QueryValue.tableName).\(quote: QueryValue.searchVectorColumn) @@ \
            to_tsquery(\(raw: language.quoted(.text))::regconfig, \(bind: "\(query)"))
            """,
            as: Bool.self
        )
    }

    /// A predicate expression matching the table's search vector using plain text.
    ///
    /// This uses `plainto_tsquery()` which converts plain text to a tsquery,
    /// treating all words as AND-connected terms. Safer for user input.
    ///
    /// ```swift
    /// Article.where { $0.plainMatch("swift postgresql") }
    /// // WHERE "articles"."searchVector" @@ plainto_tsquery('english', 'swift postgresql')
    /// // Equivalent to: swift & postgresql
    /// ```
    ///
    /// - Parameters:
    ///   - text: Plain text search query
    ///   - language: Text search configuration (default: "english")
    /// - Returns: A boolean predicate expression
    public func plainMatch(
        _ text: some StringProtocol,
        language: String = "english"
    ) -> some QueryExpression<Bool> {
        SQLQueryExpression(
            """
            \(quote: QueryValue.tableName).\(quote: QueryValue.searchVectorColumn) @@ \
            plainto_tsquery(\(raw: language.quoted(.text))::regconfig, \(bind: "\(text)"))
            """,
            as: Bool.self
        )
    }

    /// A predicate expression matching using web search syntax.
    ///
    /// This uses `websearch_to_tsquery()` which supports Google-like search syntax:
    /// - `"quoted phrases"` - Phrase search
    /// - `-word` - Exclude word
    /// - `word1 OR word2` - Either word
    ///
    /// ```swift
    /// Article.where { $0.webMatch(#""swift postgresql" -objective"#) }
    /// // WHERE "articles"."searchVector" @@ websearch_to_tsquery('english', '"swift postgresql" -objective')
    /// ```
    ///
    /// - Parameters:
    ///   - query: Web search-style query string
    ///   - language: Text search configuration (default: "english")
    /// - Returns: A boolean predicate expression
    public func webMatch(
        _ query: some StringProtocol,
        language: String = "english"
    ) -> some QueryExpression<Bool> {
        SQLQueryExpression(
            """
            \(quote: QueryValue.tableName).\(quote: QueryValue.searchVectorColumn) @@ \
            websearch_to_tsquery(\(raw: language.quoted(.text))::regconfig, \(bind: "\(query)"))
            """,
            as: Bool.self
        )
    }

    /// A predicate expression matching using phrase search.
    ///
    /// This uses `phraseto_tsquery()` which converts text to a phrase query where
    /// all words must appear in the exact order specified. Equivalent to using the
    /// `<->` (followed by) operator for each adjacent pair of words.
    ///
    /// ```swift
    /// Article.where { $0.phraseMatch("quick brown fox") }
    /// // WHERE "articles"."searchVector" @@ phraseto_tsquery('english', 'quick brown fox')
    /// // Equivalent to: 'quick' <-> 'brown' <-> 'fox'
    /// ```
    ///
    /// ## Use Cases
    ///
    /// Phrase matching is ideal for:
    /// - Exact phrase searches (e.g., "San Francisco", "machine learning")
    /// - Title matching where word order matters
    /// - Technical terms that must appear together
    ///
    /// For more flexible phrase searching with gaps, use `match()` with the `<N>` operator:
    /// ```swift
    /// Article.where { $0.match("quick <2> fox") }  // "quick" within 2 words of "fox"
    /// ```
    ///
    /// - Parameters:
    ///   - phrase: Phrase text where words must appear in order
    ///   - language: Text search configuration (default: "english")
    /// - Returns: A boolean predicate expression
    public func phraseMatch(
        _ phrase: some StringProtocol,
        language: String = "english"
    ) -> some QueryExpression<Bool> {
        SQLQueryExpression(
            """
            \(quote: QueryValue.tableName).\(quote: QueryValue.searchVectorColumn) @@ \
            phraseto_tsquery(\(raw: language.quoted(.text))::regconfig, \(bind: "\(phrase)"))
            """,
            as: Bool.self
        )
    }
}

// MARK: - Column-Level Parsing Functions

extension TableColumnExpression where Value == String {
    /// Convert text column to tsvector for full-text indexing.
    ///
    /// This function converts text to a searchable tsvector, performing:
    /// - Tokenization (word splitting)
    /// - Normalization (case folding)
    /// - Stop word removal
    /// - Stemming (reducing words to root form)
    ///
    /// ```swift
    /// Article.select { $0.title.searchVector() }
    /// // SELECT to_tsvector('english', "articles"."title")
    ///
    /// Article.select { $0.body.searchVector("french") }
    /// // SELECT to_tsvector('french', "articles"."body")
    /// ```
    ///
    /// ## Supported Languages
    ///
    /// PostgreSQL includes configurations for many languages:
    /// - `english` (default)
    /// - `simple` (no stemming/stop words)
    /// - `french`, `german`, `spanish`, `italian`, etc.
    ///
    /// - Parameter language: Text search configuration (default: "english")
    /// - Returns: A tsvector expression
    public func searchVector(_ language: String = "english") -> some QueryExpression<String> {
        SQLQueryExpression(
            "to_tsvector(\(raw: language.quoted(.text))::regconfig, \(self.queryFragment))",
            as: String.self
        )
    }

    /// Match text column against a tsquery pattern.
    ///
    /// Generates a tsvector from the text and matches it against the query.
    /// Useful for ad-hoc searches without a pre-computed tsvector column.
    ///
    /// ```swift
    /// Article.where { $0.title.match("swift") }
    /// // WHERE to_tsvector('english', "title") @@ to_tsquery('english', 'swift')
    /// ```
    ///
    /// **Note**: For better performance, use a pre-computed tsvector column
    /// with a GIN index instead of calling this on every row.
    ///
    /// - Parameters:
    ///   - query: The tsquery string to match
    ///   - language: Text search configuration (default: "english")
    /// - Returns: A boolean predicate expression
    public func match(
        _ query: some StringProtocol,
        language: String = "english"
    ) -> some QueryExpression<Bool> {
        SQLQueryExpression(
            """
            to_tsvector(\(raw: language.quoted(.text))::regconfig, \(self.queryFragment)) @@ \
            to_tsquery(\(raw: language.quoted(.text))::regconfig, \(bind: "\(query)"))
            """,
            as: Bool.self
        )
    }
}
