import Foundation
import StructuredQueriesPostgres
import Testing

// MARK: - F-001 Regression: JSONB path APIs no longer raw-interpolate caller-supplied
// path elements into SQL literals.
//
// `JSONB.Operators.Path`/`PathText`, `JSONB.AdditionalOperators.Delete.Path`, and
// `JSONB.Processing.Set`/`Insert` (plus their `Typed` counterparts) are all generic over
// `LHS`, and `Table.createGINIndexPath` is a static method on the generic `Table`
// protocol -- none has a non-generic owning type to extend per [INST-TEST-013]'s
// generic-namespace carve-out. `JSONB` itself is the non-generic parent namespace that
// owns all of them, so path-operator regression tests live there.
extension JSONB {
    @Suite("Path Injection")
    struct Tests {
        @Suite struct Unit {}
    }
}

extension JSONB.Tests.Unit {
    @Test
    func `sharp greater than path binds a malicious element instead of splicing it into SQL text`() {
        let maliciousPath = ["a', (SELECT pg_sleep(0)) --", "city"]
        let expression = TestUser.columns.metadata.value(at: maliciousPath)

        let (sql, bindings) = expression.queryFragment.prepare { "$\($0)" }

        #expect(sql == #"("test_users"."metadata" #> $1::text[])"#)
        #expect(bindings == [.stringArray(maliciousPath)])
        #expect(!sql.contains("pg_sleep"))
    }

    @Test
    func `sharp greater than greater than path binds a malicious element instead of splicing it into SQL text`() {
        let maliciousPath = ["a\", b} DROP TABLE test_users; --", "email"]
        let expression = TestUser.columns.metadata.valueAsText(at: maliciousPath)

        let (sql, bindings) = expression.queryFragment.prepare { "$\($0)" }

        #expect(sql == #"("test_users"."metadata" #>> $1::text[])"#)
        #expect(bindings == [.stringArray(maliciousPath)])
        #expect(!sql.contains("DROP TABLE"))
    }

    @Test
    func `sharp hyphen delete path binds a malicious element instead of splicing it into SQL text`() {
        let maliciousPath = ["a'; DROP TABLE test_users; --"]
        let expression = TestUser.columns.metadata.removing(path: maliciousPath)

        let (sql, bindings) = expression.queryFragment.prepare { "$\($0)" }

        #expect(sql == #"("test_users"."metadata" #- $1::text[])"#)
        #expect(bindings == [.stringArray(maliciousPath)])
        #expect(!sql.contains("DROP TABLE"))
    }

    @Test
    func `jsonb set binds a malicious path element instead of splicing it into SQL text`() {
        let maliciousPath = ["a', (SELECT 1) --"]
        let expression = TestUser.columns.metadata.setting(maliciousPath, to: "dark")

        let (sql, bindings) = expression.queryFragment.prepare { "$\($0)" }

        #expect(sql == #"jsonb_set("test_users"."metadata", $1::text[], $2::jsonb, $3)"#)
        #expect(bindings.first == .stringArray(maliciousPath))
        #expect(!sql.contains("SELECT 1"))
    }

    @Test
    func `jsonb insert binds a malicious path element instead of splicing it into SQL text`() {
        let maliciousPath = ["a', (SELECT 1) --"]
        let expression = TestUser.columns.metadata.inserting("dark", at: maliciousPath)

        let (sql, bindings) = expression.queryFragment.prepare { "$\($0)" }

        #expect(sql == #"jsonb_insert("test_users"."metadata", $1::text[], $2::jsonb, $3)"#)
        #expect(bindings.first == .stringArray(maliciousPath))
        #expect(!sql.contains("SELECT 1"))
    }

    @Test
    func `create GIN index path escapes a malicious path element instead of splicing it into DDL text`() {
        let maliciousPath = ["theme'; DROP TABLE test_users; --"]
        let fragment = TestUser.createGINIndexPath(on: \.metadata, path: maliciousPath)

        // Every single quote inside the malicious element must be doubled and the whole
        // element wrapped in a double-quoted array element, so the payload stays trapped
        // inside one unbroken string literal argument to `#>` and can never terminate the
        // literal early or introduce a second SQL statement.
        #expect(
            fragment.debugDescription
                == #"""
                CREATE INDEX "idx_test_users_metadata_theme'; DROP TABLE test_users; --_gin" ON "test_users" USING GIN (("metadata" #> '{"theme''; DROP TABLE test_users; --"}'))
                """#
        )
    }
}
