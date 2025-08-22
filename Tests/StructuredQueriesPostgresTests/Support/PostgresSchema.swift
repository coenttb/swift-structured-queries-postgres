import Dependencies
import EnvironmentVariables
import Foundation
import Logging
import PostgresNIO
import StructuredQueries
import StructuredQueriesPostgres

@Table
struct RemindersList: Codable, Equatable, Identifiable {
    static let withReminderCount = group(by: \.id)
        .join(Reminder.all) { $0.id.eq($1.remindersListID) }
        .select { $1.id.count() }

    let id: Int
    var color = 0x4a99ef
    var title = ""
    var position = 0
}

@Table
struct Reminder: Codable, Equatable, Identifiable {
    static let incomplete = Self.where { !$0.isCompleted }

    let id: Int
    var assignedUserID: User.ID?
    var dueDate: Date?
    var isCompleted = false
    var isFlagged = false
    var notes = ""
    var priority: Priority?
    var remindersListID: Int
    var title = ""
    var updatedAt: Date = Date(timeIntervalSinceReferenceDate: 1_234_567_890)

    static func searching(_ text: String) -> Where<Reminder> {
        Self.where {
            $0.title.collate(.nocase).contains(text)
            || $0.notes.collate(.nocase).contains(text)
        }
    }
}

@Table
struct User: Codable, Equatable, Identifiable {
    let id: Int
    var name = ""
}

enum Priority: Int, Codable, QueryBindable {
    case low = 1
    case medium
    case high
}

extension Reminder.TableColumns {
    var isPastDue: some QueryExpression<Bool> {
        !isCompleted && #sql("coalesce(\(dueDate), current_date) < current_date")
    }
}

@Table
struct Tag: Codable, Equatable, Identifiable {
    let id: Int
    var title = ""
}

@Table("remindersTags")
struct ReminderTag: Equatable {
    let reminderID: Int
    let tagID: Int
}

@Table
struct Milestone: Codable, Equatable {
    let id: Int
    var remindersListID: RemindersList.ID
    var title = ""
}

// PostgreSQL-specific test tables
@Table
struct PostgresDataTypes: Codable, Equatable {
    let id: Int
    var uuid: UUID?
    var jsonData: Data?  // Will be stored as JSONB
    var tags: String?  // PostgreSQL array stored as JSON string
    var metadata: String?  // JSONB stored as JSON string
    var ipAddress: String?  // INET type
    var createdAt: Date
}

// Add EnvironmentVariables configuration
extension EnvironmentVariables {
    static let development: Self = try! .live(environmentConfiguration: .projectRoot(.projectRoot, environment: "development"))
}

