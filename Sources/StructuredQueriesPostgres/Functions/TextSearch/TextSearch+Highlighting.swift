// MARK: - 12.9.4: Highlighting Results (ts_headline)

import Foundation
import StructuredQueriesCore

extension TableColumnExpression where Value == String {
  /// Highlight search matches in text with delimiters.
  ///
  /// Uses `ts_headline()` to generate display text with highlighted matches.
  /// Useful for showing search results with matched terms emphasized.
  ///
  /// ```swift
  /// Article.where { $0.match("swift") }
  ///   .select {
  ///     $0.title.headline(matching: "swift", startDelimiter: "<mark>", stopDelimiter: "</mark>")
  ///   }
  /// // SELECT ts_headline('english', "title", to_tsquery('swift'),
  /// //                    'StartSel=<mark>, StopSel=</mark>')
  /// ```
  ///
  /// ## Word Range
  ///
  /// Use `TextSearch.WordRange` to specify the headline length. This ensures
  /// `minWords < maxWords`, preventing PostgreSQL errors.
  ///
  /// ```swift
  /// // Using presets
  /// $0.body.headline(matching: "swift", wordRange: .short)  // 3-10 words
  /// $0.body.headline(matching: "swift", wordRange: .medium) // 10-25 words
  ///
  /// // Custom range
  /// $0.body.headline(
  ///   matching: "swift postgresql",
  ///   wordRange: TextSearch.WordRange(min: 20, max: 50)
  /// )
  /// ```
  ///
  /// ## Delimiter Limitations
  ///
  /// **Important:** Commas cannot be used in delimiters due to PostgreSQL's options parser.
  /// Any commas in `startDelimiter` or `stopDelimiter` will be automatically removed.
  ///
  /// ```swift
  /// // This will work - commas are stripped
  /// $0.body.headline(matching: "swift", startDelimiter: "a,b", stopDelimiter: "c,d")
  /// // Generates: StartSel=ab, StopSel=cd
  /// ```
  ///
  /// This is a PostgreSQL limitation, not a library design choice. PostgreSQL's `ts_headline`
  /// options parser uses commas as separators between options and provides no escaping mechanism.
  /// Common HTML/Markdown delimiters like `<mark>`, `**`, `<b>` work perfectly.
  ///
  /// - Parameters:
  ///   - query: The tsquery string to highlight
  ///   - language: Text search configuration (default: "english")
  ///   - startDelimiter: Opening delimiter for matches (default: "<b>")
  ///                     **Note:** Commas are not supported and will be removed.
  ///                     This is a PostgreSQL limitation - its options parser uses
  ///                     commas as separators and has no escaping mechanism.
  ///   - stopDelimiter: Closing delimiter for matches (default: "</b>")
  ///                    **Note:** Commas are not supported and will be removed.
  ///                    This is a PostgreSQL limitation - its options parser uses
  ///                    commas as separators and has no escaping mechanism.
  ///   - wordRange: Min/max words in headline (ensures minWords < maxWords)
  ///   - shortWord: Words this length or less are ignored
  ///   - maxFragments: Maximum number of text fragments
  /// - Returns: A string expression with highlighted text
  public func headline(
    matching query: some StringProtocol,
    language: String = "english",
    startDelimiter: String = "<b>",
    stopDelimiter: String = "</b>",
    wordRange: TextSearch.WordRange? = nil,
    shortWord: Int? = nil,
    maxFragments: Int? = nil
  ) -> some QueryExpression<String> {
    // Escape delimiters for ts_headline options:
    // - Single quotes must be doubled for SQL string literals
    // - Commas must be removed because they're used as option separators in PostgreSQL
    //   and cannot be escaped within option values
    func escapeDelimiter(_ s: String) -> String {
      s.replacingOccurrences(of: "'", with: "''")
        .replacingOccurrences(of: ",", with: "")
    }

    var options: [String] = [
      "StartSel=\(escapeDelimiter(startDelimiter))",
      "StopSel=\(escapeDelimiter(stopDelimiter))",
    ]

    if let wordRange {
      options.append("MinWords=\(wordRange.min)")
      options.append("MaxWords=\(wordRange.max)")
    }

    if let shortWord {
      options.append("ShortWord=\(shortWord)")
    }
    if let maxFragments {
      options.append("MaxFragments=\(maxFragments)")
    }

    let optionsString = options.joined(separator: ", ")

    return SQLQueryExpression(
      """
      ts_headline(\
      \(raw: language.quoted(.text))::regconfig, \
      \(self.queryFragment), \
      to_tsquery(\(raw: language.quoted(.text))::regconfig, \(bind: "\(query)")), \
      \(raw: optionsString.quoted(.text))\
      )
      """,
      as: String.self
    )
  }
}
