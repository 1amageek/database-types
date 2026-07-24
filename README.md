# Database Types

`database-types` provides canonical primitive values shared by the database
stack. The core remains Foundation-independent and Embedded-safe; platform
conversion is opt-in.

The package owns value semantics only. Transport, wire framing, query
execution, storage transactions, and platform bridges belong to separate
packages.

## Products

- `DatabaseTypes`: core primitive and ownership types for Swift Embedded and native
  runtimes.
- `DatabaseTypesFoundation`: explicit `Date`, `Data`, `UUID`, `Decimal`,
  calendar, and time-zone conversion for native runtimes.

## Current types

- `ByteString`: immutable byte value with constant-time zero-copy slicing.
- `ByteStringOwner`: stable external ownership contract used by host adapters.
- `FieldValue`: closed field-value algebra with exact representation identity
  and deterministic total ordering.
- `CivilDate`, `CivilTime`, `CivilDateTime`, and `Timestamp`: distinct civil and
  absolute time domains.
- `TimeSpan` and `CalendarPeriod`: distinct fixed and calendar-relative
  amounts.
- `ExactDecimal`: normalized `Int128` coefficient and `Int32` scale.
- `UUID`, `GeographicPoint`, `GeographicPosition`, and fixed-width numeric
  `Vector`: validated specialized values.
- `ReferenceIdentifier` and `EntityReference`: canonical primitive reference
  components.
- `FieldObject`: canonical string-keyed object that contains the JSON object
  value model and additional `FieldValue` primitives.
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
| Foundation-independent primitive storage | Model and Codable adaptation |
| Explicit Foundation scalar conversion product | Implicit conversion policy |

The package contains no compatibility aliases. Public declarations are named
for the represented value or ownership contract rather than for this module.

See [Database Value Specification](Documentation/DatabaseValueSpecification.md)
for invariants, conversion policy, comparison rules, and ownership boundaries.
