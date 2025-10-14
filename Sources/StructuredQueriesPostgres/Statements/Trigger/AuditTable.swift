import Foundation
import StructuredQueriesCore

/// A marker protocol for tables that can store audit logs.
///
/// Conform your audit table to this protocol to enable type-safe audit logging with trigger
/// functions. This protocol ensures that only properly structured audit tables can be used
/// with `Trigger.Function.auditLog()`.
///
/// ## Required Schema
///
/// Your audit table must have these columns:
/// - `tableName: String` - The name of the audited table
/// - `operation: String` - The operation type (INSERT, UPDATE, DELETE)
/// - `oldData: String?` - JSONB of the old row (NULL for INSERT)
/// - `newData: String?` - JSONB of the new row (NULL for DELETE)
/// - `changedAt: Date` - Timestamp of the change
/// - `changedBy: String` - User who made the change
///
/// ## Example
///
/// ```swift
/// @Table("user_audit")
/// struct UserAudit: Codable, AuditTable {
///     let id: Int
///     var tableName: String
///     var operation: String
///     var oldData: String?  // JSONB stored as string
///     var newData: String?  // JSONB stored as string
///     var changedAt: Date
///     var changedBy: String
/// }
///
/// // Now you can use it with auditLog:
/// let func = Trigger.Function<User>.auditLog("audit_users", to: UserAudit.self)
/// ```
///
/// ## PostgreSQL Schema
///
/// When creating your audit table in PostgreSQL, use this schema:
///
/// ```sql
/// CREATE TABLE "userAudit" (
///     id SERIAL PRIMARY KEY,
///     "tableName" TEXT NOT NULL,
///     operation TEXT NOT NULL,
///     "oldData" JSONB,
///     "newData" JSONB,
///     "changedAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
///     "changedBy" TEXT NOT NULL DEFAULT current_user
/// );
/// ```
///
/// ## Type Safety
///
/// The protocol provides compile-time validation:
///
/// ```swift
/// // ✅ Compiles - UserAudit conforms to AuditTable
/// Trigger.Function<User>.auditLog(to: UserAudit.self)
///
/// // ❌ Compile error - Product doesn't conform to AuditTable
/// Trigger.Function<User>.auditLog(to: Product.self)
/// // Error: Type 'Product' does not conform to protocol 'AuditTable'
/// ```
public protocol AuditTable: Table {}
