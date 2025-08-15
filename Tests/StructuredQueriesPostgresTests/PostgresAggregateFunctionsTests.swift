import Foundation
import PostgresNIO
import StructuredQueries
import StructuredQueriesPostgres
import Testing

@Suite("PostgreSQL-Specific Aggregate Functions Tests")
struct PostgresAggregateFunctionsTests {

  @Test("STRING_AGG function")
  func stringAggregation() {
    // STRING_AGG is PostgreSQL-specific
    assertPostgresQuery(
      Reminder
        .group(by: \.remindersListID)
        .select { reminder in (reminder.remindersListID, reminder.title.stringAgg(", ")) },
      sql: #"SELECT "reminders"."remindersListID", string_agg("reminders"."title", $1) FROM "reminders" GROUP BY "reminders"."remindersListID""#
    )

    assertPostgresQuery(
      Reminder
        .group(by: \.remindersListID)
        .select { reminder in (reminder.remindersListID, reminder.notes.stringAgg(" | ")) },
      sql: #"SELECT "reminders"."remindersListID", string_agg("reminders"."notes", $1) FROM "reminders" GROUP BY "reminders"."remindersListID""#
    )
  }

  @Test("ARRAY_AGG function")
  func arrayAggregation() {
    // ARRAY_AGG is PostgreSQL-specific
    assertPostgresQuery(
      Reminder
        .group(by: \.remindersListID)
        .select { reminder in (reminder.remindersListID, reminder.title.arrayAgg()) },
      sql: #"SELECT "reminders"."remindersListID", array_agg("reminders"."title") FROM "reminders" GROUP BY "reminders"."remindersListID""#
    )

    assertPostgresQuery(
      Reminder
        .group(by: \.remindersListID)
        .select { reminder in (reminder.remindersListID, reminder.id.arrayAgg()) },
      sql: #"SELECT "reminders"."remindersListID", array_agg("reminders"."id") FROM "reminders" GROUP BY "reminders"."remindersListID""#
    )
  }

  @Test("JSON_AGG and JSONB_AGG functions")
  func jsonAggregation() {
    // JSON_AGG is PostgreSQL-specific
    assertPostgresQuery(
      Reminder
        .group(by: \.remindersListID)
        .select { reminder in (reminder.remindersListID, reminder.title.jsonAgg()) },
      sql: #"SELECT "reminders"."remindersListID", json_agg("reminders"."title") FROM "reminders" GROUP BY "reminders"."remindersListID""#
    )

    // JSONB_AGG
    assertPostgresQuery(
      Reminder
        .group(by: \.remindersListID)
        .select { reminder in (reminder.remindersListID, reminder.title.jsonbAgg()) },
      sql: #"SELECT "reminders"."remindersListID", jsonb_agg("reminders"."title") FROM "reminders" GROUP BY "reminders"."remindersListID""#
    )

    assertPostgresQuery(
      Reminder
        .group(by: \.remindersListID)
        .select { reminder in (reminder.remindersListID, reminder.notes.jsonbAgg()) },
      sql: #"SELECT "reminders"."remindersListID", jsonb_agg("reminders"."notes") FROM "reminders" GROUP BY "reminders"."remindersListID""#
    )
  }

  @Test("Statistical functions - STDDEV")
  func stddevFunction() {
    // PostgreSQL-specific statistical functions
    assertPostgresQuery(
      Reminder.select { $0.id.stddev() },
      sql: #"SELECT stddev("reminders"."id") FROM "reminders""#
    )

    assertPostgresQuery(
      Reminder
        .group(by: \.remindersListID)
        .select { reminder in (reminder.remindersListID, reminder.id.stddev()) },
      sql: #"SELECT "reminders"."remindersListID", stddev("reminders"."id") FROM "reminders" GROUP BY "reminders"."remindersListID""#
    )
  }

  @Test("Statistical functions - STDDEV_POP and STDDEV_SAMP")
  func stddevPopAndSamp() {
    assertPostgresQuery(
      Reminder.select { ($0.id.stddevPop(), $0.id.stddevSamp()) },
      sql: #"SELECT stddev_pop("reminders"."id"), stddev_samp("reminders"."id") FROM "reminders""#
    )

    assertPostgresQuery(
      Reminder
        .group(by: \.remindersListID)
        .select { reminder in (reminder.remindersListID, reminder.id.stddevPop()) },
      sql: #"SELECT "reminders"."remindersListID", stddev_pop("reminders"."id") FROM "reminders" GROUP BY "reminders"."remindersListID""#
    )
  }

  @Test("Statistical functions - VARIANCE")
  func varianceFunction() {
    assertPostgresQuery(
      Reminder.select { $0.id.variance() },
      sql: #"SELECT variance("reminders"."id") FROM "reminders""#
    )

    assertPostgresQuery(
      Reminder
        .group(by: \.remindersListID)
        .select { reminder in (reminder.remindersListID, reminder.id.variance()) },
      sql: #"SELECT "reminders"."remindersListID", variance("reminders"."id") FROM "reminders" GROUP BY "reminders"."remindersListID""#
    )
  }

  @Test("Combining PostgreSQL-specific aggregates")
  func combinedAggregates() {
    assertPostgresQuery(
      Reminder
        .group(by: \.remindersListID)
        .select { reminder in
          (
            reminder.remindersListID,
            reminder.title.stringAgg(", "),
            reminder.id.arrayAgg(),
            reminder.id.stddev()
          )
        },
      sql: #"SELECT "reminders"."remindersListID", string_agg("reminders"."title", $1), array_agg("reminders"."id"), stddev("reminders"."id") FROM "reminders" GROUP BY "reminders"."remindersListID""#
    )
  }

  @Test("PostgreSQL aggregates with WHERE clause")
  func aggregatesWithWhere() {
    assertPostgresQuery(
      Reminder
        .where { $0.isCompleted }
        .group(by: \.remindersListID)
        .select { reminder in (reminder.remindersListID, reminder.title.stringAgg(", ")) },
      sql: #"SELECT "reminders"."remindersListID", string_agg("reminders"."title", $1) FROM "reminders" WHERE "reminders"."isCompleted" != 0 GROUP BY "reminders"."remindersListID""#
    )

    assertPostgresQuery(
      Reminder
        .where { $0.priority == Priority.high }
        .select { $0.id.stddev() },
      sql: #"SELECT stddev("reminders"."id") FROM "reminders" WHERE ("reminders"."priority" IS $1)"#
    )
  }

  @Test("PostgreSQL aggregates with HAVING clause")
  func aggregatesWithHaving() {
    // Using standard count() with PostgreSQL-specific aggregates
    assertPostgresQuery(
      Reminder
        .group(by: \.remindersListID)
        .having { $0.id.count() > 2 }
        .select { reminder in (reminder.remindersListID, reminder.title.arrayAgg()) },
      sql: #"SELECT "reminders"."remindersListID", array_agg("reminders"."title") FROM "reminders" GROUP BY "reminders"."remindersListID" HAVING (count("reminders"."id") > $1)"#
    )
  }

  @Test("PostgreSQL aggregates with ORDER BY")
  func aggregatesWithOrderBy() {
    assertPostgresQuery(
      Reminder
        .group(by: \.remindersListID)
        .order(by: { reminder in reminder.remindersListID })
        .select { reminder in (reminder.remindersListID, reminder.title.jsonAgg()) },
      sql: #"SELECT "reminders"."remindersListID", json_agg("reminders"."title") FROM "reminders" GROUP BY "reminders"."remindersListID" ORDER BY "reminders"."remindersListID""#
    )
  }
}