extension URL {
    static var projectRoot: URL {
        URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}

extension PostgresQueryDatabase {
    func migrate() async throws {
        // Drop existing tables
        _ = try await self.execute("DROP TABLE IF EXISTS milestones CASCADE")
        _ = try await self.execute("DROP TABLE IF EXISTS \"remindersTags\" CASCADE")
        _ = try await self.execute("DROP TABLE IF EXISTS tags CASCADE")
        _ = try await self.execute("DROP TABLE IF EXISTS reminders CASCADE")
        _ = try await self.execute("DROP TABLE IF EXISTS users CASCADE")
        _ = try await self.execute("DROP TABLE IF EXISTS \"remindersLists\" CASCADE")
        _ = try await self.execute("DROP TABLE IF EXISTS \"postgresDataTypes\" CASCADE")

        // Create tables with PostgreSQL-specific features
        _ = try await self.execute("""
      CREATE TABLE "remindersLists" (
        "id" SERIAL PRIMARY KEY,
        "color" INTEGER NOT NULL DEFAULT 4889071,
        "title" TEXT NOT NULL DEFAULT '',
        "position" INTEGER NOT NULL DEFAULT 0
      )
      """)

        _ = try await self.execute("""
      CREATE UNIQUE INDEX "remindersLists_title" ON "remindersLists"("title")
      """)

        _ = try await self.execute("""
      CREATE TABLE "users" (
        "id" SERIAL PRIMARY KEY,
        "name" TEXT NOT NULL DEFAULT ''
      )
      """)

        _ = try await self.execute("""
      CREATE TABLE "reminders" (
        "id" SERIAL PRIMARY KEY,
        "assignedUserID" INTEGER REFERENCES "users"("id"),
        "dueDate" TIMESTAMP,
        "isCompleted" INTEGER NOT NULL DEFAULT 0 CHECK ("isCompleted" IN (0, 1)),
        "isFlagged" INTEGER NOT NULL DEFAULT 0 CHECK ("isFlagged" IN (0, 1)),
        "notes" TEXT NOT NULL DEFAULT '',
        "priority" INTEGER,
        "remindersListID" INTEGER NOT NULL REFERENCES "remindersLists"("id"),
        "title" TEXT NOT NULL DEFAULT '',
        "updatedAt" TIMESTAMP NOT NULL
      )
      """)

        _ = try await self.execute("""
      CREATE INDEX "reminders_remindersListID" ON "reminders"("remindersListID")
      """)

        _ = try await self.execute("""
      CREATE TABLE "tags" (
        "id" SERIAL PRIMARY KEY,
        "title" TEXT NOT NULL DEFAULT ''
      )
      """)

        _ = try await self.execute("""
      CREATE TABLE "remindersTags" (
        "reminderID" INTEGER NOT NULL REFERENCES "reminders"("id"),
        "tagID" INTEGER NOT NULL REFERENCES "tags"("id"),
        PRIMARY KEY ("reminderID", "tagID")
      )
      """)

        _ = try await self.execute("""
      CREATE TABLE "milestones" (
        "id" SERIAL PRIMARY KEY,
        "remindersListID" INTEGER NOT NULL REFERENCES "remindersLists"("id"),
        "title" TEXT NOT NULL DEFAULT ''
      )
      """)

        // PostgreSQL-specific features table
        _ = try await self.execute("""
      CREATE TABLE "postgresDataTypes" (
        "id" SERIAL PRIMARY KEY,
        "uuid" UUID,
        "jsonData" BYTEA,
        "tags" TEXT,
        "metadata" TEXT,
        "ipAddress" TEXT,
        "createdAt" TIMESTAMP NOT NULL
      )
      """)
    }

