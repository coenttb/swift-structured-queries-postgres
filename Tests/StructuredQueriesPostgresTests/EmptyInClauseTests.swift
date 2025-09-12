import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests {
    @Suite struct EmptyInClauseTests {

        @Test func emptyArrayInClause() {
            // Test that empty arrays generate valid PostgreSQL
            let emptyIds: [Int] = []

            assertInlineSnapshot(
                of: Reminder.where { $0.id.in(emptyIds) },
                as: .sql
            ) {
                """
                SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt"
                FROM "reminders"
                WHERE ("reminders"."id" IN (NULL))
                """
            }
        }

        @Test func emptyArrayInClauseWithOtherConditions() {
            // Test empty IN clause combined with other conditions
            let emptyAccountIds: [UUID] = []

            assertInlineSnapshot(
                of: GitHubAccount.where { account in
                    account.id.in(emptyAccountIds).and(account.isValid.eq(true))
                },
                as: .sql
            ) {
                """
                SELECT "github_accounts"."id", "github_accounts"."identityId", "github_accounts"."encryptedToken", "github_accounts"."tokenName", "github_accounts"."scopes", "github_accounts"."createdAt", "github_accounts"."lastValidatedAt", "github_accounts"."isValid"
                FROM "github_accounts"
                WHERE (("github_accounts"."id" IN (NULL)) AND ("github_accounts"."isValid" = true))
                """
            }
        }

        @Test func nonEmptyArrayInClause() {
            // Test that non-empty arrays still work correctly
            let ids = [1, 2, 3]

            assertInlineSnapshot(
                of: Reminder.where { $0.id.in(ids) },
                as: .sql
            ) {
                """
                SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt"
                FROM "reminders"
                WHERE ("reminders"."id" IN (1, 2, 3))
                """
            }
        }

        @Test func emptyStringArrayInClause() {
            // Test empty string array
            let emptyNames: [String] = []

            assertInlineSnapshot(
                of: Reminder.where { $0.title.in(emptyNames) },
                as: .sql
            ) {
                """
                SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt"
                FROM "reminders"
                WHERE ("reminders"."title" IN (NULL))
                """
            }
        }

        @Test func mixedConditionsWithEmptyIn() {
            // Test complex query with empty IN clause
            let emptyIds: [Int] = []

            assertInlineSnapshot(
                of: Reminder
                    .where { reminder in
                        reminder.id.in(emptyIds)
                            .or(reminder.remindersListID.eq(1))
                    }
                    .order { $0.updatedAt.desc() },
                as: .sql
            ) {
                """
                SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt"
                FROM "reminders"
                WHERE (("reminders"."id" IN (NULL)) OR ("reminders"."remindersListID" = 1))
                ORDER BY "reminders"."updatedAt" DESC
                """
            }
        }
    }
}

// Test table for GitHub account (simplified)
@Table("github_accounts")
struct GitHubAccount: Codable, Equatable, Identifiable {
    let id: UUID
    let identityId: UUID
    let encryptedToken: String
    let tokenName: String?
    @Column(as: [String].PostgresJSONB.self)
    let scopes: [String]
    let createdAt: Date
    let lastValidatedAt: Date?
    let isValid: Bool
}
