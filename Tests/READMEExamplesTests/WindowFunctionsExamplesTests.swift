import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

/// Tests for Window Functions examples shown in README.md
@Suite("README Examples - Window Functions")
struct WindowFunctionsExamplesTests {

    // MARK: - Test Models

    @Table
    struct Employee {
        let id: Int
        var name: String
        var department: String
        var salary: Double
        var hireDate: Date
    }

    @Table
    struct Sale {
        let id: Int
        var productId: Int
        var amount: Double
        var saleDate: Date
        var region: String
    }

    // MARK: - Basic Window Functions

    @Test("README Example: ROW_NUMBER() window function")
    func rowNumber() async {
        await assertSQL(
            of: Employee
                .select {
                    (
                        $0.name,
                        $0.salary,
                        rowNumber().over {
                            $0.partition(by: $1.department)
                                .order(by: $1.salary, .desc)
                        }
                    )
                }
        ) {
            """
            SELECT "employees"."name", "employees"."salary", ROW_NUMBER() OVER (PARTITION BY "employees"."department" ORDER BY "employees"."salary" DESC)
            FROM "employees"
            """
        }
    }

    @Test("README Example: RANK() window function")
    func rank() async {
        await assertSQL(
            of: Employee
                .select {
                    (
                        $0.name,
                        $0.department,
                        $0.salary,
                        rank().over {
                            $0.partition(by: $1.department)
                                .order(by: $1.salary, .desc)
                        }
                    )
                }
        ) {
            """
            SELECT "employees"."name", "employees"."department", "employees"."salary", RANK() OVER (PARTITION BY "employees"."department" ORDER BY "employees"."salary" DESC)
            FROM "employees"
            """
        }
    }

    @Test("README Example: DENSE_RANK() window function")
    func denseRank() async {
        await assertSQL(
            of: Employee
                .select {
                    (
                        $0.name,
                        $0.salary,
                        denseRank().over {
                            $0.order(by: $1.salary, .desc)
                        }
                    )
                }
        ) {
            """
            SELECT "employees"."name", "employees"."salary", DENSE_RANK() OVER (ORDER BY "employees"."salary" DESC)
            FROM "employees"
            """
        }
    }

    // MARK: - Aggregate Window Functions

    @Test("README Example: SUM() as window function - running total")
    func sumWindow() async {
        await assertSQL(
            of: Sale
                .select {
                    (
                        $0.saleDate,
                        $0.amount,
                        sum($0.amount).over {
                            $0.order(by: $1.saleDate)
                        }
                    )
                }
        ) {
            """
            SELECT "sales"."saleDate", "sales"."amount", SUM("sales"."amount") OVER (ORDER BY "sales"."saleDate")
            FROM "sales"
            """
        }
    }

    @Test("README Example: AVG() as window function with partition")
    func avgWindow() async {
        await assertSQL(
            of: Sale
                .select {
                    (
                        $0.region,
                        $0.amount,
                        avg($0.amount).over {
                            $0.partition(by: $1.region)
                        }
                    )
                }
        ) {
            """
            SELECT "sales"."region", "sales"."amount", AVG("sales"."amount") OVER (PARTITION BY "sales"."region")
            FROM "sales"
            """
        }
    }

    // MARK: - Value Window Functions

    @Test("README Example: LAG() window function")
    func lag() async {
        await assertSQL(
            of: Sale
                .select {
                    (
                        $0.saleDate,
                        $0.amount,
                        lag($0.amount, offset: 1).over {
                            $0.order(by: $1.saleDate)
                        }
                    )
                }
        ) {
            """
            SELECT "sales"."saleDate", "sales"."amount", LAG("sales"."amount", 1) OVER (ORDER BY "sales"."saleDate")
            FROM "sales"
            """
        }
    }

    @Test("README Example: LEAD() window function with default")
    func leadWithDefault() async {
        await assertSQL(
            of: Sale
                .select {
                    (
                        $0.saleDate,
                        $0.amount,
                        lead($0.amount, offset: 1, default: 0.0).over {
                            $0.order(by: $1.saleDate)
                        }
                    )
                }
        ) {
            """
            SELECT "sales"."saleDate", "sales"."amount", LEAD("sales"."amount", 1, 0.0) OVER (ORDER BY "sales"."saleDate")
            FROM "sales"
            """
        }
    }

    @Test("README Example: FIRST_VALUE() window function")
    func firstValue() async {
        await assertSQL(
            of: Employee
                .select {
                    (
                        $0.name,
                        $0.department,
                        $0.salary,
                        firstValue($0.salary).over {
                            $0.partition(by: $1.department)
                                .order(by: $1.salary, .desc)
                        }
                    )
                }
        ) {
            """
            SELECT "employees"."name", "employees"."department", "employees"."salary", FIRST_VALUE("employees"."salary") OVER (PARTITION BY "employees"."department" ORDER BY "employees"."salary" DESC)
            FROM "employees"
            """
        }
    }

