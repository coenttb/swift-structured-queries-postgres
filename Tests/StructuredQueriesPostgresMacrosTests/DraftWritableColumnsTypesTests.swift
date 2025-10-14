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

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition, SQLQueryExpression(PrimaryKeyedTableDefinition {
                    public typealias QueryValue = User
                    public let id = SQLQueryExpression(TableColumn<QueryValue, UUID>("id", keyPath: \QueryValue.id)
                    public let name = SQLQueryExpression(TableColumn<QueryValue, String>("name", keyPath: \QueryValue.name)
                    public let email = SQLQueryExpression(TableColumn<QueryValue, String>("email", keyPath: \QueryValue.email)
                    public var primaryKey: SQLQueryExpression(TableColumn<QueryValue, UUID> {
                      self.id
                    }
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      [QueryValue.columns.id, QueryValue.columns.name, QueryValue.columns.email]
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      [QueryValue.columns.id, QueryValue.columns.name, QueryValue.columns.email]
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.id), \(self.name), \(self.email)"
                    }
                  }

                  public struct Draft: SQLQueryExpression(TableDraft {
                    public typealias PrimaryTable = User
                    let id: UUID?
                    var name: String
                    var email: String
                    public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                      public typealias QueryValue = Draft
                      public let id = SQLQueryExpression(TableColumn<QueryValue, UUID?>("id", keyPath: \QueryValue.id)
                      public let name = SQLQueryExpression(TableColumn<QueryValue, String>("name", keyPath: \QueryValue.name)
                      public let email = SQLQueryExpression(TableColumn<QueryValue, String>("email", keyPath: \QueryValue.email)
                      public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                        [QueryValue.columns.id, QueryValue.columns.name, QueryValue.columns.email]
                      }
                      public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                        [QueryValue.columns.name, QueryValue.columns.email]
                      }
                      public var queryFragment: QueryFragment {
                        "\(self.id), \(self.name), \(self.email)"
                      }
                    }
                    public nonisolated static var columns: TableColumns {
                      TableColumns()
                    }

                    public nonisolated static var tableName: String {
                      User.tableName
                    }

                    public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                      self.id = try decoder.decode(UUID.self)
                      let name = try decoder.decode(String.self)
                      let email = try decoder.decode(String.self)
                      guard let name else {
                        throw QueryDecodingError.missingRequiredColumn
                      }
                      guard let email else {
                        throw QueryDecodingError.missingRequiredColumn
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

                nonisolated extension User: SQLQueryExpression(Table, SQLQueryExpression(PrimaryKeyedTable {
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var tableName: String {
                    "users"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    let id = try decoder.decode(UUID.self)
                    let name = try decoder.decode(String.self)
                    let email = try decoder.decode(String.self)
                    guard let id else {
                      throw QueryDecodingError.missingRequiredColumn
                    }
                    guard let name else {
                      throw QueryDecodingError.missingRequiredColumn
                    }
                    guard let email else {
                      throw QueryDecodingError.missingRequiredColumn
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

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition, SQLQueryExpression(PrimaryKeyedTableDefinition {
                    public typealias QueryValue = Product
                    public let id = SQLQueryExpression(TableColumn<QueryValue, Int>("id", keyPath: \QueryValue.id)
                    public let name = SQLQueryExpression(TableColumn<QueryValue, String>("name", keyPath: \QueryValue.name)
                    public let price = SQLQueryExpression(TableColumn<QueryValue, Double>("price", keyPath: \QueryValue.price)
                    public var primaryKey: SQLQueryExpression(TableColumn<QueryValue, Int> {
                      self.id
                    }
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      [QueryValue.columns.id, QueryValue.columns.name, QueryValue.columns.price]
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      [QueryValue.columns.id, QueryValue.columns.name, QueryValue.columns.price]
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.id), \(self.name), \(self.price)"
                    }
                  }

                  public struct Draft: SQLQueryExpression(TableDraft {
                    public typealias PrimaryTable = Product
                    let id: Int?
                    var name: String
                    var price: Double
                    public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                      public typealias QueryValue = Draft
                      public let id = SQLQueryExpression(TableColumn<QueryValue, Int?>("id", keyPath: \QueryValue.id)
                      public let name = SQLQueryExpression(TableColumn<QueryValue, String>("name", keyPath: \QueryValue.name)
                      public let price = SQLQueryExpression(TableColumn<QueryValue, Double>("price", keyPath: \QueryValue.price)
                      public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                        [QueryValue.columns.id, QueryValue.columns.name, QueryValue.columns.price]
                      }
                      public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                        [QueryValue.columns.name, QueryValue.columns.price]
                      }
                      public var queryFragment: QueryFragment {
                        "\(self.id), \(self.name), \(self.price)"
                      }
                    }
                    public nonisolated static var columns: TableColumns {
                      TableColumns()
                    }

                    public nonisolated static var tableName: String {
                      Product.tableName
                    }

                    public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                      self.id = try decoder.decode(Int.self)
                      let name = try decoder.decode(String.self)
                      let price = try decoder.decode(Double.self)
                      guard let name else {
                        throw QueryDecodingError.missingRequiredColumn
                      }
                      guard let price else {
                        throw QueryDecodingError.missingRequiredColumn
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

                nonisolated extension Product: SQLQueryExpression(Table, SQLQueryExpression(PrimaryKeyedTable {
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var tableName: String {
                    "products"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    let id = try decoder.decode(Int.self)
                    let name = try decoder.decode(String.self)
                    let price = try decoder.decode(Double.self)
                    guard let id else {
                      throw QueryDecodingError.missingRequiredColumn
                    }
                    guard let name else {
                      throw QueryDecodingError.missingRequiredColumn
                    }
                    guard let price else {
                      throw QueryDecodingError.missingRequiredColumn
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

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition, SQLQueryExpression(PrimaryKeyedTableDefinition {
                    public typealias QueryValue = StripeEvent
                    public let id = SQLQueryExpression(TableColumn<QueryValue, String>("id", keyPath: \QueryValue.id)
                    public let type = SQLQueryExpression(TableColumn<QueryValue, String>("type", keyPath: \QueryValue.type)
                    public let processedAt = SQLQueryExpression(TableColumn<QueryValue, Date>("processedAt", keyPath: \QueryValue.processedAt)
                    public var primaryKey: SQLQueryExpression(TableColumn<QueryValue, String> {
                      self.id
                    }
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      [QueryValue.columns.id, QueryValue.columns.type, QueryValue.columns.processedAt]
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      [QueryValue.columns.id, QueryValue.columns.type, QueryValue.columns.processedAt]
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.id), \(self.type), \(self.processedAt)"
                    }
                  }

                  public struct Draft: SQLQueryExpression(TableDraft {
                    public typealias PrimaryTable = StripeEvent
                    let id: String?
                    var type: String
                    var processedAt: Date
                    public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                      public typealias QueryValue = Draft
                      public let id = SQLQueryExpression(TableColumn<QueryValue, String?>("id", keyPath: \QueryValue.id)
                      public let type = SQLQueryExpression(TableColumn<QueryValue, String>("type", keyPath: \QueryValue.type)
                      public let processedAt = SQLQueryExpression(TableColumn<QueryValue, Date>("processedAt", keyPath: \QueryValue.processedAt)
                      public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                        [QueryValue.columns.id, QueryValue.columns.type, QueryValue.columns.processedAt]
                      }
                      public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                        [QueryValue.columns.id, QueryValue.columns.type, QueryValue.columns.processedAt]
                      }
                      public var queryFragment: QueryFragment {
                        "\(self.id), \(self.type), \(self.processedAt)"
                      }
                    }
                    public nonisolated static var columns: TableColumns {
                      TableColumns()
                    }

                    public nonisolated static var tableName: String {
                      StripeEvent.tableName
                    }

                    public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                      self.id = try decoder.decode(String.self)
                      let type = try decoder.decode(String.self)
                      let processedAt = try decoder.decode(Date.self)
                      guard let type else {
                        throw QueryDecodingError.missingRequiredColumn
                      }
                      guard let processedAt else {
                        throw QueryDecodingError.missingRequiredColumn
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

                nonisolated extension StripeEvent: SQLQueryExpression(Table, SQLQueryExpression(PrimaryKeyedTable {
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var tableName: String {
                    "stripe_events"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    let id = try decoder.decode(String.self)
                    let type = try decoder.decode(String.self)
                    let processedAt = try decoder.decode(Date.self)
                    guard let id else {
                      throw QueryDecodingError.missingRequiredColumn
                    }
                    guard let type else {
                      throw QueryDecodingError.missingRequiredColumn
                    }
                    guard let processedAt else {
                      throw QueryDecodingError.missingRequiredColumn
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

                  public nonisolated struct TableColumns: SQLQueryExpression(TableDefinition {
                    public typealias QueryValue = Order
                    public let orderId = SQLQueryExpression(TableColumn<QueryValue, Int>("orderId", keyPath: \QueryValue.orderId)
                    public let customerId = SQLQueryExpression(TableColumn<QueryValue, UUID>("customerId", keyPath: \QueryValue.customerId)
                    public let total = SQLQueryExpression(TableColumn<QueryValue, Double>("total", keyPath: \QueryValue.total)
                    public static var allColumns: [any SQLQueryExpression(TableColumnExpression] {
                      [QueryValue.columns.orderId, QueryValue.columns.customerId, QueryValue.columns.total]
                    }
                    public static var writableColumns: [any SQLQueryExpression(WritableTableColumnExpression] {
                      [QueryValue.columns.orderId, QueryValue.columns.customerId, QueryValue.columns.total]
                    }
                    public var queryFragment: QueryFragment {
                      "\(self.orderId), \(self.customerId), \(self.total)"
                    }
                  }
                }

                nonisolated extension Order: SQLQueryExpression(Table {
                  public nonisolated static var columns: TableColumns {
                    TableColumns()
                  }
                  public nonisolated static var tableName: String {
                    "orders"
                  }
                  public nonisolated init(decoder: inout some SQLQueryExpression(QueryDecoder) throws {
                    let orderId = try decoder.decode(Int.self)
                    let customerId = try decoder.decode(UUID.self)
                    let total = try decoder.decode(Double.self)
                    guard let orderId else {
                      throw QueryDecodingError.missingRequiredColumn
                    }
                    guard let customerId else {
                      throw QueryDecodingError.missingRequiredColumn
                    }
                    guard let total else {
                      throw QueryDecodingError.missingRequiredColumn
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