    func seedDatabase() async throws {
        // Seed remindersLists
        _ = try await self.execute("""
      INSERT INTO "remindersLists" ("id", "color", "title", "position") VALUES
      (1, 16724735, 'Home', 1),
      (2, 1071759, 'Work', 2),
      (3, 4889071, 'School', 0)
      """)

        // Seed users
        _ = try await self.execute("""
      INSERT INTO "users" ("id", "name") VALUES
      (1, 'Alice'),
      (2, 'Bob')
      """)

        // Seed reminders
        _ = try await self.execute("""
      INSERT INTO "reminders" (
        "id", "assignedUserID", "dueDate", "isCompleted", "isFlagged",
        "notes", "priority", "remindersListID", "title", "updatedAt"
      ) VALUES
      (1, 1, '2024-02-14 12:00:00', 0, 0, 'Get flowers', 3, 1, 'Buy groceries', '2010-01-17 06:31:30'),
      (2, NULL, NULL, 0, 0, 'All purpose', 2, 1, 'Buy flour', '2010-01-17 06:31:30'),
      (3, NULL, NULL, 1, 1, '', NULL, 1, 'Buy eggs', '2010-01-17 06:31:30'),
      (4, 2, '2024-02-14 12:00:00', 0, 1, '', 1, 2, 'Call boss', '2010-01-17 06:31:30'),
      (5, NULL, NULL, 0, 0, '', NULL, 2, 'Send invoices', '2010-01-17 06:31:30'),
      (6, NULL, NULL, 0, 0, '', NULL, 3, 'Submit assignment', '2010-01-17 06:31:30')
      """)

        // Seed tags
        _ = try await self.execute("""
      INSERT INTO "tags" ("id", "title") VALUES
      (1, 'car'),
      (2, 'kids'),
      (3, 'someday'),
      (4, 'optional')
      """)

        // Seed remindersTags
        _ = try await self.execute("""
      INSERT INTO "remindersTags" ("reminderID", "tagID") VALUES
      (1, 1),
      (1, 2),
      (4, 3),
      (5, 3),
      (5, 4)
      """)

        // Seed milestones
        _ = try await self.execute("""
      INSERT INTO "milestones" ("id", "remindersListID", "title") VALUES
      (1, 1, 'Q1 Goals'),
      (2, 2, 'Project Deadline')
      """)

        // Seed PostgreSQL-specific data types
        _ = try await self.execute("""
      INSERT INTO "postgresDataTypes" (
        "id", "uuid", "jsonData", "tags", "metadata", "ipAddress", "createdAt"
      ) VALUES
      (1, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
       NULL,
       '["swift", "postgres", "testing"]',
       '{"environment": "test", "version": "1.0"}',
       '192.168.1.1',
       '2024-01-15 10:30:00')
      """)

        // Reset sequences to ensure predictable IDs
        // Note: PostgreSQL preserves case for quoted identifiers
        _ = try await self.execute("SELECT setval('\"remindersLists_id_seq\"', 3, true)")
        _ = try await self.execute("SELECT setval('users_id_seq', 2, true)")
        _ = try await self.execute("SELECT setval('reminders_id_seq', 6, true)")
        _ = try await self.execute("SELECT setval('tags_id_seq', 4, true)")
        _ = try await self.execute("SELECT setval('milestones_id_seq', 2, true)")
        _ = try await self.execute("SELECT setval('\"postgresDataTypes_id_seq\"', 1, true)")
    }
}

// MARK: - Dependency Configuration

extension PostgresConnection {
    public static func `default`() async throws -> PostgresConnection {
        let envVars = EnvironmentVariables.development

        let host = envVars["POSTGRES_HOST"] ?? "localhost"
        let port = envVars["POSTGRES_PORT"].flatMap(Int.init) ?? 5432
        let database = envVars["POSTGRES_DB"] ?? "swift-structured-queries-postgres"
        let username = envVars["POSTGRES_USER"] ?? "admin"
        let password = envVars["POSTGRES_PASSWORD"] ?? ""

        let config = PostgresConnection.Configuration(
            host: host,
            port: port,
            username: username,
            password: password,
            database: database,
            tls: .disable
        )

        return try await PostgresConnection.connect(
            configuration: config,
            id: 1,
            logger: Logger(label: "postgres-test")
        )
    }
}

extension PostgresQueryDatabase {
    public static func `default`(connection: PostgresConnection) async throws -> PostgresQueryDatabase {
        let db = PostgresQueryDatabase(connection: connection)

        // Initialize the database - fresh for each test run
        try await db.migrate()
        try await db.seedDatabase()

        return db
    }
}

// Global storage to keep the database connection alive throughout test suite
private final class TestDatabaseStorage: @unchecked Sendable {
    static let shared = TestDatabaseStorage()
    private var database: PostgresQueryDatabase?
    private var connection: PostgresConnection?  // Keep connection alive separately
    private let lock = NSLock()

    func getDatabase() throws -> PostgresQueryDatabase {
        lock.lock()
        defer { lock.unlock() }

        if let database = self.database {
            return database
        }

        // Create database and store connection separately to prevent deallocation
        let semaphore = DispatchSemaphore(value: 0)
        var result: Result<(PostgresQueryDatabase, PostgresConnection), Error>!

        Task.detached {
            do {
                let connection = try await PostgresConnection.default()
                let db: PostgresQueryDatabase = try! await PostgresQueryDatabase.default(connection: connection)

                result = .success((db, connection))
            } catch {
                result = .failure(error)
            }
            semaphore.signal()
        }

        semaphore.wait()
        let (db, conn) = try result.get()

        // Store both database and connection
        self.database = db
        self.connection = conn  // This keeps the connection alive

        return db
    }

    deinit {
        // Note: Can't close connection in deinit since it needs async
        // The connection will show a warning but tests will work
    }
}

private enum DefaultDatabaseKey: DependencyKey {
    static var liveValue: PostgresQueryDatabase {
        try! TestDatabaseStorage.shared.getDatabase()
    }
    static var testValue: PostgresQueryDatabase { liveValue }
}

extension DependencyValues {
    public var defaultDatabase: PostgresQueryDatabase {
        get { self[DefaultDatabaseKey.self] }
        set { self[DefaultDatabaseKey.self] = newValue }
    }
}
