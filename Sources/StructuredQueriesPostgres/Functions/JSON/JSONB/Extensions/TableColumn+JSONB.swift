import Foundation
import StructuredQueriesCore

// MARK: - Shared JSONB Operations

/// Internal marker indicating a type can be used with JSONB operations
/// Both _JSONBRepresentationProtocol and Data conform to this
public protocol _JSONBColumnValue {}

// Make both typed JSONB and raw Data conform to the marker
extension _JSONBRepresentation: _JSONBColumnValue {}
extension Data: _JSONBColumnValue {}

// MARK: - Shared JSONB Operators

/// Extension providing JSONB operators for any column storing JSONB data
/// Works for both typed JSONB (_JSONBRepresentation) and raw Data columns
extension TableColumn where Value: _JSONBColumnValue {

  // MARK: - Containment Operators

  /// PostgreSQL's @> operator - checks if the left JSONB value contains the right value
  ///
  /// Example:
  /// ```swift
  /// User.select().where { $0.settings.contains(["theme": "dark"]) }
  /// // SELECT * FROM users WHERE settings @> '{"theme": "dark"}'::jsonb
  /// ```
  public func contains<T: Encodable>(_ value: T) -> some QueryExpression<Bool> {
    JSONB.AdditionalOperators.Contains(lhs: self, rhs: value)
  }

  /// PostgreSQL's <@ operator - checks if the left JSONB value is contained by the right value
  ///
  /// Example:
  /// ```swift
  /// User.select().where { $0.settings.isContained(by: ["theme": "dark", "lang": "en", "notifications": true]) }
  /// // SELECT * FROM users WHERE settings <@ '{"theme": "dark", "lang": "en", "notifications": true}'::jsonb
  /// ```
  public func isContained<T: Encodable>(by value: T) -> some QueryExpression<Bool> {
    JSONB.AdditionalOperators.ContainedBy(lhs: self, rhs: value)
  }

  // MARK: - Key Existence Operators

  /// PostgreSQL's ? operator - checks if a key exists in the JSONB object
  ///
  /// Example:
  /// ```swift
  /// User.select().where { $0.settings.hasKey("theme") }
  /// // SELECT * FROM users WHERE settings ? 'theme'
  /// ```
  public func hasKey(_ key: String) -> some QueryExpression<Bool> {
    JSONB.AdditionalOperators.Keys.Exists(jsonb: self, key: key)
  }

  /// PostgreSQL's ?| operator - checks if any of the keys exist in the JSONB object
  ///
  /// Example:
  /// ```swift
  /// User.select().where { $0.settings.hasAny(of: ["theme", "language"]) }
  /// // SELECT * FROM users WHERE settings ?| ARRAY['theme', 'language']
  /// ```
  public func hasAny(of keys: [String]) -> some QueryExpression<Bool> {
    JSONB.AdditionalOperators.Keys.AnyExist(jsonb: self, keys: keys)
  }

  /// PostgreSQL's ?& operator - checks if all of the keys exist in the JSONB object
  ///
  /// Example:
  /// ```swift
  /// User.select().where { $0.settings.hasAll(of: ["theme", "language"]) }
  /// // SELECT * FROM users WHERE settings ?& ARRAY['theme', 'language']
  /// ```
  public func hasAll(of keys: [String]) -> some QueryExpression<Bool> {
    JSONB.AdditionalOperators.Keys.AllExist(jsonb: self, keys: keys)
  }

  // MARK: - Path Extraction Operators

  /// PostgreSQL's -> operator - extract JSON object field by key (returns JSON)
  ///
  /// Example:
  /// ```swift
  /// User.select { $0.settings.field("theme") }
  /// // SELECT settings -> 'theme' FROM users
  /// ```
  public func field(_ key: String) -> some QueryExpression<Data> {
    JSONB.Operators.Field(jsonb: self, key: key)
  }

