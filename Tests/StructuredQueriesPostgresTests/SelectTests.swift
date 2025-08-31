import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests {
    @Suite struct SelectTests {
        func compileTimeTests() {
            _ = Reminder.select(\.id)
            _ = Reminder.select { $0.id }
            _ = Reminder.select { ($0.id, $0.isCompleted) }
            _ = Reminder.all.select(\.id)
            _ = Reminder.all.select { $0.id }
            _ = Reminder.all.select { ($0.id, $0.isCompleted) }
            _ = Reminder.where(\.isCompleted).select(\.id)
            _ = Reminder.where(\.isCompleted).select { $0.id }
            _ = Reminder.where(\.isCompleted).select { ($0.id, $0.isCompleted) }
            
            let condition1 = Int?.some(1) == 2
            #expect(condition1 == false)
            let condition2 = Int?.some(1) != 2
            #expect(condition2 == true)
        }
        //
        @Test func selectAll() {
            assertInlineSnapshot(
                of: Tag.all,
                as: .sql
            ) {
                """
                SELECT "tags"."id", "tags"."title"
                FROM "tags"
                """
            }
        }
        //
        @Test func selectDistinct() {
            assertInlineSnapshot(
                of: Reminder.distinct().select(\.priority),
                as: .sql
            ) {
                """
                SELECT DISTINCT "reminders"."priority"
                FROM "reminders"
                """
            }
        }
        //
        @Test func select() {
            assertInlineSnapshot(
                of: Reminder.select { ($0.id, $0.title) },
                as: .sql
            ) {
                """
                SELECT "reminders"."id", "reminders"."title"
                FROM "reminders"
                """
            }
        }
        
        @Test func selectSingleColumn() {
            assertInlineSnapshot(
                of: Tag.select(\.title),
                as: .sql
            ) {
                """
                SELECT "tags"."title"
                FROM "tags"
                """
            }
        }
        
        @Test func selectChaining() {
            assertInlineSnapshot(
                of: Tag.select(\.id).select(\.title),
                as: .sql
            ) {
                """
                SELECT "tags"."id", "tags"."title"
                FROM "tags"
                """
            }
        }
        
        @Test func selectChainingWithJoin() {
            assertInlineSnapshot(
                of: Reminder
                    .select(\.id)
                    .join(RemindersList.select(\.id)) { $0.remindersListID.eq($1.id) },
                as: .sql
            ) {
                """
                SELECT "reminders"."id", "remindersLists"."id"
                FROM "reminders"
                JOIN "remindersLists" ON ("reminders"."remindersListID" = "remindersLists"."id")
                """
            }
        }
        
        @Test func join() {
            assertInlineSnapshot(
                of: Reminder
                    .join(RemindersList.all) { $0.remindersListID.eq($1.id) },
                as: .sql
            ) {
                """
                SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt", "remindersLists"."id", "remindersLists"."color", "remindersLists"."title", "remindersLists"."position"
                FROM "reminders"
                JOIN "remindersLists" ON ("reminders"."remindersListID" = "remindersLists"."id")
                """
            }
            
            assertInlineSnapshot(
                of: RemindersList
                    .join(Reminder.all) { $0.id.eq($1.remindersListID) }
                    .select { ($0.title, $1.title) },
                as: .sql
            ) {
                """
                SELECT "remindersLists"."title", "reminders"."title"
                FROM "remindersLists"
                JOIN "reminders" ON ("remindersLists"."id" = "reminders"."remindersListID")
                """
            }
            
            assertInlineSnapshot(
                of: Reminder.all
                    .leftJoin(User.all) { $0.assignedUserID.eq($1.id) }
                    .select { ($0.title, $1.name) }
                    .limit(2),
                as: .sql
            ) {
                """
                SELECT "reminders"."title", "users"."name"
                FROM "reminders"
                LEFT JOIN "users" ON ("reminders"."assignedUserID" = "users"."id")
                LIMIT 2
                """
            }
        }
        
        @Test func whereConditionalTrue() {
            let includeConditional = true
            assertInlineSnapshot(
                of: Reminder.all
                    .select(\.id)
                    .where {
                        if includeConditional {
                            $0.isCompleted
                        }
                    },
                as: .sql
            ) {
                """
                SELECT "reminders"."id"
                FROM "reminders"
                WHERE "reminders"."isCompleted"
                """
            }
        }
        //
        @Test func whereConditionalFalse() {
            let includeConditional = false
            assertInlineSnapshot(
                of: Reminder.all
                    .select(\.id)
                    .where {
                        if includeConditional {
                            $0.isCompleted
                        }
                    },
                as: .sql
            ) {
                """
                SELECT "reminders"."id"
                FROM "reminders"
                """
            }
        }
        
        @Test func limit() {
            assertInlineSnapshot(
                of: Reminder.select(\.id).limit(2),
                as: .sql
            ) {
                """
                SELECT "reminders"."id"
                FROM "reminders"
                LIMIT 2
                """
            }
            assertInlineSnapshot(
                of: Reminder.select(\.id).limit(2, offset: 2),
                as: .sql
            ) {
                """
                SELECT "reminders"."id"
                FROM "reminders"
                LIMIT 2 OFFSET 2
                """
            }
        }

        
        @Test func rightJoin() {
            assertInlineSnapshot(
                of: User.all
                    .rightJoin(Reminder.all) { $0.id.is($1.assignedUserID) }
                    .limit(2),
                as: .sql
            ) {
                """
                SELECT "users"."id", "users"."name", "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt"
                FROM "users"
                RIGHT JOIN "reminders" ON ("users"."id" IS "reminders"."assignedUserID")
                LIMIT 2
                """
            }
        }
        
        @Test func rightJoinWithSelect() {
            assertInlineSnapshot(
                of: User.all
                    .rightJoin(Reminder.all) { $0.id.is($1.assignedUserID) }
                    .limit(2)
                    .select { ($0, $1) },
                as: .sql
            ) {
                """
                SELECT "users"."id", "users"."name", "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt"
                FROM "users"
                RIGHT JOIN "reminders" ON ("users"."id" IS "reminders"."assignedUserID")
                LIMIT 2
                """
            }
        }
        
        @Test func rightJoinSelectColumns() {
            assertInlineSnapshot(
                of: User.all
                    .rightJoin(Reminder.all) { $0.id.is($1.assignedUserID) }
                    .select { ($1.title, $0.name) }
                    .limit(2),
                as: .sql
            ) {
                """
                SELECT "reminders"."title", "users"."name"
                FROM "users"
                RIGHT JOIN "reminders" ON ("users"."id" IS "reminders"."assignedUserID")
                LIMIT 2
                """
            }
        }
        
        @Test func fullJoin() {
            assertInlineSnapshot(
                of: Reminder.all
                    .fullJoin(User.all) { $0.assignedUserID.eq($1.id) }
                    .select { ($0.title, $1.name) }
                    .limit(2),
                as: .sql
            ) {
                """
                SELECT "reminders"."title", "users"."name"
                FROM "reminders"
                FULL JOIN "users" ON ("reminders"."assignedUserID" = "users"."id")
                LIMIT 2
                """
            }
        }
        
        @Test func whereClause() {
            assertInlineSnapshot(
                of: Reminder.where(\.isCompleted),
                as: .sql
            ) {
                """
                SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt"
                FROM "reminders"
                WHERE "reminders"."isCompleted"
                """
            }
        }
        
        
        
        @Test func order() {
            assertInlineSnapshot(
                of: Reminder
                    .select(\.title)
                    .order(by: \.title),
                as: .sql
            ) {
                """
                SELECT "reminders"."title"
                FROM "reminders"
                ORDER BY "reminders"."title"
                """
            }
            
            assertInlineSnapshot(
                of: Reminder
                    .select { ($0.isCompleted, $0.dueDate) }
                    .order { ($0.isCompleted.asc(), $0.dueDate.desc()) },
                as: .sql
            ) {
                """
                SELECT "reminders"."isCompleted", "reminders"."dueDate"
                FROM "reminders"
                ORDER BY "reminders"."isCompleted" ASC, "reminders"."dueDate" DESC
                """
            }
            
            assertInlineSnapshot(
                of: Reminder
                    .select { ($0.priority, $0.dueDate) }
                    .order {
                        if true {
                            (
                                $0.priority.asc(nulls: .last),
                                $0.dueDate.desc(nulls: .first),
                                $0.title.desc()
                            )
                        }
                    },
                as: .sql
            ) {
                """
                SELECT "reminders"."priority", "reminders"."dueDate"
                FROM "reminders"
                ORDER BY "reminders"."priority" ASC NULLS LAST, "reminders"."dueDate" DESC NULLS FIRST, "reminders"."title" DESC
                """
            }
        }
        
        @Test func map() {
            assertInlineSnapshot(
                of: Reminder.limit(1).select { ($0.id, $0.title) }.map { ($1, $0) },
                as: .sql
            ) {
                """
                SELECT "reminders"."title", "reminders"."id"
                FROM "reminders"
                LIMIT 1
                """
            }
            
            assertInlineSnapshot(
                of: Reminder.limit(1).select { ($0.id, $0.title) }.map { _, _ in },
                as: .sql
            ) {
                """
                SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt"
                FROM "reminders"
                LIMIT 1
                """
            }
        }
        
        @Test func none() {
            assertInlineSnapshot(
                of: Reminder.none,
                as: .sql
            ) {
                """
                
                """
            }
        }
        
        @Test func selfJoin() {
            enum R1: AliasName {}
            enum R2: AliasName {}
            assertInlineSnapshot(
                of: Reminder.as(R1.self)
                    .join(Reminder.as(R2.self).all) { $0.id.eq($1.id) }
                    .limit(1),
                as: .sql
            ) {
                """
                SELECT "r1s"."id", "r1s"."assignedUserID", "r1s"."dueDate", "r1s"."isCompleted", "r1s"."isFlagged", "r1s"."notes", "r1s"."priority", "r1s"."remindersListID", "r1s"."title", "r1s"."updatedAt", "r2s"."id", "r2s"."assignedUserID", "r2s"."dueDate", "r2s"."isCompleted", "r2s"."isFlagged", "r2s"."notes", "r2s"."priority", "r2s"."remindersListID", "r2s"."title", "r2s"."updatedAt"
                FROM "reminders" AS "r1s"
                JOIN "reminders" AS "r2s" ON ("r1s"."id" = "r2s"."id")
                LIMIT 1
                """
            }
        }
        
        @Test func selfLeftJoinSelect() {
            enum R1: AliasName {}
            enum R2: AliasName {}
            assertInlineSnapshot(
                of: Reminder.as(R1.self)
                    .leftJoin(Reminder.as(R2.self).all) { $0.id.eq($1.id) }
                    .select { ($0.title, $1.title) }
                    .limit(1),
                as: .sql
            ) {
                """
                SELECT "r1s"."title", "r2s"."title"
                FROM "reminders" AS "r1s"
                LEFT JOIN "reminders" AS "r2s" ON ("r1s"."id" = "r2s"."id")
                LIMIT 1
                """
            }
        }
        
        // TODO: Re-enable when Swift compiler bug is fixed
        // @Test func forceEmptyJoin() {
        //     enum R1: AliasName {}
        //     enum R2: AliasName {}
        //     assertInlineSnapshot(
        //         of: Reminder.as(R1.self)
        //             .group(by: \.id)
        //             .leftJoin(Reminder.as(R2.self).all) { $0.id.eq($1.id) && $0.id.eq(42) }
        //             .limit(1)
        //             .select { ($0, $1.jsonAgg().filter(where: $1.id.isNotNull)) },
        //         as: .sql
        //     ) {
        //         """
        //         SELECT "r1s"."id", "r1s"."assignedUserID", "r1s"."dueDate", "r1s"."isCompleted", "r1s"."isFlagged", "r1s"."notes", "r1s"."priority", "r1s"."remindersListID", "r1s"."title", "r1s"."updatedAt", json_agg("r2s") FILTER (WHERE ("r2s"."id" IS NOT NULL))
        //         FROM "reminders" AS "r1s"
        //         LEFT JOIN "reminders" AS "r2s" ON (("r1s"."id" = "r2s"."id") AND ("r1s"."id" = 42))
        //         GROUP BY "r1s"."id"
        //         LIMIT 1
        //         """
        //     }
        // }
        
        
        // TODO: Re-enable when Swift compiler bug is fixed
        // @Test func vec0() {
        //     let xs = [0.890, 0.544, 0.825, 0.961, 0.358, 0.0196, 0.521, 0.175]
        //     assertInlineSnapshot(
        //         of:
        //             VecExample
        //             .where { _ in
        //                 #sql("sample_embedding match \(#bind(xs, as: [Double].JSONRepresentation.self))")
        //             }
        //             .order(by: \.distance)
        //             .limit(2),
        //         as: .sql
        //     ) {
        //         """
        //         SELECT "vecExamples"."rowid", "vecExamples"."distance"
        //         FROM "vecExamples"
        //         WHERE sample_embedding match '[
        //           0.89,
        //           0.544,
        //           0.825,
        //           0.961,
        //           0.358,
        //           0.0196,
        //           0.521,
        //           0.175
        //         ]'
        //         ORDER BY "vecExamples"."distance"
        //         LIMIT 2
        //         """
        //     }
        // }
        
        
        
        @Test func reusableStaticHelperOnDraft() {
            assertInlineSnapshot(
                of: Reminder.Draft.incomplete.select(\.id),
                as: .sql
            ) {
                """
                SELECT "reminders"."id"
                FROM "reminders"
                WHERE NOT ("reminders"."isCompleted")
                """
            }
            
            assertInlineSnapshot(
                of: Reminder.Draft.where { _ in true }.incomplete.select(\.id),
                as: .sql
            ) {
                """
                SELECT "reminders"."id"
                FROM "reminders"
                WHERE true AND NOT ("reminders"."isCompleted")
                """
            }
            
            assertInlineSnapshot(
                of: Reminder.Draft.select(\.id).incomplete,
                as: .sql
            ) {
                """
                SELECT "reminders"."id"
                FROM "reminders"
                WHERE NOT ("reminders"."isCompleted")
                """
            }
            
            assertInlineSnapshot(
                of: Reminder.Draft.all.incomplete.select(\.id),
                as: .sql
            ) {
                """
                SELECT "reminders"."id"
                FROM "reminders"
                WHERE NOT ("reminders"."isCompleted")
                """
            }
        }
        
        @Test func reusableColumnHelperOnDraft() {
            assertInlineSnapshot(
                of: Reminder.Draft.select(\.isHighPriority),
                as: .sql
            ) {
                """
                SELECT ("reminders"."priority" = 3)
                FROM "reminders"
                """
            }
        }
        
        @Test func singleJoinChaining() {
            let base = Reminder.group(by: \.id).join(ReminderTag.all) { $0.id.eq($1.reminderID) }
            _ = base.select { r, _ in r.isCompleted }
            _ = base.join(RemindersList.all) { _, _, _ in true }
            _ = base.leftJoin(RemindersList.all) { _, _, _ in true }
            _ = base.rightJoin(RemindersList.all) { _, _, _ in true }
            _ = base.fullJoin(RemindersList.all) { _, _, _ in true }
            _ =
            base
                .join(RemindersList.all) { _, _, _ in true }
                .join(RemindersList.all) { _, _, _, _ in true }
            _ =
            base
                .leftJoin(RemindersList.all) { _, _, _ in true }
                .leftJoin(RemindersList.all) { _, _, _, _ in true }
            _ =
            base
                .rightJoin(RemindersList.all) { _, _, _ in true }
                .rightJoin(RemindersList.all) { _, _, _, _ in true }
            _ =
            base
                .fullJoin(RemindersList.all) { _, _, _ in true }
                .fullJoin(RemindersList.all) { _, _, _, _ in true }
            _ = base.where { r, _ in r.isCompleted }
            _ = base.group { r, _ in r.isCompleted }
            _ = base.having { r, _ in r.isCompleted }
            _ = base.order { r, _ in r.isCompleted }
//            _ = base.limit { r, _ in r.title.length() }
            _ = base.limit(1)
//            _ = base.count()
//            _ = base.count { r, _ in r.isCompleted }
            _ = base.map {}
        }
    }
}

extension Reminder.TableColumns {
    var isHighPriority: some QueryExpression<Bool> {
        self.priority == Priority.high
    }
}
