import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests {
    @Suite struct TableTests {
        // Tests for default scopes (soft delete pattern)

        @Table
        struct SoftDeleteRow {
            static let all = unscoped.where { !$0.isDeleted }.order { $0.id.desc() }
            let id: Int
            var isDeleted = false
        }

        @Test func defaultScopeAppliesWhereClause() async {
            // Default scope automatically adds WHERE and ORDER BY
            await assertSQL(of: SoftDeleteRow.where { $0.id > 0 }) {
                """
                SELECT "softDeleteRows"."id", "softDeleteRows"."isDeleted"
                FROM "softDeleteRows"
                WHERE NOT ("softDeleteRows"."isDeleted") AND ("softDeleteRows"."id") > (0)
                ORDER BY "softDeleteRows"."id" DESC
                """
            }
        }

        @Test func unscopedRemovesDefaultScope() async {
            // .unscoped removes the default WHERE and ORDER BY
            await assertSQL(of: SoftDeleteRow.unscoped) {
                """
                SELECT "softDeleteRows"."id", "softDeleteRows"."isDeleted"
                FROM "softDeleteRows"
                """
            }
        }

        @Test func defaultScopeWithTableAlias() async {
            enum R: AliasName {}
            // Table aliases preserve the default scope
            await assertSQL(of: SoftDeleteRow.as(R.self).select(\.id)) {
                """
                SELECT "rs"."id"
                FROM "softDeleteRows" AS "rs"
                WHERE NOT ("rs"."isDeleted")
                ORDER BY "rs"."id" DESC
                """
            }
            // .unscoped works with aliases too
            await assertSQL(of: SoftDeleteRow.as(R.self).unscoped.select(\.id)) {
                """
                SELECT "rs"."id"
                FROM "softDeleteRows" AS "rs"
                """
            }
        }

        @Test func defaultScopeInDeleteStatements() async {
            // Default scope applies to DELETE statements
            await assertSQL(
                of:
                    SoftDeleteRow
                    .where { $0.id > 0 }
                    .delete()
                    .returning(\.self)
            ) {
                """
                DELETE FROM "softDeleteRows"
                WHERE NOT ("softDeleteRows"."isDeleted") AND ("softDeleteRows"."id") > (0)
                RETURNING "id", "isDeleted"
                """
            }
            // .unscoped allows deleting all rows
            await assertSQL(
                of: SoftDeleteRow
                    .unscoped
                    .where { $0.id > 0 }
                    .delete()
                    .returning(\.self)
            ) {
                """
                DELETE FROM "softDeleteRows"
                WHERE ("softDeleteRows"."id") > (0)
                RETURNING "id", "isDeleted"
                """
            }
        }

        @Test func defaultScopeInUpdateStatements() async {
            // Default scope applies to UPDATE statements
            await assertSQL(
                of:
                    SoftDeleteRow
                    .update { $0.isDeleted.toggle() }
                    .where { $0.id > 0 }
                    .returning(\.self)
            ) {
                """
                UPDATE "softDeleteRows"
                SET "isDeleted" = NOT ("softDeleteRows"."isDeleted")
                WHERE NOT ("softDeleteRows"."isDeleted") AND ("softDeleteRows"."id") > (0)
                RETURNING "softDeleteRows"."id", "softDeleteRows"."isDeleted"
                """
            }
            // .unscoped allows updating all rows
            await assertSQL(
                of: SoftDeleteRow
                    .unscoped
                    .where { $0.id > 0 }
                    .update { $0.isDeleted.toggle() }
                    .returning(\.self)
            ) {
                """
                UPDATE "softDeleteRows"
                SET "isDeleted" = NOT ("softDeleteRows"."isDeleted")
                WHERE ("softDeleteRows"."id") > (0)
                RETURNING "softDeleteRows"."id", "softDeleteRows"."isDeleted"
                """
            }
        }
    }
}
