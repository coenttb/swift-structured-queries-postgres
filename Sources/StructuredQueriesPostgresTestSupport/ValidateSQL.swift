import Foundation
import InlineSnapshotTesting
#if StructuredQueriesPostgresSQLValidation
import Logging
import NIOCore
import NIOPosix
import PostgresNIO
#endif


import StructuredQueriesCore
import Testing

// MARK: - Shared Client
#if StructuredQueriesPostgresSQLValidation
/// Global EventLoopGroup for all validation clients
private let validationEventLoopGroup = MultiThreadedEventLoopGroup.singleton

/// Shared PostgresClient for ALL SQL validations
/// This prevents "too many connections" by reusing a single connection pool
private actor SharedValidationClient {
    private var client: PostgresClient?
    private var runTask: Task<Void, Never>?
    
    func getOrCreateClient() async throws -> PostgresClient {
        if let existing = client {
            return existing
        }
        
        let config = try postgresConfiguration()
        let newClient = PostgresClient(
            configuration: config,
            eventLoopGroup: validationEventLoopGroup,
            backgroundLogger: Logger(label: "sql-validation")
        )
        self.client = newClient
        
        // Start client.run() once for the shared client
        let task = Task {
            await newClient.run()
        }
        self.runTask = task
        
        // Register shutdown handler on first client creation
        if !shutdownHandlerRegistered {
            shutdownHandlerRegistered = true
            atexit {
                let semaphore = DispatchSemaphore(value: 0)
                Task {
                    await sharedValidationClient.shutdown()
                    semaphore.signal()
                }
                _ = semaphore.wait(timeout: .now() + .seconds(5))
            }
        }
        
        // Give client time to initialize
        try? await Task.sleep(nanoseconds: 50_000_000)  // 50ms
        
        return newClient
    }
    
    func shutdown() async {
        // Cancel run task
        runTask?.cancel()
        
        // Wait for cancellation
        if let task = runTask {
            await task.value
        }
        
        // Shutdown EventLoopGroup
        try? await validationEventLoopGroup.shutdownGracefully()
        
        client = nil
        runTask = nil
    }
}

private let sharedValidationClient = SharedValidationClient()

/// Register shutdown handler on first use
private nonisolated(unsafe) var shutdownHandlerRegistered = false
#endif

// MARK: - SQL Validation

/// Validates that generated SQL is syntactically correct PostgreSQL.
///
/// This helper uses PostgreSQL's `EXPLAIN` command to validate SQL syntax without executing
/// the query. It's useful for catching syntax errors during testing.
///
/// **Note**: This function is only available when the `StructuredQueriesPostgresSQLValidation`
/// trait is enabled, as it requires the heavy `postgres-nio` dependency.
///
/// ## Usage
///
/// ```swift
/// @Test func windowFunctionWithFrame() async throws {
///     let query = Reminder.all.select {
///         let id = $0.id
///         return ($0.title, rowNumber().over {
///             $0.order(by: id).rows(between: .unboundedPreceding, and: .currentRow)
///         })
///     }
///
///     // Validate SQL syntax and snapshot exact output
///     await assertSQL(of: query) {
///         """
///         SELECT "reminders"."title", ROW_NUMBER() OVER (ORDER BY "reminders"."id" ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
///         FROM "reminders"
///         """
///     }
/// }
/// ```
///
/// ## How It Works
///
/// 1. Generates SQL from the statement
/// 2. Snapshots the SQL (like `assertInlineSnapshot`)
/// 3. Validates syntax by running `EXPLAIN` against PostgreSQL
/// 4. Fails test if SQL is invalid
///
/// ## Database Connection
///
/// This function expects a PostgreSQL database to be available at:
/// - Host: `localhost`
/// - Port: `5432`
/// - Database: `test`
/// - Username: `postgres`
/// - Password: (none)
///
/// You can customize this by setting the `POSTGRES_URL` environment variable:
/// ```
/// POSTGRES_URL=postgres://user:pass@host:port/database swift test
/// ```
///
/// - Parameters:
///   - statement: The statement to validate
///   - matches: The expected SQL output (optional - will be recorded if nil)
///   - fileID: The source file ID (auto-populated)
///   - filePath: The source file path (auto-populated)
///   - function: The source function (auto-populated)
///   - line: The source line (auto-populated)
///   - column: The source column (auto-populated)
public func assertSQL<T>(
    of statement: some Statement<T>,
    matches: (() -> String)? = nil,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    function: StaticString = #function,
    line: UInt = #line,
    column: UInt = #column
) async {
    // First, snapshot the SQL (synchronous)
    assertInlineSnapshot(
        of: statement,
        as: .sql,
        message: "SQL did not match snapshot",
        matches: matches,
        fileID: fileID,
        file: filePath,
        function: function,
        line: line,
        column: column
    )
    #if StructuredQueriesPostgresSQLValidation
    // Then validate syntax against PostgreSQL (asynchronous)
    await validatePostgreSQLSyntax(
        statement,
        fileID: fileID,
        filePath: filePath,
        function: function,
        line: line,
        column: column
    )
    #endif
}


