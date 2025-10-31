import MacroTesting
import StructuredQueriesPostgresMacros
import Testing

extension SnapshotTests {
  @MainActor
  @Suite("Draft WritableColumns Type-Based Exclusion")
  struct DraftWritableColumnsTypesTests {

    @Test("Draft excludes UUID primary key from writableColumns")
    func testDraftExcludesUUIDPrimaryKey() {
      assertMacro {
        #"""
        @Table("users")
        struct User {
          let id: UUID
          var name: String
          var email: String
        }
        """#
      } expansion: {
        #"""
        struct User {
          let id: UUID
          var name: String
          var email: String

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
            public typealias QueryValue = User
            public typealias PrimaryKey = UUID
            public let id = StructuredQueriesCore._TableColumn<QueryValue, UUID>.for("id", keyPath: \QueryValue.id)
            public let primaryKey = StructuredQueriesCore._TableColumn<QueryValue, UUID>.for("id", keyPath: \QueryValue.id)
            public let name = StructuredQueriesCore._TableColumn<QueryValue, String>.for("name", keyPath: \QueryValue.name)
            public let email = StructuredQueriesCore._TableColumn<QueryValue, String>.for("email", keyPath: \QueryValue.email)
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.email._allColumns)
              return allColumns
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.email._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.id), \(self.name), \(self.email)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = User
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              id: some StructuredQueriesCore.QueryExpression<UUID>,
              name: some StructuredQueriesCore.QueryExpression<String>,
              email: some StructuredQueriesCore.QueryExpression<String>
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: id._allColumns)
              allColumns.append(contentsOf: name._allColumns)
              allColumns.append(contentsOf: email._allColumns)
              self.allColumns = allColumns
            }
          }

          public struct Draft: StructuredQueriesCore.TableDraft {
            public typealias PrimaryTable = User
            let id: UUID?
            var name: String
            var email: String
            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
              public typealias QueryValue = Draft
              public let id = StructuredQueriesCore._TableColumn<QueryValue, UUID?>.for("id", keyPath: \QueryValue.id, default: nil)
              public let name = StructuredQueriesCore._TableColumn<QueryValue, String>.for("name", keyPath: \QueryValue.name)
              public let email = StructuredQueriesCore._TableColumn<QueryValue, String>.for("email", keyPath: \QueryValue.email)
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.email._allColumns)
                return allColumns
              }
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.email._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.name), \(self.email)"
              }
            }
            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Draft
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<UUID?> = UUID?(queryOutput: nil),
                name: some StructuredQueriesCore.QueryExpression<String>,
                email: some StructuredQueriesCore.QueryExpression<String>
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: id._allColumns)
                allColumns.append(contentsOf: name._allColumns)
                allColumns.append(contentsOf: email._allColumns)
                self.allColumns = allColumns
              }
            }
            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var _columnWidth: Int {
              var columnWidth = 0
              columnWidth += UUID?._columnWidth
              columnWidth += String._columnWidth
              columnWidth += String._columnWidth
              return columnWidth
            }

            public nonisolated static var tableName: String {
              User.tableName
            }

            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.id = try decoder.decode(UUID.self) ?? nil
              let name = try decoder.decode(String.self)
              let email = try decoder.decode(String.self)
              guard let name else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              guard let email else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              self.name = name
              self.email = email
            }

            public nonisolated init(_ other: User) {
              self.id = other.id
              self.name = other.name
              self.email = other.email
            }
            public init(
              id: UUID? = nil,
              name: String,
              email: String
            ) {
              self.id = id
              self.name = name
              self.email = email
            }
          }
        }

        nonisolated extension User: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var _columnWidth: Int {
            var columnWidth = 0
            columnWidth += UUID._columnWidth
            columnWidth += String._columnWidth
            columnWidth += String._columnWidth
            return columnWidth
          }
          public nonisolated static var tableName: String {
            "users"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let id = try decoder.decode(UUID.self)
            let name = try decoder.decode(String.self)
            let email = try decoder.decode(String.self)
            guard let id else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            guard let name else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            guard let email else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            self.id = id
            self.name = name
            self.email = email
          }
        }
        """#
      }
    }

    @Test("Draft excludes Int primary key from writableColumns")
    func testDraftExcludesIntPrimaryKey() {
      assertMacro {
        #"""
        @Table("products")
        struct Product {
          let id: Int
          var name: String
          var price: Double
        }
        """#
      } expansion: {
        #"""
        struct Product {
          let id: Int
          var name: String
          var price: Double

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
            public typealias QueryValue = Product
            public typealias PrimaryKey = Int
            public let id = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
            public let primaryKey = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
            public let name = StructuredQueriesCore._TableColumn<QueryValue, String>.for("name", keyPath: \QueryValue.name)
            public let price = StructuredQueriesCore._TableColumn<QueryValue, Double>.for("price", keyPath: \QueryValue.price)
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.price._allColumns)
              return allColumns
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.price._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.id), \(self.name), \(self.price)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Product
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              id: some StructuredQueriesCore.QueryExpression<Int>,
              name: some StructuredQueriesCore.QueryExpression<String>,
              price: some StructuredQueriesCore.QueryExpression<Double>
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: id._allColumns)
              allColumns.append(contentsOf: name._allColumns)
              allColumns.append(contentsOf: price._allColumns)
              self.allColumns = allColumns
            }
          }

          public struct Draft: StructuredQueriesCore.TableDraft {
            public typealias PrimaryTable = Product
            let id: Int?
            var name: String
            var price: Double
            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
              public typealias QueryValue = Draft
              public let id = StructuredQueriesCore._TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
              public let name = StructuredQueriesCore._TableColumn<QueryValue, String>.for("name", keyPath: \QueryValue.name)
              public let price = StructuredQueriesCore._TableColumn<QueryValue, Double>.for("price", keyPath: \QueryValue.price)
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.price._allColumns)
                return allColumns
              }
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.price._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.name), \(self.price)"
              }
            }
            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Draft
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
                name: some StructuredQueriesCore.QueryExpression<String>,
                price: some StructuredQueriesCore.QueryExpression<Double>
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: id._allColumns)
                allColumns.append(contentsOf: name._allColumns)
                allColumns.append(contentsOf: price._allColumns)
                self.allColumns = allColumns
              }
            }
            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var _columnWidth: Int {
              var columnWidth = 0
              columnWidth += Int?._columnWidth
              columnWidth += String._columnWidth
              columnWidth += Double._columnWidth
              return columnWidth
            }

            public nonisolated static var tableName: String {
              Product.tableName
            }

            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.id = try decoder.decode(Int.self) ?? nil
              let name = try decoder.decode(String.self)
              let price = try decoder.decode(Double.self)
              guard let name else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              guard let price else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              self.name = name
              self.price = price
            }

            public nonisolated init(_ other: Product) {
              self.id = other.id
              self.name = other.name
              self.price = other.price
            }
            public init(
              id: Int? = nil,
              name: String,
              price: Double
            ) {
              self.id = id
              self.name = name
              self.price = price
            }
          }
        }

        nonisolated extension Product: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var _columnWidth: Int {
            var columnWidth = 0
            columnWidth += Int._columnWidth
            columnWidth += String._columnWidth
            columnWidth += Double._columnWidth
            return columnWidth
          }
          public nonisolated static var tableName: String {
            "products"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let id = try decoder.decode(Int.self)
            let name = try decoder.decode(String.self)
            let price = try decoder.decode(Double.self)
            guard let id else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            guard let name else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            guard let price else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            self.id = id
            self.name = name
            self.price = price
          }
        }
        """#
      }
    }

    @Test("Draft includes String primary key in writableColumns")
    func testDraftIncludesStringPrimaryKey() {
      assertMacro {
        #"""
        @Table("stripe_events")
        struct StripeEvent {
          let id: String
          var type: String
          var processedAt: Date
        }
        """#
      } expansion: {
        #"""
        struct StripeEvent {
          let id: String
          var type: String
          var processedAt: Date

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
            public typealias QueryValue = StripeEvent
            public typealias PrimaryKey = String
            public let id = StructuredQueriesCore._TableColumn<QueryValue, String>.for("id", keyPath: \QueryValue.id)
            public let primaryKey = StructuredQueriesCore._TableColumn<QueryValue, String>.for("id", keyPath: \QueryValue.id)
            public let type = StructuredQueriesCore._TableColumn<QueryValue, String>.for("type", keyPath: \QueryValue.type)
            public let processedAt = StructuredQueriesCore._TableColumn<QueryValue, Date>.for("processedAt", keyPath: \QueryValue.processedAt)
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.type._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.processedAt._allColumns)
              return allColumns
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.type._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.processedAt._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.id), \(self.type), \(self.processedAt)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = StripeEvent
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              id: some StructuredQueriesCore.QueryExpression<String>,
              type: some StructuredQueriesCore.QueryExpression<String>,
              processedAt: some StructuredQueriesCore.QueryExpression<Date>
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: id._allColumns)
              allColumns.append(contentsOf: type._allColumns)
              allColumns.append(contentsOf: processedAt._allColumns)
              self.allColumns = allColumns
            }
          }

          public struct Draft: StructuredQueriesCore.TableDraft {
            public typealias PrimaryTable = StripeEvent
            let id: String?
            var type: String
            var processedAt: Date
            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
              public typealias QueryValue = Draft
              public let id = StructuredQueriesCore._TableColumn<QueryValue, String?>.for("id", keyPath: \QueryValue.id, default: nil)
              public let type = StructuredQueriesCore._TableColumn<QueryValue, String>.for("type", keyPath: \QueryValue.type)
              public let processedAt = StructuredQueriesCore._TableColumn<QueryValue, Date>.for("processedAt", keyPath: \QueryValue.processedAt)
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.type._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.processedAt._allColumns)
                return allColumns
              }
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.type._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.processedAt._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.type), \(self.processedAt)"
              }
            }
            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Draft
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<String?> = String?(queryOutput: nil),
                type: some StructuredQueriesCore.QueryExpression<String>,
                processedAt: some StructuredQueriesCore.QueryExpression<Date>
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: id._allColumns)
                allColumns.append(contentsOf: type._allColumns)
                allColumns.append(contentsOf: processedAt._allColumns)
                self.allColumns = allColumns
              }
            }
            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var _columnWidth: Int {
              var columnWidth = 0
              columnWidth += String?._columnWidth
              columnWidth += String._columnWidth
              columnWidth += Date._columnWidth
              return columnWidth
            }

            public nonisolated static var tableName: String {
              StripeEvent.tableName
            }

            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.id = try decoder.decode(String.self) ?? nil
              let type = try decoder.decode(String.self)
              let processedAt = try decoder.decode(Date.self)
              guard let type else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              guard let processedAt else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              self.type = type
              self.processedAt = processedAt
            }

            public nonisolated init(_ other: StripeEvent) {
              self.id = other.id
              self.type = other.type
              self.processedAt = other.processedAt
            }
            public init(
              id: String? = nil,
              type: String,
              processedAt: Date
            ) {
              self.id = id
              self.type = type
              self.processedAt = processedAt
            }
          }
        }

        nonisolated extension StripeEvent: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var _columnWidth: Int {
            var columnWidth = 0
            columnWidth += String._columnWidth
            columnWidth += String._columnWidth
            columnWidth += Date._columnWidth
            return columnWidth
          }
          public nonisolated static var tableName: String {
            "stripe_events"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let id = try decoder.decode(String.self)
            let type = try decoder.decode(String.self)
            let processedAt = try decoder.decode(Date.self)
            guard let id else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            guard let type else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            guard let processedAt else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            self.id = id
            self.type = type
            self.processedAt = processedAt
          }
        }
        """#
      }
    }

    @Test("Draft includes non-id fields regardless of type")
    func testDraftIncludesNonIdFields() {
      assertMacro {
        #"""
        @Table("orders")
        struct Order {
          let orderId: Int  // Not named 'id', so included even though Int
          var customerId: UUID  // Not named 'id', so included even though UUID
          var total: Double
        }
        """#
      } expansion: {
        #"""
        struct Order {
          let orderId: Int  // Not named 'id', so included even though Int
          var customerId: UUID  // Not named 'id', so included even though UUID
          var total: Double

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = Order
            public let orderId = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("orderId", keyPath: \QueryValue.orderId)
            public let customerId = StructuredQueriesCore._TableColumn<QueryValue, UUID>.for("customerId", keyPath: \QueryValue.customerId)
            public let total = StructuredQueriesCore._TableColumn<QueryValue, Double>.for("total", keyPath: \QueryValue.total)
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.orderId._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.customerId._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.total._allColumns)
              return allColumns
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.orderId._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.customerId._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.total._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.orderId), \(self.customerId), \(self.total)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Order
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              orderId: some StructuredQueriesCore.QueryExpression<Int>,
              customerId: some StructuredQueriesCore.QueryExpression<UUID>,
              total: some StructuredQueriesCore.QueryExpression<Double>
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: orderId._allColumns)
              allColumns.append(contentsOf: customerId._allColumns)
              allColumns.append(contentsOf: total._allColumns)
              self.allColumns = allColumns
            }
          }
        }

        nonisolated extension Order: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var _columnWidth: Int {
            var columnWidth = 0
            columnWidth += Int._columnWidth
            columnWidth += UUID._columnWidth
            columnWidth += Double._columnWidth
            return columnWidth
          }
          public nonisolated static var tableName: String {
            "orders"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let orderId = try decoder.decode(Int.self)
            let customerId = try decoder.decode(UUID.self)
            let total = try decoder.decode(Double.self)
            guard let orderId else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            guard let customerId else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            guard let total else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            self.orderId = orderId
            self.customerId = customerId
            self.total = total
          }
        }
        """#
      }
    }
  }
}
