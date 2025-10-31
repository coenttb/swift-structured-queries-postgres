import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests {
  @Suite struct SQLSyntaxTests {

    @Test func returningVariations() async {
      // RETURNING * - Standard SQL (supported by PostgreSQL, SQLite 3.35.0+, and others)
      await assertSQL(
        of: Reminder.insert {
          Reminder(id: 1, remindersListID: 1, title: "Test")
        }.returning(\.self)
      ) {
        """
        INSERT INTO "reminders"
        ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
        VALUES
        (1, NULL, NULL, false, false, '', NULL, 1, 'Test', '2040-02-14 23:31:30.000')
        RETURNING "id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt"
        """
      }

      // RETURNING multiple columns
      await assertSQL(
        of: Reminder.insert {
          Reminder(id: 1, remindersListID: 1, title: "Test")
        }.returning { ($0.id, $0.title, $0.updatedAt) }
      ) {
        """
        INSERT INTO "reminders"
        ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
        VALUES
        (1, NULL, NULL, false, false, '', NULL, 1, 'Test', '2040-02-14 23:31:30.000')
        RETURNING "id", "title", "updatedAt"
        """
      }
    }

    @Test func defaultValuesSQL() async {
      // INSERT with DEFAULT - Standard SQL
      await assertSQL(
        of: #sql(
          """
          INSERT INTO "reminders" ("id", "remindersListID", "title")
          VALUES (DEFAULT, 1, 'Default ID test')
          """)
      ) {
        """
        INSERT INTO "reminders" ("id", "remindersListID", "title")
        VALUES (DEFAULT, 1, 'Default ID test')
        """
      }
    }

    @Test func inClause() async {
      // Standard IN clause
      await assertSQL(
        of: Reminder.where { reminder in
          #sql("\(reminder.priority) IN (1, 2, 3)")
        }
      ) {
        """
        SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt"
        FROM "reminders"
        WHERE "reminders"."priority" IN (1, 2, 3)
        """
      }
    }

    @Test func coalesceFunctions() async {
      // COALESCE - Standard SQL function
      await assertSQL(
        of: Reminder.select {
          #sql("COALESCE(\($0.notes), 'No notes')", as: String.self)
        }
      ) {
        """
        SELECT COALESCE("reminders"."notes", 'No notes')
        FROM "reminders"
        """
      }
    }

    @Test func cteWithInsertSQL() async {
      // CTE with INSERT ... RETURNING - Standard SQL
      await assertSQL(
        of: #sql(
          """
          WITH inserted AS (
              INSERT INTO "reminders" ("remindersListID", "title")
              VALUES (1, 'New Task')
              RETURNING "id"
          )
          SELECT * FROM inserted
          """)
      ) {
        """
        WITH inserted AS (
            INSERT INTO "reminders" ("remindersListID", "title")
            VALUES (1, 'New Task')
            RETURNING "id"
        )
        SELECT * FROM inserted
        """
      }
    }

    @Test func windowFunctions() async {
      // ROW_NUMBER() OVER - Standard SQL window function
      await assertSQL(
        of: #sql(
          """
          SELECT
              "id",
              "title",
              ROW_NUMBER() OVER (PARTITION BY "remindersListID" ORDER BY "updatedAt" DESC) as rn
          FROM "reminders"
          """)
      ) {
        """
        SELECT
            "id",
            "title",
            ROW_NUMBER() OVER (PARTITION BY "remindersListID" ORDER BY "updatedAt" DESC) as rn
        FROM "reminders"
        """
      }

      // RANK() and DENSE_RANK() - Standard SQL window functions
      await assertSQL(
        of: #sql(
          """
          SELECT
              "title",
              RANK() OVER (ORDER BY "priority" DESC) as rank,
              DENSE_RANK() OVER (ORDER BY "priority" DESC) as dense_rank
          FROM "reminders"
          """)
      ) {
        """
        SELECT
            "title",
            RANK() OVER (ORDER BY "priority" DESC) as rank,
            DENSE_RANK() OVER (ORDER BY "priority" DESC) as dense_rank
        FROM "reminders"
        """
      }
    }

    @Test func upperFunction() async {
      // UPPER() - Standard SQL function
      await assertSQL(
        of: Reminder.select { reminder in
          #sql("UPPER(\(reminder.title))", as: String.self)
        }
      ) {
        """
        SELECT UPPER("reminders"."title")
        FROM "reminders"
        """
      }
    }

    @Test func basicCTE() async {
      // Basic CTE - Standard SQL
      await assertSQL(
        of: #sql(
          """
          WITH active_lists AS (
              SELECT * FROM "remindersLists"
              WHERE "position" > 0
          )
          SELECT * FROM active_lists
          """)
      ) {
        """
        WITH active_lists AS (
            SELECT * FROM "remindersLists"
            WHERE "position" > 0
        )
        SELECT * FROM active_lists
        """
      }
    }
  }
}