  /// PostgreSQL's ->> operator - extract JSON object field as text
  ///
  /// Example:
  /// ```swift
  /// User.select { $0.settings.fieldAsText("theme") }
  /// // SELECT settings ->> 'theme' FROM users
  /// ```
  public func fieldAsText(_ key: String) -> some QueryExpression<String?> {
    JSONB.Operators.FieldText(jsonb: self, key: key)
  }

  /// PostgreSQL's -> operator with integer - extract JSON array element (returns JSON)
  ///
  /// Example:
  /// ```swift
  /// User.select { $0.tags.element(at: 0) }
  /// // SELECT tags -> 0 FROM users
  /// ```
  public func element(at index: Int) -> some QueryExpression<Data> {
    JSONB.Operators.Index(jsonb: self, index: index)
  }

  /// PostgreSQL's ->> operator with integer - extract JSON array element as text
  ///
  /// Example:
  /// ```swift
  /// User.select { $0.tags.elementAsText(at: 0) }
  /// // SELECT tags ->> 0 FROM users
  /// ```
  public func elementAsText(at index: Int) -> some QueryExpression<String?> {
    JSONB.Operators.IndexText(jsonb: self, index: index)
  }

  /// PostgreSQL's #> operator - extract JSON sub-object at specified path (returns JSON)
  ///
  /// Example:
  /// ```swift
  /// User.select { $0.profile.value(at: ["address", "city"]) }
  /// // SELECT profile #> '{address,city}' FROM users
  /// ```
  public func value(at path: [String]) -> some QueryExpression<Data> {
    JSONB.Operators.Path(jsonb: self, path: path)
  }

  /// PostgreSQL's #>> operator - extract JSON sub-object at specified path as text
  ///
  /// Example:
  /// ```swift
  /// User.select { $0.profile.valueAsText(at: ["address", "city"]) }
  /// // SELECT profile #>> '{address,city}' FROM users
  /// ```
  public func valueAsText(at path: [String]) -> some QueryExpression<String?> {
    JSONB.Operators.PathText(jsonb: self, path: path)
  }

  // MARK: - Set-Returning Functions

  /// PostgreSQL's jsonb_array_elements function - expand JSONB array to set of JSONB values
  ///
  /// **PostgreSQL Documentation**: Table 9.51 (Set-returning functions)
  ///
  /// **Note**: This is a set-returning function that returns multiple rows.
  ///
  /// Example:
  /// ```swift
  /// User.select { $0.tags.arrayElements() }
  /// // SELECT jsonb_array_elements(tags) FROM users
  /// ```
  public func arrayElements() -> some QueryExpression<Data> {
    JSONB.Processing.SetReturning.ArrayElements(jsonb: self, format: .jsonb)
  }

  /// PostgreSQL's jsonb_array_elements_text function - expand JSONB array to set of text values
  ///
  /// **PostgreSQL Documentation**: Table 9.51 (Set-returning functions)
  ///
  /// **Note**: This is a set-returning function that returns multiple rows.
  ///
  /// Example:
  /// ```swift
  /// User.select { $0.tags.arrayElementsText() }
  /// // SELECT jsonb_array_elements_text(tags) FROM users
  /// ```
  public func arrayElementsText() -> some QueryExpression<String> {
    JSONB.Processing.SetReturning.ArrayElementsText(jsonb: self, format: .jsonb)
  }

  /// PostgreSQL's jsonb_each function - expand JSONB object into set of key-value pairs
  ///
  /// **PostgreSQL Documentation**: Table 9.51 (Set-returning functions)
  ///
  /// **Note**: This is a set-returning function that returns multiple rows with (key text, value jsonb) columns.
  ///
  /// Example:
  /// ```swift
  /// User.select { $0.settings.each() }
  /// // SELECT jsonb_each(settings) FROM users
  /// ```
  public func each() -> some QueryExpression<(String, Data)> {
    JSONB.Processing.SetReturning.Each(jsonb: self, format: .jsonb)
  }

