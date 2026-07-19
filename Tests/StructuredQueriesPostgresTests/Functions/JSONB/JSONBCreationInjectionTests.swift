import Foundation
import StructuredQueriesPostgres
import Testing

// MARK: - F-101 Regression: `JSONB.Creation.object(keys:values:)` no longer raw-interpolates
// caller-supplied key/value elements into SQL literals.
//
// Before the fix, `JSONObjectFromArrays.queryFragment` built the `json_object(...)` call by
// hand-joining `keys`/`values` into `"'{" + ... + "}'"` literals and splicing the result into
// the SQL text via `\(raw:)` -- the identical vulnerable pattern F-001 eliminated from the
// JSONB path operators (`#>`/`#>>`/`#-`/`jsonb_set`/`jsonb_insert`). A key or value element
// containing a single quote could break out of the literal and inject arbitrary SQL. Both
// arrays are now bound as genuine `text[]` parameters via the existing
// `Array: QueryExpression where Element: QueryBindable` conformance, mirroring the mechanism
// F-001 already established for the path operators.
//
// Unlike the F-001 path operators (all generic over `LHS`, with no non-generic owning type),
// `JSONObjectFromArrays` backs the non-generic `JSONB.Creation.object(keys:values:)` static
// method, so this suite nests directly under the non-generic `JSONB.Creation` namespace per
// [INST-TEST-013] rather than falling back to the `JSONB` parent carve-out.
extension JSONB.Creation {
    @Suite("Object Injection")
    struct Tests {
        @Suite struct Unit {}
    }
}

extension JSONB.Creation.Tests.Unit {
    @Test
    func `json object binds a malicious key instead of splicing it into SQL text`() {
        let maliciousKeys = ["a', (SELECT pg_sleep(0)) --", "email"]
        let values = ["Alice", "alice@example.com"]
        let expression = JSONB.Creation.object(keys: maliciousKeys, values: values)

        let (sql, bindings) = expression.queryFragment.prepare { "$\($0)" }

        #expect(sql == #"json_object($1::text[], $2::text[])"#)
        #expect(bindings == [.stringArray(maliciousKeys), .stringArray(values)])
        #expect(!sql.contains("pg_sleep"))
        #expect(!sql.contains("'"))
    }

    @Test
    func `json object binds a malicious value instead of splicing it into SQL text`() {
        let keys = ["name"]
        let maliciousValues = ["a\", b} DROP TABLE test_users; --"]
        let expression = JSONB.Creation.object(keys: keys, values: maliciousValues)

        let (sql, bindings) = expression.queryFragment.prepare { "$\($0)" }

        #expect(sql == #"json_object($1::text[], $2::text[])"#)
        #expect(bindings == [.stringArray(keys), .stringArray(maliciousValues)])
        #expect(!sql.contains("DROP TABLE"))
        #expect(!sql.contains("}"))
    }

    @Test
    func `json object binds malicious keys and values simultaneously instead of splicing them into SQL text`(
    ) {
        let maliciousKeys = ["theme'; DROP TABLE test_users; --"]
        let maliciousValues = ["a\" } , (SELECT pg_sleep(0)) --"]
        let expression = JSONB.Creation.object(keys: maliciousKeys, values: maliciousValues)

        let (sql, bindings) = expression.queryFragment.prepare { "$\($0)" }

        #expect(sql == #"json_object($1::text[], $2::text[])"#)
        #expect(bindings == [.stringArray(maliciousKeys), .stringArray(maliciousValues)])
        #expect(!sql.contains("DROP TABLE"))
        #expect(!sql.contains("pg_sleep"))
        #expect(!sql.contains("'"))
        #expect(!sql.contains("\""))
    }

    @Test
    func `json object binds a key containing a double quote instead of splicing it into SQL text`() {
        let maliciousKeys = ["a\"b"]
        let values = ["c"]
        let expression = JSONB.Creation.object(keys: maliciousKeys, values: values)

        let (sql, bindings) = expression.queryFragment.prepare { "$\($0)" }

        #expect(sql == #"json_object($1::text[], $2::text[])"#)
        #expect(bindings == [.stringArray(maliciousKeys), .stringArray(values)])
        #expect(!sql.contains("\""))
    }
}