#if StructuredQueriesPostgresSQLValidation
/// Validates SQL syntax against PostgreSQL without snapshotting.
///
/// Use this when you only want syntax validation without snapshot testing.
///
/// ```swift
/// await validatePostgreSQLSyntax(myQuery)
/// ```
public func validatePostgreSQLSyntax<T>(
    _ statement: some Statement<T>,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    function: StaticString = #function,
    line: UInt = #line,
    column: UInt = #column
) async {
    let sql = statement.query.debugDescription
    
    // Normalize whitespace to handle newlines and multiple spaces
    let normalizedSQL = sql.replacingOccurrences(
        of: "\\s+", with: " ", options: .regularExpression
    )
        .trimmingCharacters(in: .whitespaces)
        .uppercased()
    
    // Validate CREATE FUNCTION and CREATE TRIGGER using transaction rollback
    let ddlValidatablePrefixes = [
        "CREATE FUNCTION", "CREATE OR REPLACE FUNCTION", "CREATE TRIGGER",
    ]
    if ddlValidatablePrefixes.contains(where: { normalizedSQL.hasPrefix($0) }) {
        await validateDDLWithTransaction(
            sql,
            fileID: fileID,
            filePath: filePath,
            function: function,
            line: line,
            column: column
        )
        return
    }
    
    // Skip validation for other DDL that can't be validated
    let ddlSkippedPrefixes = [
        "CREATE VIEW", "CREATE TEMP VIEW", "CREATE TEMPORARY VIEW",
        "CREATE OR REPLACE VIEW", "CREATE OR REPLACE TEMP VIEW",
        "DROP VIEW", "CREATE TABLE", "DROP TABLE",
        "ALTER TABLE", "CREATE INDEX", "DROP INDEX",
        "DROP TRIGGER", "DROP FUNCTION",
    ]
    
    if ddlSkippedPrefixes.contains(where: { normalizedSQL.hasPrefix($0) }) {
        // These DDL statements are assumed syntactically correct from query builder
        return
    }
    
    do {
        // Get or create shared client
        let client = try await sharedValidationClient.getOrCreateClient()
        
        // Validate SQL using EXPLAIN
        do {
            try await client.withConnection { connection in
                let validationQuery = "EXPLAIN (FORMAT TEXT) \(sql)"
                _ = try await connection.query(
                    PostgresQuery(unsafeSQL: validationQuery),
                    logger: Logger(label: "sql-validation")
                )
                // If we reach here, SQL is valid ✅
            }
        } catch {
            // Check if this is a syntax error or just a missing table/column
            let errorString = String(reflecting: error)
            
            // PostgreSQL error codes:
            // 42601 = syntax_error
            // 42P01 = undefined_table (OK - syntax is valid, table just doesn't exist)
            // 42703 = undefined_column (OK - syntax is valid, column just doesn't exist)
            // 42883 = undefined_function (OK - syntax is valid, function just doesn't exist)
            
            let isSyntaxError = errorString.contains("sqlState: 42601")  // syntax_error
            let isSchemaError =
            errorString.contains("sqlState: 42P01")  // undefined_table
            || errorString.contains("sqlState: 42703")  // undefined_column
            || errorString.contains("sqlState: 42883")  // undefined_function
            
            // Only fail the test for actual syntax errors
            if isSyntaxError {
                Issue.record(
                        """
                        Invalid PostgreSQL SQL syntax:
                        
                        \(sql)
                        
                        Error: \(errorString)
                        """,
                        sourceLocation: SourceLocation(
                            fileID: fileID.description,
                            filePath: filePath.description,
                            line: Int(line),
                            column: Int(column)
                        )
                )
            } else if !isSchemaError {
                // Unknown error type - report it but note it might be OK
                Issue.record(
                        """
                        PostgreSQL validation error (might be OK if not a syntax error):
                        
                        \(sql)
                        
                        Error: \(errorString)
                        """,
                        sourceLocation: SourceLocation(
                            fileID: fileID.description,
                            filePath: filePath.description,
                            line: Int(line),
                            column: Int(column)
                        )
                )
            }
            // If isSchemaError, do nothing - syntax is valid, schema just doesn't exist
        }
    } catch {
        Issue.record(
                """
                Failed to connect to PostgreSQL for syntax validation.
                
                Make sure PostgreSQL is running and configured via environment variables:
                
                Option 1: POSTGRES_URL (connection string)
                  POSTGRES_URL=postgres://user:pass@localhost:5432/database
                
                Option 2: Individual variables (compatible with swift-records)
                  POSTGRES_HOST=localhost       (default: localhost)
                  POSTGRES_PORT=5432            (default: 5432)
                  POSTGRES_USER=coenttb         (default: coenttb)
                  POSTGRES_PASSWORD=            (default: none)
                  POSTGRES_DB=test              (default: test)
                
                Error: \(error.localizedDescription)
                
                To skip SQL validation, disable the StructuredQueriesPostgresSQLValidation trait.
                """,
                sourceLocation: SourceLocation(
                    fileID: fileID.description,
                    filePath: filePath.description,
                    line: Int(line),
                    column: Int(column)
                )
        )
    }
}