  /// PostgreSQL's jsonb_each_text function - expand JSONB object into set of key-value pairs (text values)
  ///
  /// **PostgreSQL Documentation**: Table 9.51 (Set-returning functions)
  ///
  /// **Note**: This is a set-returning function that returns multiple rows with (key text, value text) columns.
  ///
  /// Example:
  /// ```swift
  /// User.select { $0.settings.eachText() }
  /// // SELECT jsonb_each_text(settings) FROM users
  /// ```
  public func eachText() -> some QueryExpression<(String, String)> {
    JSONB.Processing.SetReturning.EachText(jsonb: self, format: .jsonb)
  }

  /// PostgreSQL's jsonb_object_keys function - returns set of keys in the outermost JSONB object
  ///
  /// **PostgreSQL Documentation**: Table 9.51 (Set-returning functions)
  ///
  /// **Note**: This is a set-returning function that returns multiple rows.
  ///
  /// Example:
  /// ```swift
  /// User.select { $0.settings.objectKeys() }
  /// // SELECT jsonb_object_keys(settings) FROM users
  /// ```
  public func objectKeys() -> some QueryExpression<String> {
    JSONB.Processing.SetReturning.ObjectKeys(jsonb: self, format: .jsonb)
  }

  // MARK: - Path Functions

  /// PostgreSQL's jsonb_extract_path function - extract JSONB sub-object at specified path
  ///
  /// **PostgreSQL Documentation**: Table 9.51 (Path functions)
  ///
  /// Equivalent to the #> operator, but as a function.
  ///
  /// Example:
  /// ```swift
  /// User.select { $0.profile.extractPath(["address", "city"]) }
  /// // SELECT jsonb_extract_path(profile, 'address', 'city') FROM users
  /// ```
  public func extractPath(_ path: [String]) -> some QueryExpression<Data> {
    JSONB.Processing.Path.ExtractPath(jsonb: self, path: path, format: .jsonb)
  }

  /// PostgreSQL's jsonb_extract_path_text function - extract JSONB sub-object at specified path as text
  ///
  /// **PostgreSQL Documentation**: Table 9.51 (Path functions)
  ///
  /// Equivalent to the #>> operator, but as a function.
  ///
  /// Example:
  /// ```swift
  /// User.select { $0.profile.extractPathText(["address", "city"]) }
  /// // SELECT jsonb_extract_path_text(profile, 'address', 'city') FROM users
  /// ```
  public func extractPathText(_ path: [String]) -> some QueryExpression<String?> {
    JSONB.Processing.Path.ExtractPathText(jsonb: self, path: path, format: .jsonb)
  }

  /// PostgreSQL's jsonb_path_exists function - does JSON path return any item?
  ///
  /// **PostgreSQL Documentation**: Table 9.51 (Path functions)
  ///
  /// **Note**: Requires PostgreSQL 12+
  ///
  /// Example:
  /// ```swift
  /// User.where { $0.settings.pathExists("$.theme") }
  /// // SELECT * FROM users WHERE jsonb_path_exists(settings, '$.theme')
  /// ```
  public func pathExists(_ path: String) -> some QueryExpression<Bool> {
    JSONB.Processing.Path.PathExists(jsonb: self, path: path)
  }

  /// PostgreSQL's jsonb_path_query function - get all JSONB items returned by JSON path
  ///
  /// **PostgreSQL Documentation**: Table 9.51 (Path functions)
  ///
  /// **Note**: This is a set-returning function that returns multiple rows. Requires PostgreSQL 12+
  ///
  /// Example:
  /// ```swift
  /// User.select { $0.metadata.pathQuery("$.tags[*]") }
  /// // SELECT jsonb_path_query(metadata, '$.tags[*]') FROM users
  /// ```
  public func pathQuery(_ path: String) -> some QueryExpression<Data> {
    JSONB.Processing.Path.PathQuery(jsonb: self, path: path)
  }

}

