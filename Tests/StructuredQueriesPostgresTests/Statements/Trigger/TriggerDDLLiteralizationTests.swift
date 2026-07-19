import Foundation
import StructuredQueriesPostgres
import Testing

// MARK: - F-002 Regression: CREATE TRIGGER `WHEN` clauses and dollar-quoted PL/pgSQL
// function bodies no longer carry stray bind-parameter segments into DDL.
//
// `Trigger<On: Table>` and `Trigger<On>.Function` are both generic over `On`, and there
// is no non-generic parent namespace that owns them (unlike `JSONB`), so this uses the
// [INST-TEST-013] generic-namespace carve-out: a top-level `@Suite("Name") struct Tests`
// (not a compound `FooTests`).
//
// PostgreSQL does not substitute bind parameters inside DDL. Before the fix, a bound
// value embedded in a WHEN clause or PL/pgSQL body left an unresolved `$n` placeholder
// in the DDL text while the corresponding value sat, unused, in the statement's
// `bindings` array -- the placeholder either fails to parse as DDL or, worse, PL/pgSQL
// reinterprets `$n` as a positional function-argument reference at trigger-fire time.
// `QueryFragment.literalizedForDDL()` now renders every bound value as escaped literal
// SQL text before it reaches `Trigger.query` / `Trigger.Function.query`, so these tests
// assert both that no bindings remain and that the value was correctly escaped in place.
@Suite("Trigger DDL Literalization")
struct Tests {
    @Suite struct Unit {}
}

extension Tests.Unit {
    @Table("ddl_literalization_users")
    struct User {
        let id: Int
        var role: String
    }

    @Test
    func `WHEN clause literalizes a comparison value instead of leaving a stray bind parameter`() {
        let maliciousValue = "admin'; DROP TABLE ddl_literalization_users; --"
        let trigger = User.createTrigger(
            timing: .before,
            event: .delete(when: { old in old.role == maliciousValue }),
            function: .plpgsql("noop", "RETURN OLD;")
        )

        let (sql, bindings) = trigger.query.prepare { "$\($0)" }

        // No value may remain as an unresolved bind parameter inside DDL.
        #expect(bindings.isEmpty)
        #expect(!sql.contains("$1"))
        // The malicious single quote must be doubled (escaped) and the whole value
        // embedded as one self-contained SQL string literal directly in the WHEN clause.
        #expect(
            sql.contains(
                #"(OLD."role") = ('admin''; DROP TABLE ddl_literalization_users; --')"#
            )
        )
    }

    @Test
    func `preventDeletionWhen literalizes the comparison value in the function body instead of leaving a stray bind parameter`(
    ) {
        let maliciousValue = "admin'; DROP TABLE ddl_literalization_users; --"
        let trigger = User.createTrigger(
            timing: .before,
            event: .delete,
            function: .preventDeletionWhen(
                column: \.role,
                equals: maliciousValue,
                message: "Cannot delete admin users"
            )
        )

        let (sql, bindings) = trigger.function.query.prepare { "$\($0)" }

        // No value may remain as an unresolved bind parameter inside the dollar-quoted
        // PL/pgSQL body.
        #expect(bindings.isEmpty)
        #expect(!sql.contains("$1"))
        // The malicious single quote must be doubled (escaped) and the whole value
        // embedded as one self-contained SQL string literal directly in the function body.
        #expect(
            sql.contains(
                #"IF OLD."role" = 'admin''; DROP TABLE ddl_literalization_users; --' THEN"#
            )
        )
    }
}
