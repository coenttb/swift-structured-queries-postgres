import MacroTesting
import StructuredQueriesPostgresMacros
import Testing

extension SnapshotTests {
  @MainActor
  @Suite struct SQLMacroTests {
    @Test func basics() {
      assertMacro {
        """
        #sql("CURRENT_TIMESTAMP")
        """
      } expansion: {
        """
        StructuredQueriesPostgresCore.SQLQueryExpression("CURRENT_TIMESTAMP")
        """
      }
    }

    @Test func unmatchedDelimiters() {
      assertMacro {
        """
        #sql("date('now)")
        """
      } diagnostics: {
        """
        #sql("date('now)")
             ──────┬─────
                   ╰─ ⚠️ Cannot find "'" to match opening "'" in SQL string, producing incomplete fragment; did you mean to make this explicit?
                      ✏️ Use 'SQLQueryExpression.init(_:)' to silence this warning
        """
      } fixes: {
        """
        SQLQueryExpression("date('now)")
        """
      } expansion: {
        """
        SQLQueryExpression("date('now)")
        """
      }
      assertMacro {
        #"""
        #sql("(\($0.id) = \($1.id)")
        """#
      } diagnostics: {
        #"""
        #sql("(\($0.id) = \($1.id)")
             ─┬────────────────────
              ╰─ ⚠️ Cannot find ')' to match opening '(' in SQL string, producing incomplete fragment; did you mean to make this explicit?
                 ✏️ Use 'SQLQueryExpression.init(_:)' to silence this warning
        """#
      } fixes: {
        #"""
        SQLQueryExpression("(\($0.id) = \($1.id)")
        """#
      } expansion: {
        #"""
        SQLQueryExpression("(\($0.id) = \($1.id)")
        """#
      }
    }

    @Test func unmatchedOpenDelimiters() {
      assertMacro {
        """
        #sql("(1 + 2))")
        """
      } diagnostics: {
        """
        #sql("(1 + 2))")
             ────────┬─
                     ╰─ ⚠️ Cannot find '(' to match closing ')' in SQL string, producing incomplete fragment; did you mean to make this explicit?
                        ✏️ Use 'SQLQueryExpression.init(_:)' to silence this warning
        """
      } fixes: {
        """
        SQLQueryExpression("(1 + 2))")
        """
      } expansion: {
        """
        SQLQueryExpression("(1 + 2))")
        """
      }
    }

    @Test func escapedDelimiters() {
      assertMacro {
        """
        #sql("'('")
        """
      } expansion: {
        """
        StructuredQueriesPostgresCore.SQLQueryExpression("'('")
        """
      }
      assertMacro {
        """
        #sql("[it's fine]")
        """
      } expansion: {
        """
        StructuredQueriesPostgresCore.SQLQueryExpression("[it's fine]")
        """
      }
    }

    @Test func unexpectedBind() {
      assertMacro {
        """
        #sql("CURRENT_TIMESTAMP = ?")
        """
      } diagnostics: {
        """
        #sql("CURRENT_TIMESTAMP = ?")
             ─────────────────────┬─
                                  ╰─ 🛑 Invalid bind parameter in literal; use interpolation to bind values into SQL
        """
      }
      assertMacro {
        """
        #sql("CURRENT_TIMESTAMP = ?1")
        """
      } diagnostics: {
        """
        #sql("CURRENT_TIMESTAMP = ?1")
             ─────────────────────┬──
                                  ╰─ 🛑 Invalid bind parameter in literal; use interpolation to bind values into SQL
        """
      }
      assertMacro {
        """
        #sql("CURRENT_TIMESTAMP = :timestamp")
        """
      } diagnostics: {
        """
        #sql("CURRENT_TIMESTAMP = :timestamp")
             ─────────────────────┬──────────
                                  ╰─ 🛑 Invalid bind parameter in literal; use interpolation to bind values into SQL
        """
      }
      assertMacro {
        """
        #sql("CURRENT_TIMESTAMP = @timestamp")
        """
      } diagnostics: {
        """
        #sql("CURRENT_TIMESTAMP = @timestamp")
             ─────────────────────┬──────────
                                  ╰─ 🛑 Invalid bind parameter in literal; use interpolation to bind values into SQL
        """
      }
      assertMacro {
        """
        #sql("CURRENT_TIMESTAMP = $timestamp")
        """
      } diagnostics: {
        """
        #sql("CURRENT_TIMESTAMP = $timestamp")
             ─────────────────────┬──────────
                                  ╰─ 🛑 Invalid bind parameter in literal; use interpolation to bind values into SQL
        """
      }
    }

    @Test func escapedBind() {
      assertMacro {
        """
        #sql(#""text" = 'hello?'"#)
        """
      } expansion: {
        """
        StructuredQueriesPostgresCore.SQLQueryExpression(#""text" = 'hello?'"#)
        """
      }
      assertMacro {
        """
        #sql(#""text" = 'hello?1'"#)
        """
      } expansion: {
        """
        StructuredQueriesPostgresCore.SQLQueryExpression(#""text" = 'hello?1'"#)
        """
      }
      assertMacro {
        """
        #sql(#""text" = 'hello:hi'"#)
        """
      } expansion: {
        """
        StructuredQueriesPostgresCore.SQLQueryExpression(#""text" = 'hello:hi'"#)
        """
      }
      assertMacro {
        """
        #sql(#""text" = 'hello@hi'"#)
        """
      } expansion: {
        """
        StructuredQueriesPostgresCore.SQLQueryExpression(#""text" = 'hello@hi'"#)
        """
      }
      assertMacro {
        """
        #sql(#""text" = 'hello$hi'"#)
        """
      } expansion: {
        """
        StructuredQueriesPostgresCore.SQLQueryExpression(#""text" = 'hello$hi'"#)
        """
      }
    }

    @Test func invalidBind() {
      assertMacro {
        #"""
        #sql("'\(42)'")
        """#
      } diagnostics: {
        #"""
        #sql("'\(42)'")
               ┬────
               ╰─ 🛑 Bind after opening "'" in SQL string, producing invalid fragment; did you mean to make this explicit? To interpolate raw SQL, use '\(raw:)'.
                  ✏️ Insert 'raw: '
        """#
      } fixes: {
        #"""
        #sql("'\(raw: 42)'")
        """#
      } expansion: {
        #"""
        StructuredQueriesPostgresCore.SQLQueryExpression("'\(raw: 42)'")
        """#
      }
    }

    @Test func validRawBind() {
      assertMacro {
        #"""
        #sql("'\(raw: 42)'")
        """#
      } expansion: {
        #"""
        StructuredQueriesPostgresCore.SQLQueryExpression("'\(raw: 42)'")
        """#
      }
    }

    @Test func complexValidRawBind() {
      assertMacro {
        #"""
        #sql("\($0.dueDate) < date('now', '-\(raw: monthsAgo) months')")
        """#
      } expansion: {
        #"""
        StructuredQueriesPostgresCore.SQLQueryExpression("\($0.dueDate) < date('now', '-\(raw: monthsAgo) months')")
        """#
      }
    }

    @Test func emptyDelimiters() {
      assertMacro {
        #"""
        #sql("''")
        """#
      } expansion: {
        """
        StructuredQueriesPostgresCore.SQLQueryExpression("''")
        """
      }
      assertMacro {
        #"""
        #sql(
          """
          ""
          """
        )
        """#
      } expansion: {
        #"""
        StructuredQueriesPostgresCore.SQLQueryExpression(
          """
          ""
          """)
        """#
      }
      assertMacro {
        #"""
        #sql("[]")
        """#
      } expansion: {
        """
        StructuredQueriesPostgresCore.SQLQueryExpression("[]")
        """
      }
    }

    @Test func quotedDelimiters() {
      assertMacro {
        #"""
        #sql(
          """
          SELECT 1 AS "a ""real"" one"
          """
        )
        """#
      } expansion: {
        #"""
        StructuredQueriesPostgresCore.SQLQueryExpression(
          """
          SELECT 1 AS "a ""real"" one"
          """)
        """#
      }
    }

    @Test func unclosedQuotedDelimiters() {
      assertMacro {
        #"""
        #sql(
          """
          SELECT 1 AS "a ""real"" one
          """
        )
        """#
      } diagnostics: {
        #"""
        #sql(
          """
          SELECT 1 AS "a ""real"" one
                      ╰─ ⚠️ Cannot find '"' to match opening '"' in SQL string, producing incomplete fragment; did you mean to make this explicit?
                         ✏️ Use 'SQLQueryExpression.init(_:)' to silence this warning
          """
        )
        """#
      } fixes: {
        #"""
        SQLQueryExpression(
          """
          SELECT 1 AS "a ""real"" one
          """)
        """#
      } expansion: {
        #"""
        SQLQueryExpression(
          """
          SELECT 1 AS "a ""real"" one
          """)
        """#
      }
    }

    @Test func dollarSign() {
      assertMacro {
        """
        #sql("json_extract(notes, '$.body')")
        """
      } expansion: {
        """
        StructuredQueriesPostgresCore.SQLQueryExpression("json_extract(notes, '$.body')")
        """
      }
    }

    @Test func badDollarSign() {
      assertMacro {
        """
        #sql("json_extract(notes, $.body)")
        """
      } diagnostics: {
        """
        #sql("json_extract(notes, $.body)")
             ─────────────────────┬───────
                                  ╰─ 🛑 Invalid bind parameter in literal; use interpolation to bind values into SQL
        """
      }
    }
  }
}
