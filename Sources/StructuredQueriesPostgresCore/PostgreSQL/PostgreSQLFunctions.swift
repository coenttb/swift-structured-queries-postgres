import Foundation

// MARK: - PostgreSQL Boolean Conversion

extension QueryExpression where QueryValue == Bool {
    /// Converts boolean to PostgreSQL JSON boolean representation
    public func toJSONBoolean() -> some QueryExpression<String> {
        SQLQueryExpression("CASE WHEN \(self.queryFragment) THEN 'true' ELSE 'false' END", as: String.self)
    }
}

// MARK: - PostgreSQL JSON Quote

extension QueryExpression where QueryValue == String {
    /// PostgreSQL's to_json function for proper JSON escaping
    public func jsonQuote() -> some QueryExpression<Data> {
        SQLQueryExpression("to_json(\(self.queryFragment))", as: Data.self)
    }
}

extension QueryExpression where QueryValue == String? {
    /// PostgreSQL's to_json function for proper JSON escaping (nullable)
    public func jsonQuote() -> some QueryExpression<Data?> {
        SQLQueryExpression("to_json(\(self.queryFragment))", as: Data?.self)
    }
}

extension QueryExpression {
    /// Generic JSON quote for any expression type
    public func jsonQuote() -> some QueryExpression<Data> {
        SQLQueryExpression("to_json(\(self.queryFragment))", as: Data.self)
    }
}

// MARK: - PostgreSQL ROW_NUMBER and Window Functions

extension QueryExpression {
    /// PostgreSQL's ROW_NUMBER() window function
    public static func rowNumber() -> some QueryExpression<Int> {
        SQLQueryExpression("ROW_NUMBER() OVER ()", as: Int.self)
    }
    
    /// PostgreSQL's ROW_NUMBER() with partition and order
    public static func rowNumber(
        partitionBy partition: (any QueryExpression)? = nil,
        orderBy order: (any QueryExpression)? = nil
    ) -> some QueryExpression<Int> {
        var fragment: QueryFragment = "ROW_NUMBER() OVER ("
        
        if let partition {
            fragment.append("PARTITION BY \(partition.queryFragment)")
            if order != nil {
                fragment.append(" ")
            }
        }
        
        if let order {
            fragment.append("ORDER BY \(order.queryFragment)")
        }
        
        fragment.append(")")
        return SQLQueryExpression(fragment, as: Int.self)
    }
}

// MARK: - PostgreSQL Coalesce (Alternative to IFNULL)

extension QueryExpression where QueryValue: QueryBindable {
    /// PostgreSQL's COALESCE function (equivalent to SQLite's IFNULL)
    /// Returns the first non-null value
    public func coalesce(_ defaultValue: QueryValue) -> some QueryExpression<QueryValue> {
        SQLQueryExpression("COALESCE(\(self.queryFragment), \(bind: defaultValue))", as: QueryValue.self)
    }
}

extension QueryExpression {
    /// PostgreSQL's COALESCE with another expression
    public func coalesce(_ defaultExpression: some QueryExpression<QueryValue>) -> some QueryExpression<QueryValue> {
        SQLQueryExpression("COALESCE(\(self.queryFragment), \(defaultExpression.queryFragment))", as: QueryValue.self)
    }
}

// MARK: - PostgreSQL EXISTS Support

/// PostgreSQL's EXISTS function
public func exists(_ subquery: some Statement) -> some QueryExpression<Bool> {
    SQLQueryExpression("EXISTS (\(subquery.queryFragment))", as: Bool.self)
}

/// PostgreSQL's NOT EXISTS function
public func notExists(_ subquery: some Statement) -> some QueryExpression<Bool> {
    SQLQueryExpression("NOT EXISTS (\(subquery.queryFragment))", as: Bool.self)
}

// MARK: - PostgreSQL String Functions

extension QueryExpression where QueryValue == String {
    /// PostgreSQL's string concatenation using ||
    public func concat(_ other: String) -> some QueryExpression<String> {
        SQLQueryExpression("(\(self.queryFragment) || \(bind: other))", as: String.self)
    }
    
