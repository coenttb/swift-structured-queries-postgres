import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

// Database integration tests removed. This file contained tests that required database execution:
// - UUID binding tests with actual database operations
// - Overflow error handling with database execution
// - UUID IN clause tests with database execution
//
// These tests belong in swift-records package where database integration tests are located.
// This package (swift-structured-queries-postgres) is DSL-focused and should only contain
// snapshot tests for SQL generation, not database execution tests.
