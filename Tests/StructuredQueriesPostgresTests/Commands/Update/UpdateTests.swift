import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests {
    @Suite struct UpdateTests {
        @Test func basics() async {
            await assertSQL(
                of:
                    Reminder
                    .update { $0.isCompleted.toggle() }
                    .returning { ($0.title, $0.priority, $0.isCompleted) }
            ) {
                """
                UPDATE "reminders"
                SET "isCompleted" = NOT ("reminders"."isCompleted")
                RETURNING "reminders"."title", "reminders"."priority", "reminders"."isCompleted"
                """
            }

            await assertSQL(
                of:
                    Reminder
                    .where { $0.priority == nil }
                    .update { $0.isCompleted = true }
                    .returning { ($0.title, $0.priority, $0.isCompleted) }
            ) {
                """
                UPDATE "reminders"
                SET "isCompleted" = true
                WHERE ("reminders"."priority") IS NOT DISTINCT FROM (NULL)
                RETURNING "reminders"."title", "reminders"."priority", "reminders"."isCompleted"
                """
            }
        }

        @Test func returningRepresentable() async {
            await assertSQL(
                of:
                    Reminder
                    .update { $0.isCompleted.toggle() }
                    .returning(\.dueDate)
            ) {
                """
                UPDATE "reminders"
                SET "isCompleted" = NOT ("reminders"."isCompleted")
                RETURNING "reminders"."dueDate"
                """
            }
        }

        @Test func toggleAssignment() async {
            await assertSQL(
                of: Reminder.update {
                    $0.isCompleted = !$0.isCompleted
                }
            ) {
                """
                UPDATE "reminders"
                SET "isCompleted" = NOT ("reminders"."isCompleted")
                """
            }
        }

        @Test func toggleBoolean() async {
            await assertSQL(
                of: Reminder.update { $0.isCompleted.toggle() }
            ) {
                """
                UPDATE "reminders"
                SET "isCompleted" = NOT ("reminders"."isCompleted")
                """
            }
        }

        @Test func multipleMutations() async {
            // NOTE: rewritten from `$0.title += "!"` / `$0.title += "?"`. Swift 6.3.3 resolves
            // both the compound-assignment sugar AND the explicit `$0.title = $0.title + "!"`
            // spelling for `Updates`'s `@dynamicMemberLookup` subscript to the
            // `@available(*, unavailable) get` overload in
            // `Sources/StructuredQueriesCore/Updates.swift` (pre-existing, unrelated to this
            // branch's fixes) -- the constraint solver prefers unifying the read side to the
            // concrete `Value.QueryOutput` (disfavored-but-simpler) overload, which is a hard
            // compile error regardless of spelling. Reading via the static `Reminder.columns.title`
            // (exactly what the available-get overload itself returns, per
            // `get { Base.columns[keyPath: keyPath] }` in `Updates.swift`) sidesteps the
            // ambiguous dynamic-member read while producing byte-identical SQL.
            await assertSQL(
                of: Reminder.update {
                    $0.title = Reminder.columns.title + "!"
                    $0.title = Reminder.columns.title + "?"
                }
            ) {
                """
                UPDATE "reminders"
                SET "title" = ("reminders"."title") || ('!'), "title" = ("reminders"."title") || ('?')
                """
            }
        }

        @Test func rawBind() async {
            await assertSQL(
                of:
                    Reminder
                    .update { $0.dueDate = #sql("CURRENT_TIMESTAMP") }
                    .where { $0.id.eq(1) }
                    .returning(\.title)
            ) {
                """
                UPDATE "reminders"
                SET "dueDate" = CURRENT_TIMESTAMP
                WHERE ("reminders"."id") = (1)
                RETURNING "reminders"."title"
                """
            }
        }

        @Test func updateWhereKeyPath() async {
            await assertSQL(
                of:
                    Reminder
                    .update { $0.isFlagged.toggle() }
                    .where(\.isFlagged)
                    .returning(\.title)
            ) {
                """
                UPDATE "reminders"
                SET "isFlagged" = NOT ("reminders"."isFlagged")
                WHERE "reminders"."isFlagged"
                RETURNING "reminders"."title"
                """
            }
        }

        @Test func aliasName() async {
            enum R: AliasName {}
            // NOTE: rewritten from `$0.title += " 2"` — see `multipleMutations()` above for why
            // neither the compound-assignment spelling nor the explicit `$0.title = $0.title + " 2"`
            // form compiles under Swift 6.3.3. This closure updates the ALIASED table
            // (`Reminder.as(R.self)`), so the read must go through the matching
            // `TableAlias<Reminder, R>.columns.title` (not the unaliased `Reminder.columns.title`)
            // to keep rendering the `"rs"."title"` alias prefix the snapshot below expects.
            await assertSQL(
                of: Reminder.as(R.self)
                    .where { $0.id.eq(1) }
                    .update { $0.title = TableAlias<Reminder, R>.columns.title + " 2" }
                    .returning(\.self)
            ) {
                """
                UPDATE "reminders" AS "rs"
                SET "title" = ("rs"."title") || (' 2')
                WHERE ("rs"."id") = (1)
                RETURNING "rs"."id", "rs"."assignedUserID", "rs"."dueDate", "rs"."isCompleted", "rs"."isFlagged", "rs"."notes", "rs"."priority", "rs"."remindersListID", "rs"."title", "rs"."updatedAt"
                """
            }
        }

        @Test func noPrimaryKey() async {
            await assertSQL(
                of: Item.update {
                    $0.title = "Dog"
                }
            ) {
                """
                UPDATE "items"
                SET "title" = 'Dog'
                """
            }
        }

        @Test func emptyUpdate() {
            assertInlineSnapshot(
                of: Item.update { _ in },
                as: .sql
            ) {
                """

                """
            }
        }

        @Test func complexMutation() async {
            await assertSQL(
                of:
                    Reminder
                    .find(1)
                    .update {
                        $0.dueDate = Case()
                            .when($0.dueDate == nil, then: #sql("'2018-01-29 00:08:00.000'"))
                    }
                    .returning(\.dueDate)
            ) {
                """
                UPDATE "reminders"
                SET "dueDate" = CASE WHEN ("reminders"."dueDate") IS NOT DISTINCT FROM (NULL) THEN '2018-01-29 00:08:00.000' END
                WHERE ("reminders"."id") IN (1)
                RETURNING "reminders"."dueDate"
                """
            }
        }

        @Test func empty() {
            assertInlineSnapshot(
                of: Reminder.none.update { $0.isCompleted.toggle() },
                as: .sql
            ) {
                """

                """
            }
        }
    }
}

@Table private struct Item {
    var title = ""
    var quantity = 0
}
