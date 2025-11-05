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
    }

    @Table
    struct Sale {
        let id: Int
        var date: Date
        var amount: Double
    }

    // MARK: - Basic Window Functions

    @Test("README Example: RANK() window function")
    func rankWindowFunction() async {
        await assertSQL(
            of: Employee.all
                .select { employee in
                    (
                        employee.name,
                        employee.salary,
                        rank().over {
                            $0.partition(by: employee.department)
                                .order(by: employee.salary.desc())
                        }
                    )
                }
        ) {
            """
            SELECT "employees"."name", "employees"."salary", RANK() OVER (PARTITION BY "employees"."department" ORDER BY "employees"."salary" DESC)
            FROM "employees"
            """
        }
    }

    // MARK: - Named Windows (WINDOW Clause)

    @Test("README Example: Named window definition")
    func namedWindow() async {
        await assertSQL(
            of: Employee.all
                .window("dept_salary") {
                    $0.partition(by: $1.department)
                        .order(by: $1.salary.desc())
                }
                .select {
                    (
                        $0.name,
                        rank().over("dept_salary"),
                        denseRank().over("dept_salary"),
                        rowNumber().over("dept_salary")
                    )
                }
        ) {
            """
            SELECT "employees"."name", RANK() OVER dept_salary, DENSE_RANK() OVER dept_salary, ROW_NUMBER() OVER dept_salary
            FROM "employees"
            WINDOW dept_salary AS (PARTITION BY "employees"."department" ORDER BY "employees"."salary" DESC)
            """
        }
    }

}