// MARK: - Type-Preserving Mutation Operations (Typed JSONB)

/// Mutation operations that preserve the typed JSONB type for UPDATE statements
extension TableColumn where Value: _JSONBRepresentationProtocol {

  // MARK: - Concatenation

  /// PostgreSQL's || operator - concatenate two JSONB values
  ///
  /// Returns the same JSONB type as the input column, allowing assignment in UPDATE statements.
  ///
  /// Example:
  /// ```swift
  /// User.update { $0.settings = $0.settings.concat(["newField": "value"]) }
  /// // UPDATE users SET settings = settings || '{"newField": "value"}'::jsonb
  /// ```
  public func concat<T: Encodable>(_ value: T) -> some QueryExpression<Value> {
    JSONB.AdditionalOperators.TypedConcat(lhs: self, rhs: value)
  }

  // MARK: - Deletion Operators

  /// PostgreSQL's - operator - delete key/value pair or array element (by key)
  ///
  /// Returns the same JSONB type as the input column, allowing assignment in UPDATE statements.
  ///
  /// Example:
  /// ```swift
  /// User.update { $0.settings = $0.settings.removing("obsoleteField") }
  /// // UPDATE users SET settings = settings - 'obsoleteField'
  /// ```
  public func removing(_ key: String) -> some QueryExpression<Value> {
    JSONB.AdditionalOperators.TypedDelete.Key(jsonb: self, key: key)
  }

  /// PostgreSQL's - operator - delete multiple keys
  ///
  /// Returns the same JSONB type as the input column, allowing assignment in UPDATE statements.
  ///
  /// Example:
  /// ```swift
  /// User.update { $0.settings = $0.settings.removing(keys: ["field1", "field2"]) }
  /// // UPDATE users SET settings = settings - ARRAY['field1', 'field2']
  /// ```
  public func removing(keys: [String]) -> some QueryExpression<Value> {
    JSONB.AdditionalOperators.TypedDelete.Keys(jsonb: self, keys: keys)
  }

  /// PostgreSQL's - operator - delete array element by index
  ///
  /// Returns the same JSONB type as the input column, allowing assignment in UPDATE statements.
  ///
  /// Example:
  /// ```swift
  /// User.update { $0.tags = $0.tags.removing(at: 2) }
  /// // UPDATE users SET tags = tags - 2
  /// ```
  public func removing(at index: Int) -> some QueryExpression<Value> {
    JSONB.AdditionalOperators.TypedDelete.Index(jsonb: self, index: index)
  }

  /// PostgreSQL's #- operator - delete field or element at specified path
  ///
  /// Returns the same JSONB type as the input column, allowing assignment in UPDATE statements.
  ///
  /// Example:
  /// ```swift
  /// User.update { $0.profile = $0.profile.removing(path: ["address", "zipcode"]) }
  /// // UPDATE users SET profile = profile #- '{address,zipcode}'
  /// ```
  public func removing(path: [String]) -> some QueryExpression<Value> {
    JSONB.AdditionalOperators.TypedDelete.Path(jsonb: self, path: path)
  }

  // MARK: - Manipulation Functions

  /// PostgreSQL's jsonb_set function - Update JSONB at path
  ///
  /// Returns the same JSONB type as the input column, allowing assignment in UPDATE statements.
  ///
  /// Example:
  /// ```swift
  /// User.update {
  ///     $0.settings = $0.settings.setting(["preferences", "theme"], to: "dark")
  /// }
  /// // UPDATE users SET settings = jsonb_set(settings, '{preferences,theme}', '"dark"'::jsonb, true)
  /// ```
  public func setting<T: Encodable>(
    _ path: [String],
    to value: T,
    createIfMissing: Bool = true
  ) -> some QueryExpression<Value> {
    JSONB.Processing.TypedSet(
      jsonb: self, path: path, value: value, createIfMissing: createIfMissing)
  }

