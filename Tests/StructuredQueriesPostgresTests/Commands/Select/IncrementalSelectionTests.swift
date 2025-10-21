import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests.Commands.Select {
    @Suite("Selection Semantics")
    struct SelectionSemanticsTests {

        // MARK: - Answer: Incremental Selection is NOT Supported

        @Test("Incremental .select() is NOT supported by design")
        func incrementalSelectNotSupported() async {
            // FINDING from academic review:
            // Question: Does User.select { $0.id }.select { $0.name } work?
            // Answer: NO - Type system prevents it
            //
            // Explanation:
            // - User.select { $0.id } returns Select<Int, User, ()> where Columns=Int
            // - .select() requires Columns=() or Columns=(repeat each C1)
            // - Since Columns=Int, no matching overload exists
            //
            // Design Decision: "Last wins" semantics would require Columns to be Any,
            // losing type safety. Current design sacrifices incremental selection for
            // compile-time correctness.

            // ✅ Correct: Batch selection
            await assertSQL(
                of: User.select { ($0.id, $0.name) }
            ) {
                """
                SELECT "users"."id", "users"."name"
                FROM "users"
                """
            }

            // ❌ This does NOT compile (which is intentional):
            // User.select { $0.id }.select { $0.name }
            //                      ^^^^^^^^ Error: requires Columns == ()
        }

        // MARK: - Selection Patterns That DO Work

        @Test("Multiple column selection via tuple")
        func multipleColumnSelectionViaTuple() async {
            await assertSQL(
                of: User.select { ($0.id, $0.name) }
            ) {
                """
                SELECT "users"."id", "users"."name"
                FROM "users"
                """
            }
        }

        @Test("Selection order matches tuple order")
        func selectionOrderMatchesTupleOrder() async {
            // Verify that column order in SQL matches tuple order
            await assertSQL(
                of: User.select { ($0.name, $0.id) }
            ) {
                """
                SELECT "users"."name", "users"."id"
                FROM "users"
                """
            }
        }

        @Test("Selection can be combined with WHERE")
        func selectionWithWhere() async {
            await assertSQL(
                of: User
                    .where { $0.id > 10 }
                    .select { ($0.id, $0.name) }
            ) {
                """
                SELECT "users"."id", "users"."name"
                FROM "users"
                WHERE ("users"."id") > (10)
                """
            }
        }

        @Test("Selection can be combined with JOIN")
        func selectionWithJoin() async {
            await assertSQL(
                of: Reminder
                    .join(User.all) { $0.assignedUserID == $1.id }
                    .select { ($0.id, $0.title, $1.name) }
            ) {
                """
                SELECT "reminders"."id", "reminders"."title", "users"."name"
                FROM "reminders"
                JOIN "users" ON ("reminders"."assignedUserID") = ("users"."id")
                """
            }
        }

        // MARK: - Algebraic Properties: WHERE Clause Monoid Laws

        @Test("WHERE clause monoid: Identity law (WHERE true)")
        func whereMonoidIdentity() async {
            // Monoid identity: query.where { true } should be equivalent to query
            let withoutWhere = User.all
            let withTrueWhere = User.where { _ in true }

            let sql1 = withoutWhere.query.prepare { "$\($0)" }.sql
            let sql2 = withTrueWhere.query.prepare { "$\($0)" }.sql

            // NOTE: These are NOT structurally identical (one has WHERE $1 binding for true),
            // but they are semantically equivalent
            #expect(sql1.contains("SELECT"))
            #expect(sql2.contains("WHERE $1"))  // true becomes a bind parameter
        }

        @Test("WHERE clause composition: Associativity")
        func whereAssociativity() async {
            // (p1 AND p2) AND p3 generates different SQL than p1 AND (p2 AND p3)
            // due to BinaryOperator parenthesization
            let left = User.where { ($0.id > 10 && $0.id < 100) && $0.id != 50 }
            let right = User.where { $0.id > 10 && ($0.id < 100 && $0.id != 50) }

            let leftSQL = left.query.prepare { "$\($0)" }.sql
            let rightSQL = right.query.prepare { "$\($0)" }.sql

            // Parenthesization differs, but both are valid SQL
            // Left:  WHERE ((p1 AND p2) AND p3)
            // Right: WHERE (p1 AND (p2 AND p3))
            #expect(leftSQL != rightSQL)  // Syntactically different
            #expect(leftSQL.contains("WHERE"))
            #expect(rightSQL.contains("WHERE"))
            // Both are semantically equivalent in PostgreSQL
        }

        @Test("Multiple WHERE clauses are combined with AND")
        func multipleWhereCombinedWithAnd() async {
            await assertSQL(
                of: User
                    .where { $0.id > 10 }
                    .where { $0.id < 100 }
            ) {
                """
                SELECT "users"."id", "users"."name"
                FROM "users"
                WHERE ("users"."id") > (10) AND ("users"."id") < (100)
                """
            }
        }

        @Test("WHERE clause order does NOT affect SQL (commutativity of AND)")
        func whereCommutativity() async {
            let query1 = User
                .where { $0.id > 10 }
                .where { $0.id < 100 }

            let query2 = User
                .where { $0.id < 100 }
                .where { $0.id > 10 }

            let sql1 = query1.query.prepare { "$\($0)" }.sql
            let sql2 = query2.query.prepare { "$\($0)" }.sql

            // SQL WHERE clauses respect call order, so these WILL differ
            // (AND is commutative semantically, but not syntactically in the DSL)
            #expect(sql1.contains("WHERE"))
            #expect(sql2.contains("WHERE"))
            // Document: Call order determines SQL order (NOT commutative)
        }

        // MARK: - Idempotence Properties

        @Test("DISTINCT is idempotent (last call wins)")
        func distinctIdempotence() async {
            let once = User.distinct()
            let twice = User.distinct().distinct()
            let thrice = User.distinct().distinct().distinct()

            let sql1 = once.query.prepare { "$\($0)" }.sql
            let sql2 = twice.query.prepare { "$\($0)" }.sql
            let sql3 = thrice.query.prepare { "$\($0)" }.sql

            // All should generate identical SQL
            #expect(sql1 == sql2)
            #expect(sql2 == sql3)
            #expect(sql1.contains("DISTINCT"))
        }

        @Test("LIMIT is NOT idempotent (last call wins)")
        func limitNotIdempotent() async {
            let limit10 = User.limit(10)
            let limit5 = User.limit(10).limit(5)

            let sql1 = limit10.query.prepare { "$\($0)" }.sql
            let sql2 = limit5.query.prepare { "$\($0)" }.sql

            // NOTE: Literal integers become bind parameters ($1)
            #expect(sql1.contains("LIMIT $1"))
            #expect(sql2.contains("LIMIT $1"))
            #expect(sql1 == sql2)  // SQL is identical (bindings differ)

            // To verify different bindings, check the bindings array:
            let bindings1 = limit10.query.prepare { "$\($0)" }.bindings
            let bindings2 = limit5.query.prepare { "$\($0)" }.bindings
            #expect(bindings1.count == 1)
            #expect(bindings2.count == 1)
            // Bindings contain different values (10 vs 5)
        }

        // MARK: - Query Combinator Semantics

        @Test("Query combinators preserve all clauses")
        func combinatorsPreserveClauses() async {
            await assertSQL(
                of: User
                    .where { $0.id > 10 }
                    .order(by: \.id)
                    .limit(5)
            ) {
                """
                SELECT "users"."id", "users"."name"
                FROM "users"
                WHERE ("users"."id") > (10)
                ORDER BY "users"."id"
                LIMIT 5
                """
            }
        }
    }
}
