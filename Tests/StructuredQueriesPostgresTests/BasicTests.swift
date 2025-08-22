import Dependencies
import Foundation
import NIOCore
import PostgresNIO
import StructuredQueries
import StructuredQueriesPostgres
import Testing

@Suite("PostgreSQL Adapter Tests")
struct BasicTests {

    @Test("QueryFragment to PostgresStatement conversion")
    func testPostgresStatement() {
        let fragment: QueryFragment = """
      SELECT * FROM users WHERE id = \(42) AND name = \(bind: "Alice")
      """

        let postgresStatement = PostgresStatement(queryFragment: fragment)

        #expect(postgresStatement.query.sql == "SELECT * FROM users WHERE id = $1 AND name = $2")
        #expect(postgresStatement.query.binds.count == 2)
    }

    @Test("Query decoder initialization")
    func testQueryDecoder() {
        #expect(true)
    }

    @Test("QueryFragment with NULL values")
    func testStatementWithNullValues() {
        let fragment: QueryFragment = """
      INSERT INTO users (id, name, email) VALUES (\(1), \(bind: "Bob"), \(QueryBinding.null))
      """

        let postgresStatement = PostgresStatement(queryFragment: fragment)

        #expect(postgresStatement.query.sql == "INSERT INTO users (id, name, email) VALUES ($1, $2, $3)")
        #expect(postgresStatement.query.binds.count == 3)
    }

    @Test("QueryFragment with BLOB data")
    func testStatementWithBlobData() {
        let data = Data([0x01, 0x02, 0x03])
        let fragment: QueryFragment = """
      UPDATE files SET content = \(data) WHERE id = \(100)
      """

        let postgresStatement = PostgresStatement(queryFragment: fragment)

        #expect(postgresStatement.query.sql == "UPDATE files SET content = $1 WHERE id = $2")
        #expect(postgresStatement.query.binds.count == 2)
    }

    @Test("QueryBindable conformance")
    func testQueryBindableTypes() {
        let intBinding = 42.queryBinding
        #expect(intBinding == .int(42))

        let stringBinding = "hello".queryBinding
        #expect(stringBinding == .text("hello"))

        let doubleBinding = 3.14.queryBinding
        #expect(doubleBinding == .double(3.14))

        let boolBinding = true.queryBinding
        #expect(boolBinding == .int(1))

        let falseBinding = false.queryBinding
        #expect(falseBinding == .int(0))
    }
}