    /// PostgreSQL's string concatenation with another expression
    public func concat(_ other: some QueryExpression<String>) -> some QueryExpression<String> {
        SQLQueryExpression("(\(self.queryFragment) || \(other.queryFragment))", as: String.self)
    }
    
    /// PostgreSQL's POSITION function (equivalent to SQLite's INSTR)
    public func position(of substring: String) -> some QueryExpression<Int> {
        SQLQueryExpression("POSITION(\(bind: substring) IN \(self.queryFragment))", as: Int.self)
    }
    
    /// PostgreSQL's STRPOS function (alternative to POSITION)
    public func strpos(_ substring: String) -> some QueryExpression<Int> {
        SQLQueryExpression("STRPOS(\(self.queryFragment), \(bind: substring))", as: Int.self)
    }
    
    /// PostgreSQL's SUBSTRING function
    public func substring(from start: Int, for length: Int? = nil) -> some QueryExpression<String> {
        if let length {
            return SQLQueryExpression("SUBSTRING(\(self.queryFragment) FROM \(start) FOR \(length))", as: String.self)
        } else {
            return SQLQueryExpression("SUBSTRING(\(self.queryFragment) FROM \(start))", as: String.self)
        }
    }
}

// MARK: - PostgreSQL Date/Time Functions

public enum DateField: String {
    case year = "YEAR"
    case month = "MONTH"
    case day = "DAY"
    case hour = "HOUR"
    case minute = "MINUTE"
    case second = "SECOND"
    case dow = "DOW" // day of week
    case doy = "DOY" // day of year
    case epoch = "EPOCH"
}

public enum DateTruncPrecision: String {
    case year = "year"
    case month = "month"
    case day = "day"
    case hour = "hour"
    case minute = "minute"
    case second = "second"
}

extension QueryExpression where QueryValue == Date {
    /// PostgreSQL's EXTRACT function for date parts
    public func extract(_ field: DateField) -> some QueryExpression<Double> {
        SQLQueryExpression("EXTRACT(\(raw: field.rawValue) FROM \(self.queryFragment))", as: Double.self)
    }
    
    /// PostgreSQL's date truncation
    public func dateTrunc(_ precision: DateTruncPrecision) -> some QueryExpression<Date> {
        SQLQueryExpression("DATE_TRUNC('\(raw: precision.rawValue)', \(self.queryFragment))", as: Date.self)
    }
}

// MARK: - PostgreSQL CURRENT_TIMESTAMP

extension Date {
    /// PostgreSQL's CURRENT_TIMESTAMP
    public static var currentTimestamp: some QueryExpression<Date> {
        SQLQueryExpression("CURRENT_TIMESTAMP", as: Date.self)
    }
    
    /// PostgreSQL's CURRENT_DATE
    public static var currentDate: some QueryExpression<Date> {
        SQLQueryExpression("CURRENT_DATE", as: Date.self)
    }
}

// MARK: - PostgreSQL String Aggregation (Alternative to GROUP_CONCAT)

extension QueryExpression where QueryValue == String {
    /// PostgreSQL's STRING_AGG function (equivalent to SQLite's GROUP_CONCAT)
    /// Aggregates string values with a separator
    public func stringAgg(
        _ separator: String = ",",
        order: (any QueryExpression)? = nil,
        filter: (any QueryExpression<Bool>)? = nil
    ) -> some QueryExpression<String?> {
        var fragment: QueryFragment = "STRING_AGG("
        fragment.append(self.queryFragment)
        fragment.append(", \(bind: separator)")
        
        if let order {
            fragment.append(" ORDER BY \(order.queryFragment)")
        }
        fragment.append(")")
        
        if let filter {
            fragment.append(" FILTER (WHERE \(filter.queryFragment))")
        }
        
        return SQLQueryExpression(fragment, as: String?.self)
    }
    
    /// PostgreSQL's STRING_AGG with DISTINCT
    public func stringAgg(
        distinct: Bool,
        separator: String = ",",
        order: (any QueryExpression)? = nil,
        filter: (any QueryExpression<Bool>)? = nil
    ) -> some QueryExpression<String?> {
        var fragment: QueryFragment = "STRING_AGG("
        if distinct {
            fragment.append("DISTINCT ")
        }
        fragment.append(self.queryFragment)
        fragment.append(", \(bind: separator)")
        
        if let order {
            fragment.append(" ORDER BY \(order.queryFragment)")
        }
        fragment.append(")")
        
        if let filter {
            fragment.append(" FILTER (WHERE \(filter.queryFragment))")
        }
        
        return SQLQueryExpression(fragment, as: String?.self)
    }
}