/// Validates DDL statements (CREATE FUNCTION, CREATE TRIGGER) using transaction rollback.
///
/// PostgreSQL doesn't support EXPLAIN with DDL statements, so we execute them in a
/// transaction and roll back to validate syntax without side effects.
private func validateDDLWithTransaction(
    _ sql: String,
    fileID: StaticString,
    filePath: StaticString,
    function: StaticString,
    line: UInt,
    column: UInt
) async {
    do {
        let client = try await sharedValidationClient.getOrCreateClient()
        
        try await client.withConnection { connection in
            // Start transaction
            _ = try await connection.query(
                PostgresQuery(unsafeSQL: "BEGIN"),
                logger: Logger(label: "sql-validation")
            )
            
            do {
                // Execute DDL statement - if syntax is invalid, this will throw
                _ = try await connection.query(
                    PostgresQuery(unsafeSQL: sql),
                    logger: Logger(label: "sql-validation")
                )
                
                // Rollback to remove the DDL from the database
                _ = try await connection.query(
                    PostgresQuery(unsafeSQL: "ROLLBACK"),
                    logger: Logger(label: "sql-validation")
                )
                
                // If we reach here, SQL syntax is valid ✅
            } catch {
                // Rollback on error
                _ = try? await connection.query(
                    PostgresQuery(unsafeSQL: "ROLLBACK"),
                    logger: Logger(label: "sql-validation")
                )
                
                let errorString = String(reflecting: error)
                
                // Check for syntax errors
                let isSyntaxError = errorString.contains("sqlState: 42601")  // syntax_error
                
                // Check for schema errors (OK - syntax is valid, objects just don't exist)
                let isSchemaError =
                errorString.contains("sqlState: 42P01")  // undefined_table
                || errorString.contains("sqlState: 42703")  // undefined_column
                || errorString.contains("sqlState: 42883")  // undefined_function
                
                if isSyntaxError {
                    Issue.record(
                            """
                            Invalid PostgreSQL DDL syntax:
                            
                            \(sql)
                            
                            Error: \(errorString)
                            """,
                            sourceLocation: SourceLocation(
                                fileID: fileID.description,
                                filePath: filePath.description,
                                line: Int(line),
                                column: Int(column)
                            )
                    )
                } else if !isSchemaError {
                    // Unknown error type - report it
                    Issue.record(
                            """
                            PostgreSQL DDL validation error:
                            
                            \(sql)
                            
                            Error: \(errorString)
                            """,
                            sourceLocation: SourceLocation(
                                fileID: fileID.description,
                                filePath: filePath.description,
                                line: Int(line),
                                column: Int(column)
                            )
                    )
                }
                // If isSchemaError, do nothing - syntax is valid, schema just doesn't exist
            }
        }
    } catch {
        Issue.record(
                """
                Failed to connect to PostgreSQL for DDL validation.
                
                Make sure PostgreSQL is running and configured via environment variables.
                
                Error: \(error.localizedDescription)
                """,
                sourceLocation: SourceLocation(
                    fileID: fileID.description,
                    filePath: filePath.description,
                    line: Int(line),
                    column: Int(column)
                )
        )
    }
}

// MARK: - Configuration

private func postgresConfiguration() throws -> PostgresClient.Configuration {
    // Try POSTGRES_URL first (standard connection string)
    if let urlString = ProcessInfo.processInfo.environment["POSTGRES_URL"] {
        guard let url = URL(string: urlString),
              let host = url.host(),
              let user = url.user
        else {
            throw ValidationError.invalidURL(urlString)
        }
        
        let database = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        
        return PostgresClient.Configuration(
            host: host,
            port: url.port ?? 5432,
            username: user,
            password: url.password,
            database: database.isEmpty ? nil : database,
            tls: .disable
        )
    }
    
    // Try individual environment variables (compatible with swift-records pattern)
    let host = ProcessInfo.processInfo.environment["POSTGRES_HOST"] ?? "localhost"
    let port = ProcessInfo.processInfo.environment["POSTGRES_PORT"].flatMap(Int.init) ?? 5432
    let username = ProcessInfo.processInfo.environment["POSTGRES_USER"] ?? "coenttb"
    let password = ProcessInfo.processInfo.environment["POSTGRES_PASSWORD"]
    let database = ProcessInfo.processInfo.environment["POSTGRES_DB"] ?? "test"
    
    return PostgresClient.Configuration(
        host: host,
        port: port,
        username: username,
        password: password?.isEmpty == true ? nil : password,
        database: database,
        tls: .disable
    )
}

private enum ValidationError: Error {
    case invalidURL(String)
}

#endif
