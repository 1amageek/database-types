# Database Types

`DatabaseTypes` provides Foundation-independent currency types shared by
database clients, runtimes, and storage adapters.

The package owns value semantics only. Transport, wire framing, query
execution, storage transactions, and platform bridges belong to separate
packages.

## Products

- `DatabaseTypes`: core value and protocol types for Swift Embedded and native
  runtimes.

## Current types

- `ByteString`: immutable byte value with constant-time zero-copy slicing.
- `ByteStringOwner`: stable external ownership contract used by host adapters.

`FieldValue`, identity, scalar, graph, schema, and operation currency types will
move here from `database-kit`. Compatibility aliases are not provided.
