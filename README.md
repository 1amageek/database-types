# Database Types

`DatabaseTypes` provides the Foundation-independent primitive values shared by
the database stack.

The package owns value semantics only. Transport, wire framing, query
execution, storage transactions, and platform bridges belong to separate
packages.

## Products

- `DatabaseTypes`: core value and protocol types for Swift Embedded and native
  runtimes.

## Current types

- `ByteString`: immutable byte value with constant-time zero-copy slicing.
- `ByteStringOwner`: stable external ownership contract used by host adapters.
- `FieldValue`: closed field-value algebra with exact fixed-width numeric
  identity.
- `CivilDate`, `Timestamp`, `UUID`, and `ExactDecimal`: validated scalar values.
- `IdentifierValue` and `EntityIdentity`: typed scalar and composite identities.
- `ObjectField`: one numbered, named field in a structural value.
- `RDFTerm` and its atomic RDF components: validated RDF values, subjects,
  predicates, IRIs, blank-node identifiers, literals, language tags, and XSD
  datatypes.

## Ownership boundary

| Owned here | Owned by an upper package |
|---|---|
| Primitive representation and intrinsic invariants | Query and schema meaning |
| Exact equality, hashing, and structural ordering | Numeric query coercion |
| Immutable byte ownership and scoped borrowing | Wire framing and binary codecs |
| RDF atomic value semantics | Graph execution and algorithms |
| Foundation-independent primitive storage | Lexical, Foundation, and Codable adaptation |

The package contains no compatibility aliases. Public declarations are named
for the represented value or ownership contract rather than for this module.
