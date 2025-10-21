import Foundation
import StructuredQueriesCore

// MARK: - UUID Extraction Functions
//
// PostgreSQL Chapter 9.14: UUID Functions
// https://www.postgresql.org/docs/18/functions-uuid.html
//
// Functions for extracting information from UUIDs

extension QueryExpression where QueryValue == UUID {
    /// PostgreSQL's `uuid_extract_version()` - Extract UUID version number
    ///
    /// Returns the version number (1-7) from a UUID.
    ///
    /// ```swift
    /// User.where { $0.id.extractVersion() == 7 }
    /// // SELECT … FROM "users" WHERE uuid_extract_version("users"."id") = 7
    ///
    /// Event.select {
    ///     ($0.id, $0.id.extractVersion())
    /// }
    /// // SELECT "events"."id", uuid_extract_version("events"."id") FROM "events"
    /// ```
    ///
    /// - Returns: UUID version as Int (1-7), or NULL for non-RFC-9562 variants
    ///
    /// **UUID Versions:**
    /// - `1`: Time-based with MAC address
    /// - `3`: Name-based with MD5
    /// - `4`: Random (most common for primary keys)
    /// - `5`: Name-based with SHA-1
    /// - `6`: Time-based, reordered (new)
    /// - `7`: Time-ordered (recommended for databases)
    ///
    /// > Note: Returns NULL if the UUID does not conform to RFC 9562 standard.
    ///
    /// > Tip: Use this to filter for specific UUID types:
    /// > `Event.where { $0.id.extractVersion() == 7 }` finds all time-ordered UUIDs.
    public func extractVersion() -> some QueryExpression<Int?> {
        SQLQueryExpression(
            "uuid_extract_version(\(self.queryFragment))",
            as: Int?.self
        )
    }

    /// PostgreSQL's `uuid_extract_timestamp()` - Extract timestamp from UUID
    ///
    /// Returns the embedded timestamp from UUIDv1 or UUIDv7.
    /// Returns NULL for other UUID versions.
    ///
    /// ```swift
    /// Event.select { $0.id.extractTimestamp() }
    /// // SELECT uuid_extract_timestamp("events"."id") FROM "events"
    ///
    /// Event.where {
    ///     $0.id.extractTimestamp() != nil &&
    ///     $0.id.extractTimestamp()! > Date.currentDate
    /// }
    /// // SELECT … FROM "events"
    /// // WHERE uuid_extract_timestamp("events"."id") IS NOT NULL
    /// //   AND uuid_extract_timestamp("events"."id") > CURRENT_DATE
    /// ```
    ///
    /// - Returns: Timestamp with time zone, or NULL if UUID is not v1 or v7
    ///
    /// > Note: Only UUIDv1 and UUIDv7 contain extractable timestamps.
    /// > UUIDv4 (random) will return NULL.
    ///
    /// > Tip: Check version first to ensure timestamp exists:
    /// > ```swift
    /// > Event.where {
    /// >     $0.id.extractVersion() == 7 &&
    /// >     $0.id.extractTimestamp()! > someDate
    /// > }
    /// > ```
    ///
    /// **NULL Handling Examples:**
    /// ```swift
    /// // Filter only UUIDs with timestamps
    /// Event.where { $0.id.extractTimestamp() != nil }
    ///
    /// // Safely compare after NULL check
    /// Event.where {
    ///     let timestamp = $0.id.extractTimestamp()
    ///     timestamp != nil && timestamp! > someDate
    /// }
    ///
    /// // Combine with version check for type safety
    /// Event.where {
    ///     $0.id.extractVersion() == 7 &&
    ///     $0.id.extractTimestamp()! >= Date().addingTimeInterval(-3600)
    /// }
    /// ```
    ///
    /// **Use cases:**
    /// - Query events by embedded timestamp without separate `createdAt` column
    /// - Analyze temporal distribution of UUIDv7-keyed records
    /// - Audit when records were created server-side
    /// - Time-based partitioning using UUID timestamps
    public func extractTimestamp() -> some QueryExpression<Date?> {
        SQLQueryExpression(
            "uuid_extract_timestamp(\(self.queryFragment))",
            as: Date?.self
        )
    }
}

// MARK: - Optional UUID Extraction

extension QueryExpression where QueryValue == UUID? {
    /// PostgreSQL's `uuid_extract_version()` - Extract UUID version number from optional UUID
    ///
    /// Returns the version number (1-7) from an optional UUID, or NULL if the UUID is NULL.
    ///
    /// ```swift
    /// User.select { $0.alternateId.extractVersion() }
    /// // SELECT uuid_extract_version("users"."alternateId") FROM "users"
    /// ```
    ///
    /// - Returns: UUID version as Int?, or NULL if input is NULL or non-RFC-9562
    public func extractVersion() -> some QueryExpression<Int?> {
        SQLQueryExpression(
            "uuid_extract_version(\(self.queryFragment))",
            as: Int?.self
        )
    }

    /// PostgreSQL's `uuid_extract_timestamp()` - Extract timestamp from optional UUID
    ///
    /// Returns the embedded timestamp from an optional UUIDv1 or UUIDv7, or NULL.
    ///
    /// ```swift
    /// Event.select { $0.optionalId.extractTimestamp() }
    /// // SELECT uuid_extract_timestamp("events"."optionalId") FROM "events"
    /// ```
    ///
    /// - Returns: Timestamp with time zone, or NULL if input is NULL or not v1/v7
    public func extractTimestamp() -> some QueryExpression<Date?> {
        SQLQueryExpression(
            "uuid_extract_timestamp(\(self.queryFragment))",
            as: Date?.self
        )
    }
}
