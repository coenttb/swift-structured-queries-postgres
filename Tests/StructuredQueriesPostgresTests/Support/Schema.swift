import Dependencies
import Foundation
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport

@Table
struct RemindersList: Codable, Equatable, Identifiable {
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
}

extension Reminder.TableColumns {
    var isHighPriority: some QueryExpression<Bool> {
        priority == Priority.high
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

@Table struct Milestone: Codable, Equatable {
    let id: Int
    var remindersListID: RemindersList.ID
    var title = ""
}

@Table("reminders_audit")
struct RemindersAudit: Codable, Equatable, AuditTable {
    let id: Int
    var tableName: String
    var operation: String
    var oldData: String?  // JSONB stored as string
    var newData: String?  // JSONB stored as string
    var changedAt: Date
    var changedBy: String
}

@Table
struct Order: Codable, Equatable, Identifiable {
    let id: Int
    var orderID: Int
    var customerID: Int
    var amount: Double
    var quantity: Double  // Changed to Double for math operations
    var unitPrice: Double
    var discount: Double?
    var isPaid: Bool = false
    var createdAt: Date = Date(timeIntervalSinceReferenceDate: 0)
}

@Table
struct Customer: Codable, Equatable, Identifiable {
    let id: Int
    var name = ""
}

@Table
struct LineItem: Codable, Equatable {
    let id: Int
    var orderID: Int
    var price: Double
    var quantity: Double  // Changed to Double for math operations
}

// Database migration, trigger installation, and seed data code removed.
// This file contained SQLite-specific features:
// - FTS5 virtual tables (PostgreSQL uses different full-text search)
// - SQLite temporary triggers (PostgreSQL has different trigger syntax)
// - SQLite-specific SQL syntax (datetime('subsec'), etc.)
//
// Database operations, migrations, and seed data belong in swift-records package
// where database integration is handled. This package is DSL-focused.
