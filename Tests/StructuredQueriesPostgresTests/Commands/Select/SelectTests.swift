import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests.Commands.Select {
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
    @Test func selectAll() async {
      await assertSQL(of: Tag.all) {
        """
        SELECT "tags"."id", "tags"."title"
        FROM "tags"
        """
      }
    }
    //
    @Test func selectDistinct() async {
      await assertSQL(of: Reminder.distinct().select(\.priority)) {
        """
        SELECT DISTINCT "reminders"."priority"
        FROM "reminders"
        """
      }
    }

    @Test func selectDistinctOn() async {
      await assertSQL(
        of:
          Reminder
          .distinct(on: { $0.remindersListID })
          .order { $0.remindersListID }
          .select { ($0.id, $0.title) }
      ) {
        """
        SELECT DISTINCT ON ("reminders"."remindersListID") "reminders"."id", "reminders"."title"
        FROM "reminders"
        ORDER BY "reminders"."remindersListID"
        """
      }
    }

    @Test func selectDistinctOnMultiple() async {
      await assertSQL(
        of:
          Reminder
          .distinct { ($0.remindersListID, $0.priority) }
          .order { ($0.remindersListID, $0.priority, $0.updatedAt.desc()) }
          .select { ($0.id, $0.title) }
      ) {
        """
        SELECT DISTINCT ON ("reminders"."remindersListID", "reminders"."priority") "reminders"."id", "reminders"."title"
        FROM "reminders"
        ORDER BY "reminders"."remindersListID", "reminders"."priority", "reminders"."updatedAt" DESC
        """
      }
    }

    @Test func select() async {
      await assertSQL(of: Reminder.select { ($0.id, $0.title) }) {
        """
        SELECT "reminders"."id", "reminders"."title"
        FROM "reminders"
        """
      }
    }

    @Test func selectSingleColumn() async {
      await assertSQL(of: Tag.select(\.title)) {
        """
        SELECT "tags"."title"
        FROM "tags"
        """
      }
    }

    @Test func selectChaining() async {
      await assertSQL(of: Tag.select(\.id).select(\.title)) {
        """
        SELECT "tags"."id", "tags"."title"
        FROM "tags"
        """
      }
    }

    @Test func selectChainingWithJoin() async {
      await assertSQL(
        of:
          Reminder
          .select(\.id)
          .join(RemindersList.select(\.id)) { $0.remindersListID.eq($1.id) }
      ) {
        """
        SELECT "reminders"."id", "remindersLists"."id"
        FROM "reminders"
        JOIN "remindersLists" ON ("reminders"."remindersListID") = ("remindersLists"."id")
        """
      }
    }

    @Test func join() async {
      await assertSQL(
        of:
          Reminder
          .join(RemindersList.all) { $0.remindersListID.eq($1.id) }
      ) {
        """
        SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt", "remindersLists"."id", "remindersLists"."color", "remindersLists"."title", "remindersLists"."position"
        FROM "reminders"
        JOIN "remindersLists" ON ("reminders"."remindersListID") = ("remindersLists"."id")
        """
      }

      await assertSQL(
        of:
          RemindersList
          .join(Reminder.all) { $0.id.eq($1.remindersListID) }
          .select { ($0.title, $1.title) }
      ) {
        """
        SELECT "remindersLists"."title", "reminders"."title"
        FROM "remindersLists"
        JOIN "reminders" ON ("remindersLists"."id") = ("reminders"."remindersListID")
        """
      }

      await assertSQL(
        of: Reminder.all
          .leftJoin(User.all) { $0.assignedUserID.eq($1.id) }
          .select { ($0.title, $1.name) }
          .limit(2)
      ) {
        """
        SELECT "reminders"."title", "users"."name"
        FROM "reminders"
        LEFT OUTER JOIN "users" ON ("reminders"."assignedUserID") = ("users"."id")
        LIMIT 2
        """
      }
    }

    @Test func whereConditionalTrue() async {
      let includeConditional = true
      await assertSQL(
        of: Reminder.all
          .select(\.id)
          .where {
            if includeConditional {
              $0.isCompleted
            }
          }
      ) {
        """
        SELECT "reminders"."id"
        FROM "reminders"
        WHERE "reminders"."isCompleted"
        """
      }
    }
    //
    @Test func whereConditionalFalse() async {
      let includeConditional = false
      await assertSQL(
        of: Reminder.all
          .select(\.id)
          .where {
            if includeConditional {
              $0.isCompleted
            }
          }
      ) {
        """
        SELECT "reminders"."id"
        FROM "reminders"
        """
      }
    }

    @Test func limit() async {
      await assertSQL(of: Reminder.select(\.id).limit(2)) {
        """
        SELECT "reminders"."id"
        FROM "reminders"
        LIMIT 2
        """
      }
      await assertSQL(of: Reminder.select(\.id).limit(2, offset: 2)) {
        """
        SELECT "reminders"."id"
        FROM "reminders"
        LIMIT 2 OFFSET 2
        """
      }
    }

    @Test func rightJoin() async {
      await assertSQL(
        of: User.all
          .rightJoin(Reminder.all) { $0.id.is($1.assignedUserID) }
          .limit(2)
      ) {
        """
        SELECT "users"."id", "users"."name", "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt"
        FROM "users"
        RIGHT OUTER JOIN "reminders" ON ("users"."id") IS NOT DISTINCT FROM ("reminders"."assignedUserID")
        LIMIT 2
        """
      }
    }

    @Test func rightJoinWithSelect() async {
      await assertSQL(
        of: User.all
          .rightJoin(Reminder.all) { $0.id.is($1.assignedUserID) }
          .limit(2)
          .select { ($0, $1) }
      ) {
        """
        SELECT "users"."id", "users"."name", "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt"
        FROM "users"
        RIGHT OUTER JOIN "reminders" ON ("users"."id") IS NOT DISTINCT FROM ("reminders"."assignedUserID")
        LIMIT 2
        """
      }
    }

    @Test func rightJoinSelectColumns() async {
      await assertSQL(
        of: User.all
          .rightJoin(Reminder.all) { $0.id.is($1.assignedUserID) }
          .select { ($1.title, $0.name) }
          .limit(2)
      ) {
        """
        SELECT "reminders"."title", "users"."name"
        FROM "users"
        RIGHT OUTER JOIN "reminders" ON ("users"."id") IS NOT DISTINCT FROM ("reminders"."assignedUserID")
        LIMIT 2
        """
      }
    }

    @Test func fullJoin() async {
      await assertSQL(
        of: Reminder.all
          .fullJoin(User.all) { $0.assignedUserID.eq($1.id) }
          .select { ($0.title, $1.name) }
          .limit(2)
      ) {
        """
        SELECT "reminders"."title", "users"."name"
        FROM "reminders"
        FULL OUTER JOIN "users" ON ("reminders"."assignedUserID") = ("users"."id")
        LIMIT 2
        """
      }
    }

    @Test func whereClause() async {
      await assertSQL(of: Reminder.where(\.isCompleted)) {
        """
        SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt"
        FROM "reminders"
        WHERE "reminders"."isCompleted"
        """
      }
    }

    @Test func order() async {
      await assertSQL(
        of:
          Reminder
          .select(\.title)
          .order(by: \.title)
      ) {
        """
        SELECT "reminders"."title"
        FROM "reminders"
        ORDER BY "reminders"."title"
        """
      }

      await assertSQL(
        of:
          Reminder
          .select { ($0.isCompleted, $0.dueDate) }
          .order { ($0.isCompleted.asc(), $0.dueDate.desc()) }
      ) {
        """
        SELECT "reminders"."isCompleted", "reminders"."dueDate"
        FROM "reminders"
        ORDER BY "reminders"."isCompleted" ASC, "reminders"."dueDate" DESC
        """
      }

      await assertSQL(
        of:
          Reminder
          .select { ($0.priority, $0.dueDate) }
          .order {
            if true {
              (
                $0.priority.asc(nulls: .last),
                $0.dueDate.desc(nulls: .first),
                $0.title.desc()
              )
            }
          }
      ) {
        """
        SELECT "reminders"."priority", "reminders"."dueDate"
        FROM "reminders"
        ORDER BY "reminders"."priority" ASC NULLS LAST, "reminders"."dueDate" DESC NULLS FIRST, "reminders"."title" DESC
        """
      }
    }

    @Test func map() async {
      await assertSQL(of: Reminder.limit(1).select { ($0.id, $0.title) }.map { ($1, $0) }) {
        """
        SELECT "reminders"."title", "reminders"."id"
        FROM "reminders"
        LIMIT 1
        """
      }

      await assertSQL(of: Reminder.limit(1).select { ($0.id, $0.title) }.map { _, _ in }) {
        """
        SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt"
        FROM "reminders"
        LIMIT 1
        """
      }
    }

    @Test func none() {
      assertInlineSnapshot(of: Reminder.none, as: .sql) {
        """

        """
      }
    }

    @Test func selfJoin() async {
      enum R1: AliasName {}
      enum R2: AliasName {}
      await assertSQL(
        of: Reminder.as(R1.self)
          .join(Reminder.as(R2.self).all) { $0.id.eq($1.id) }
          .limit(1)
      ) {
        """
        SELECT "r1s"."id", "r1s"."assignedUserID", "r1s"."dueDate", "r1s"."isCompleted", "r1s"."isFlagged", "r1s"."notes", "r1s"."priority", "r1s"."remindersListID", "r1s"."title", "r1s"."updatedAt", "r2s"."id", "r2s"."assignedUserID", "r2s"."dueDate", "r2s"."isCompleted", "r2s"."isFlagged", "r2s"."notes", "r2s"."priority", "r2s"."remindersListID", "r2s"."title", "r2s"."updatedAt"
        FROM "reminders" AS "r1s"
        JOIN "reminders" AS "r2s" ON ("r1s"."id") = ("r2s"."id")
        LIMIT 1
        """
      }
    }

    @Test func selfLeftJoinSelect() async {
      enum R1: AliasName {}
      enum R2: AliasName {}
      await assertSQL(
        of: Reminder.as(R1.self)
          .leftJoin(Reminder.as(R2.self).all) { $0.id.eq($1.id) }
          .select { ($0.title, $1.title) }
          .limit(1)
      ) {
        """
        SELECT "r1s"."title", "r2s"."title"
        FROM "reminders" AS "r1s"
        LEFT OUTER JOIN "reminders" AS "r2s" ON ("r1s"."id") = ("r2s"."id")
        LIMIT 1
        """
      }
    }

    // TODO: Re-enable when Swift compiler bug is fixed (causes compiler hang)
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
    //         LEFT OUTER JOIN "reminders" AS "r2s" ON (("r1s"."id" = "r2s"."id") AND ("r1s"."id" = 42))
    //         GROUP BY "r1s"."id"
    //         LIMIT 1
    //         """
    //     }
    // }

    @Test func reusableStaticHelperOnDraft() async {
      await assertSQL(of: Reminder.incomplete.select(\.id)) {
        """
        SELECT "reminders"."id"
        FROM "reminders"
        WHERE NOT ("reminders"."isCompleted")
        """
      }

      await assertSQL(of: Reminder.incomplete.where { _ in true }.select(\.id)) {
        """
        SELECT "reminders"."id"
        FROM "reminders"
        WHERE NOT ("reminders"."isCompleted") AND true
        """
      }

      await assertSQL(of: Reminder.incomplete.select(\.id)) {
        """
        SELECT "reminders"."id"
        FROM "reminders"
        WHERE NOT ("reminders"."isCompleted")
        """
      }

      await assertSQL(of: Reminder.incomplete.select(\.id)) {
        """
        SELECT "reminders"."id"
        FROM "reminders"
        WHERE NOT ("reminders"."isCompleted")
        """
      }
    }

    @Test func reusableColumnHelperOnDraft() async {
      await assertSQL(of: Reminder.select(\.isHighPriority)) {
        """
        SELECT ("reminders"."priority") = (3)
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
