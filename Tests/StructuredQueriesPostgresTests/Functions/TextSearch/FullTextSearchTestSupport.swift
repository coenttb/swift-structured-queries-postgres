import Foundation
import StructuredQueriesPostgres
import Testing

// Shared test tables for full-text search tests
@Table("articles")
struct FTSArticle: FullTextSearchable {
    let id: Int
    var title: String
    var body: String
    var searchVector: String  // tsvector column

    static var searchVectorColumn: String { "searchVector" }
}

@Table("blogPosts")
struct FTSBlogPost: FullTextSearchable {
    let id: Int
    var content: String
    var search_vector: String  // Default column name
}

// Full-Text Search test namespace
extension SnapshotTests {
    @Suite("Full-Text Search") struct FullTextSearch {}
}