extension QueryExpression {
    /// Generic STRING_AGG for any expression type (will be cast to text)
    public func stringAgg(
        _ separator: String = ",",
        order: (any QueryExpression)? = nil,
        filter: (any QueryExpression<Bool>)? = nil
    ) -> some QueryExpression<String?> {
        var fragment: QueryFragment = "STRING_AGG(CAST("
        fragment.append(self.queryFragment)
        fragment.append(" AS TEXT), \(bind: separator)")
        
        if let order {
            fragment.append(" ORDER BY \(order.queryFragment)")
        }
        fragment.append(")")
        
        if let filter {
            fragment.append(" FILTER (WHERE \(filter.queryFragment))")
        }
        
        return SQLQueryExpression(fragment, as: String?.self)
    }
}

// MARK: - PostgreSQL Binary Functions

extension QueryExpression where QueryValue == [UInt8] {
    /// PostgreSQL's ENCODE function (equivalent to SQLite's HEX)
    /// Encodes binary data to hex string
    public func encodeHex() -> some QueryExpression<String> {
        SQLQueryExpression("ENCODE(\(self.queryFragment), 'hex')", as: String.self)
    }
    
    /// PostgreSQL's ENCODE function with custom encoding
    public func encode(_ format: String) -> some QueryExpression<String> {
        SQLQueryExpression("ENCODE(\(self.queryFragment), \(bind: format))", as: String.self)
    }
}

extension QueryExpression where QueryValue == String {
    /// PostgreSQL's DECODE function (equivalent to SQLite's UNHEX)
    /// Decodes hex string to binary data
    public func decodeHex() -> some QueryExpression<[UInt8]> {
        SQLQueryExpression("DECODE(\(self.queryFragment), 'hex')", as: [UInt8].self)
    }
    
    /// PostgreSQL's QUOTE_LITERAL function (equivalent to SQLite's QUOTE)
    /// Quotes a string for safe inclusion in SQL
    public func quoteLiteral() -> some QueryExpression<String> {
        SQLQueryExpression("QUOTE_LITERAL(\(self.queryFragment))", as: String.self)
    }
    
    /// PostgreSQL's QUOTE_IDENT function
    /// Quotes an identifier for safe inclusion in SQL
    public func quoteIdent() -> some QueryExpression<String> {
        SQLQueryExpression("QUOTE_IDENT(\(self.queryFragment))", as: String.self)
    }
    
    /// PostgreSQL's ASCII function (partial equivalent to SQLite's UNICODE)
    /// Returns the ASCII code of the first character
    public func ascii() -> some QueryExpression<Int?> {
        SQLQueryExpression("ASCII(\(self.queryFragment))", as: Int?.self)
    }
}

// MARK: - PostgreSQL Random Functions

extension Int {
    /// PostgreSQL's GEN_RANDOM_BYTES function (equivalent to SQLite's RANDOMBLOB)
    /// Generates random bytes
    public func genRandomBytes() -> some QueryExpression<[UInt8]> {
        SQLQueryExpression("GEN_RANDOM_BYTES(\(self))", as: [UInt8].self)
    }
}

// MARK: - PostgreSQL Total Alternative

extension QueryExpression where QueryValue: Numeric & QueryBindable {
    /// PostgreSQL alternative to SQLite's TOTAL function
    /// Returns 0 if the result set is empty (instead of NULL like SUM)
    public func sumOrZero() -> some QueryExpression<QueryValue> {
        SQLQueryExpression("COALESCE(SUM(\(self.queryFragment)), 0)", as: QueryValue.self)
    }
    
    /// PostgreSQL SUM with default value
    public func sumOr(_ defaultValue: QueryValue) -> some QueryExpression<QueryValue> {
        SQLQueryExpression("COALESCE(SUM(\(self.queryFragment)), \(bind: defaultValue))", as: QueryValue.self)
    }
}