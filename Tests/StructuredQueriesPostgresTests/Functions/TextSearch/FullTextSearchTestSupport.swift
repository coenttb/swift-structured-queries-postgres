import Foundation
import StructuredQueriesPostgres
import Testing

// Shared test tables for full-text search tests
@Table("articles")
struct Article: FullTextSearchable {
    let id: Int
    var title: String
    var body: String
    var searchVector: String  // tsvector column
}

@Table("blogPosts")
struct FTSBlogPost: FullTextSearchable {
    let id: Int
    var content: String
    var searchVector: String  // Default column name
}

// Full-Text Search test namespace
extension SnapshotTests {
    @Suite("Full-Text Search") struct FullTextSearch {}
}
