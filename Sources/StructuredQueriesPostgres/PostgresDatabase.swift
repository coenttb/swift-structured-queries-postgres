import Dependencies
import Foundation
import NIOCore
import PostgresNIO
import StructuredQueries

public struct PostgresQueryDatabase: Sendable {
    internal let connection: PostgresConnection

    public init(connection: PostgresConnection) {
        self.connection = connection
    }

    public func close() async throws {
        try await connection.close()
    }

    public func execute(_ query: some Statement<()>) async throws {
        let queryFragment = query.query
        guard !queryFragment.isEmpty else { return }
        let postgresStatement = PostgresStatement(queryFragment: queryFragment)

        _ = try await connection.query(
            postgresStatement.query,
            logger: connection.logger
        )
    }

    public func execute<QueryValue: QueryRepresentable>(
        _ query: some Statement<QueryValue>
    ) async throws -> [QueryValue.QueryOutput] {
        let queryFragment = query.query
        guard !queryFragment.isEmpty else { return [] }
        let postgresStatement = PostgresStatement(queryFragment: queryFragment)

        let rows = try await connection.query(
            postgresStatement.query,
            logger: connection.logger
        )

        var results: [QueryValue.QueryOutput] = []
        for try await row in rows {
            var decoder = PostgresQueryDecoder(row: row)
            let value = try decoder.decodeColumns(QueryValue.self)
            results.append(value)
        }
        return results
    }

    public func execute<each V: QueryRepresentable>(
        _ query: some Statement<(repeat each V)>
    ) async throws -> [(repeat (each V).QueryOutput)] {
        let queryFragment = query.query
        guard !queryFragment.isEmpty else { return [] }
        let postgresStatement = PostgresStatement(queryFragment: queryFragment)

        let rows = try await connection.query(
            postgresStatement.query,
            logger: connection.logger
        )

        var results: [(repeat (each V).QueryOutput)] = []
        for try await row in rows {
            var decoder = PostgresQueryDecoder(row: row)
            try results.append(decoder.decodeColumns((repeat each V).self))
        }
        return results
    }

    public func execute<QueryValue>(
        _ query: some SelectStatementOf<QueryValue>
    ) async throws -> [QueryValue.QueryOutput] {
        let queryFragment = query.query
        guard !queryFragment.isEmpty else { return [] }
        let postgresStatement = PostgresStatement(queryFragment: queryFragment)

        let rows = try await connection.query(
            postgresStatement.query,
            logger: connection.logger
        )

        var results: [QueryValue.QueryOutput] = []
        for try await row in rows {
            var decoder = PostgresQueryDecoder(row: row)
            let value = try QueryValue(decoder: &decoder).queryOutput
            results.append(value)
        }
        return results
    }

//     FIXME: This function is temporarily disabled due to an unsafeBitCast crash in selectStar()
//     See: https://github.com/pointfreeco/swift-structured-queries/issues/[TODO]
//     The crash occurs when selectStar() uses unsafeBitCast with variadic generics
//    public func execute<S: SelectStatement, each J: Table>(
//        _ query: S
//    ) async throws -> [(S.From.QueryOutput, repeat (each J).QueryOutput)]
//    where S.QueryValue == (), S.Joins == (repeat each J) {
//        try await execute(query.selectStar())
//    }
    

    public func executeFragment(_ fragment: QueryFragment) async throws {
        let postgresStatement = PostgresStatement(queryFragment: fragment)

        _ = try await connection.query(
            postgresStatement.query,
            logger: connection.logger
        )
    }

    public func execute(
        _ sql: String,
        bindings: PostgresBindings = PostgresBindings()
    ) async throws -> PostgresRowSequence {
        let query = PostgresQuery(unsafeSQL: sql, binds: bindings)
        return try await connection.query(query, logger: connection.logger)
    }

    public func executeWithParameters(
        _ sql: String,
        parameters: [any QueryBindable] = []
    ) async throws -> PostgresRowSequence {
        var interpolation = QueryFragment.StringInterpolation(literalCapacity: sql.count, interpolationCount: parameters.count)
        var currentSQL = sql

        for param in parameters {
            if let range = currentSQL.range(of: "?") {
                let beforeParam = String(currentSQL[..<range.lowerBound])
                if !beforeParam.isEmpty {
                    interpolation.appendLiteral(beforeParam)
                }
                interpolation.appendInterpolation(param.queryBinding)
                currentSQL = String(currentSQL[range.upperBound...])
            }
        }

        if !currentSQL.isEmpty {
            interpolation.appendLiteral(currentSQL)
        }

        let queryFragment = QueryFragment(stringInterpolation: interpolation)
        let postgresStatement = PostgresStatement(queryFragment: queryFragment)
        return try await connection.query(postgresStatement.query, logger: connection.logger)
    }
}

extension PostgresQueryDatabase {
    public func cursor<S: Statement>(
        _ statement: S
    ) async throws -> PostgresQueryCursor<S.QueryValue> where S.QueryValue: Decodable & QueryDecodable {
        let queryFragment = statement.query
        let postgresStatement = PostgresStatement(queryFragment: queryFragment)

        let rows = try await connection.query(
            postgresStatement.query,
            logger: connection.logger
        )

        return PostgresQueryCursor<S.QueryValue>(rows: rows)
    }

    public func withRollback<T>(
        _ body: (PostgresQueryDatabase) async throws -> T
    ) async throws -> T {
        _ = try await self.execute("BEGIN")

        do {
            let result = try await body(self)

            _ = try await self.execute("ROLLBACK")

            return result
        } catch {
            _ = try await self.execute("ROLLBACK")
            throw error
        }
    }
}

// MARK: - Dependency

extension PostgresQueryDatabase: DependencyKey {
    public static var liveValue: PostgresQueryDatabase {
        fatalError(
      """
      No live PostgresQueryDatabase has been configured.

      Configure it in your app's entry point:

      @main
      struct MyApp: App {
        init() {
          let connection = try! await PostgresConnection.connect(...)
          @Dependency(PostgresQueryDatabase.self) = PostgresQueryDatabase(connection: connection)
        }
      }
      """
        )
    }

    public static var testValue: PostgresQueryDatabase {
        fatalError("PostgresQueryDatabase.testValue not implemented. Use a mock or test database connection.")
    }
}

extension DependencyValues {
    public var postgresDatabase: PostgresQueryDatabase {
        get { self[PostgresQueryDatabase.self] }
        set { self[PostgresQueryDatabase.self] = newValue }
    }
}