  /// PostgreSQL's jsonb_insert function - Insert into JSONB at path
  ///
  /// Returns the same JSONB type as the input column, allowing assignment in UPDATE statements.
  ///
  /// Example:
  /// ```swift
  /// User.update {
  ///     $0.settings = $0.settings.inserting(["id": 123], at: ["items", "0"])
  /// }
  /// // UPDATE users SET settings = jsonb_insert(settings, '{items,0}', '{"id": 123}'::jsonb, false)
  /// ```
  public func inserting<T: Encodable>(
    _ value: T,
    at path: [String],
    after: Bool = false
  ) -> some QueryExpression<Value> {
    JSONB.Processing.TypedInsert(jsonb: self, path: path, value: value, after: after)
  }

  /// PostgreSQL's jsonb_strip_nulls function - Remove null values from JSONB
  ///
  /// Returns the same JSONB type as the input column, allowing assignment in UPDATE statements.
  ///
  /// Example:
  /// ```swift
  /// User.update { $0.settings = $0.settings.strippingNulls() }
  /// // UPDATE users SET settings = jsonb_strip_nulls(settings)
  /// ```
  public func strippingNulls() -> some QueryExpression<Value> {
    JSONB.Processing.TypedStripNulls(jsonb: self)
  }
}

// MARK: - Data Mutation Operations (Raw Data)

/// Mutation operations for raw Data columns storing JSONB
extension TableColumn where Value == Data {

  // MARK: - Concatenation

  /// PostgreSQL's || operator - concatenate two JSONB values
  ///
  /// Example:
  /// ```swift
  /// User.update { $0.settings = $0.settings.concat(["newField": "value"]) }
  /// // UPDATE users SET settings = settings || '{"newField": "value"}'::jsonb
  /// ```
  public func concat<T: Encodable>(_ value: T) -> some QueryExpression<Data> {
    JSONB.AdditionalOperators.Concat(lhs: self, rhs: value)
  }

  // MARK: - Deletion Operators

  /// PostgreSQL's - operator - delete key/value pair or array element (by key)
  ///
  /// Example:
  /// ```swift
  /// User.update { $0.settings = $0.settings.removing("obsoleteField") }
  /// // UPDATE users SET settings = settings - 'obsoleteField'
  /// ```
  public func removing(_ key: String) -> some QueryExpression<Data> {
    JSONB.AdditionalOperators.Delete.Key(jsonb: self, key: key)
  }

  /// PostgreSQL's - operator - delete multiple keys
  ///
  /// Example:
  /// ```swift
  /// User.update { $0.settings = $0.settings.removing(keys: ["field1", "field2"]) }
  /// // UPDATE users SET settings = settings - ARRAY['field1', 'field2']
  /// ```
  public func removing(keys: [String]) -> some QueryExpression<Data> {
    JSONB.AdditionalOperators.Delete.Keys(jsonb: self, keys: keys)
  }

  /// PostgreSQL's - operator - delete array element by index
  ///
  /// Example:
  /// ```swift
  /// User.update { $0.tags = $0.tags.removing(at: 2) }
  /// // UPDATE users SET tags = tags - 2
  /// ```
  public func removing(at index: Int) -> some QueryExpression<Data> {
    JSONB.AdditionalOperators.Delete.Index(jsonb: self, index: index)
  }

  /// PostgreSQL's #- operator - delete field or element at specified path
  ///
  /// Example:
  /// ```swift
  /// User.update { $0.profile = $0.profile.removing(path: ["address", "zipcode"]) }
  /// // UPDATE users SET profile = profile #- '{address,zipcode}'
  /// ```
  public func removing(path: [String]) -> some QueryExpression<Data> {
    JSONB.AdditionalOperators.Delete.Path(jsonb: self, path: path)
  }
}