    @Test("README Example: LAST_VALUE() window function")
    func lastValue() async {
        await assertSQL(
            of: Employee
                .select {
                    (
                        $0.name,
                        $0.salary,
                        lastValue($0.salary).over {
                            $0.order(by: $1.hireDate)
                        }
                    )
                }
        ) {
            """
            SELECT "employees"."name", "employees"."salary", LAST_VALUE("employees"."salary") OVER (ORDER BY "employees"."hireDate")
            FROM "employees"
            """
        }
    }

    // MARK: - Named Windows (WINDOW Clause)

    @Test("README Example: Named window definition")
    func namedWindow() async {
        await assertSQL(
            of: Employee
                .window("dept_salary") {
                    WindowSpec()
                        .partition(by: $0.department)
                        .order(by: $0.salary, .desc)
                }
                .select {
                    (
                        $0.name,
                        $0.salary,
                        rank().over("dept_salary"),
                        denseRank().over("dept_salary"),
                        rowNumber().over("dept_salary")
                    )
                }
        ) {
            """
            SELECT "employees"."name", "employees"."salary", RANK() OVER dept_salary, DENSE_RANK() OVER dept_salary, ROW_NUMBER() OVER dept_salary
            FROM "employees"
            WINDOW dept_salary AS (PARTITION BY "employees"."department" ORDER BY "employees"."salary" DESC)
            """
        }
    }

    @Test("README Example: Multiple named windows")
    func multipleNamedWindows() async {
        await assertSQL(
            of: Sale
                .window("by_region") {
                    WindowSpec().partition(by: $0.region)
                }
                .window("by_date") {
                    WindowSpec().order(by: $0.saleDate)
                }
                .select {
                    (
                        $0.region,
                        $0.amount,
                        avg($0.amount).over("by_region"),
                        sum($0.amount).over("by_date")
                    )
                }
        ) {
            """
            SELECT "sales"."region", "sales"."amount", AVG("sales"."amount") OVER by_region, SUM("sales"."amount") OVER by_date
            FROM "sales"
            WINDOW by_region AS (PARTITION BY "sales"."region"), by_date AS (ORDER BY "sales"."saleDate")
            """
        }
    }

    @Test("README Example: Mixed named and inline windows")
    func mixedWindows() async {
        await assertSQL(
            of: Employee
                .window("dept_window") {
                    WindowSpec()
                        .partition(by: $0.department)
                        .order(by: $0.salary, .desc)
                }
                .select {
                    let id = $0.id
                    return (
                        $0.name,
                        $0.salary,
                        rank().over("dept_window"),
                        rowNumber().over { $0.order(by: id) }
                    )
                }
        ) {
            """
            SELECT "employees"."name", "employees"."salary", RANK() OVER dept_window, ROW_NUMBER() OVER (ORDER BY "employees"."id")
            FROM "employees"
            WINDOW dept_window AS (PARTITION BY "employees"."department" ORDER BY "employees"."salary" DESC)
            """
        }
    }

    // MARK: - Advanced Window Examples

    @Test("README Example: NTILE() for quartiles")
    func ntile() async {
        await assertSQL(
            of: Employee
                .select {
                    (
                        $0.name,
                        $0.salary,
                        ntile(4).over {
                            $0.order(by: $1.salary, .desc)
                        }
                    )
                }
        ) {
            """
            SELECT "employees"."name", "employees"."salary", NTILE(4) OVER (ORDER BY "employees"."salary" DESC)
            FROM "employees"
            """
        }
    }

    @Test("README Example: PERCENT_RANK() distribution")
    func percentRank() async {
        await assertSQL(
            of: Employee
                .select {
                    (
                        $0.name,
                        $0.salary,
                        percentRank().over {
                            $0.order(by: $1.salary, .desc)
                        }
                    )
                }
        ) {
            """
            SELECT "employees"."name", "employees"."salary", PERCENT_RANK() OVER (ORDER BY "employees"."salary" DESC)
            FROM "employees"
            """
        }
    }

    @Test("README Example: CUME_DIST() cumulative distribution")
    func cumeDist() async {
        await assertSQL(
            of: Employee
                .select {
                    (
                        $0.name,
                        $0.salary,
                        cumeDist().over {
                            $0.partition(by: $1.department)
                                .order(by: $1.salary, .desc)
                        }
                    )
                }
        ) {
            """
            SELECT "employees"."name", "employees"."salary", CUME_DIST() OVER (PARTITION BY "employees"."department" ORDER BY "employees"."salary" DESC)
            FROM "employees"
            """
        }
    }
}
