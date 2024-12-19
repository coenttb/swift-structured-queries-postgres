# ``StructuredQueriesCore/Table``

## Topics

### Query building

- ``all``
- ``distinct(_:)``
- ``select(_:)``
- ``join(_:on:)``
- ``leftJoin(_:on:)``
- ``rightJoin(_:on:)``
- ``fullJoin(_:on:)``
- ``where(_:)``
- ``group(by:)``
- ``having(_:)``
- ``order(by:)``
- ``limit(_:offset:)``
- ``count(filter:)``
- ``insert(or:_:onConflict:)``
- ``insert(or:_:values:onConflict:)``
- ``insert(or:_:select:onConflict:)``
- ``insert(or:onConflict:)``
- ``update(or:set:)``
- ``delete()``

### Schema definition

- ``tableName``
- ``columns-swift.type.property``
- ``TableColumns``
- ``TableColumn``
- ``TableColumnExpression``
- ``TableDefinition``

### Scoping

- ``DefaultScope``
- ``unscoped``

### Column shorthand syntax

- ``subscript(dynamicMember:)``

### Table aliasing

- ``tableAlias``
- ``as(_:)``
