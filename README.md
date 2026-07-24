# Database Types

`database-types` provides canonical primitive values shared by the database
stack. The core remains Foundation-independent and Embedded-safe; platform
conversion is opt-in.

The package owns value semantics only. Transport, wire framing, query
execution, storage transactions, and platform bridges belong to separate
packages.

## Dependency direction

```text
database-kit ───────────────> DatabaseTypes
DatabaseTypesFoundation ────> DatabaseTypes
```

Arrows point from a consumer to its dependency. `DatabaseTypes` never imports
or depends on `database-kit`; the packages build, test, and release
independently. A consumer must declare its own `DatabaseTypes` dependency.

## Products

- `DatabaseTypes`: core primitive and ownership types for Swift Embedded and native
  runtimes.
- `DatabaseTypesFoundation`: explicit `Date`, `Data`, `UUID`, `Decimal`,
  calendar, and time-zone conversion for native runtimes.

## Requirements

- Swift 6.4 or newer.
- A Swift 6.4 or newer Wasm Embedded SDK for Embedded builds.
- macOS 15, iOS 18, tvOS 18, watchOS 11, or visionOS 2 for the optional
  Foundation adapter.

The Swift compiler and Wasm Embedded SDK must use the same toolchain version.

## Package dependency

The package is in initial development and currently publishes its development
line from `main`:

```swift
dependencies: [
    .package(
        url: "https://github.com/1amageek/database-types.git",
        branch: "main"
    ),
]
```

Depend on `DatabaseTypes` for the Foundation-independent primitive layer.
Depend on `DatabaseTypesFoundation` only in native targets that require
explicit Foundation conversion.

## Verification

Run the native test suite with Xcode:

```bash
xcodebuild test \
  -scheme database-types-Package \
  -destination 'platform=macOS,arch=arm64'
```

Compile the core with a matching Swift 6.4+ compiler and Embedded SDK:

```bash
swift build \
  --configuration release \
  --product DatabaseTypes \
  --swift-sdk <swift-6.4-or-newer_wasm-embedded>
```

`DatabaseTypesFoundation` is intentionally absent from the Embedded dependency
graph.

## Source layout

The core is organized by represented value domain. Directories do not define
additional modules or dependency boundaries.

| Directory | Responsibility |
|---|---|
| `FieldValues` | Closed field-value algebra and canonical objects |
| `Bytes` | Immutable byte ownership, borrowing, and slicing |
| `Decimal` | Exact base-10 representation and arithmetic |
| `Temporal` | Civil, absolute, fixed-duration, and calendar-period values |
| `Geographic` | Two- and three-dimensional WGS 84 values |
| `Vector` | Fixed-width dense numeric vectors |
| `Identity` | UUIDs, reference identifiers, and reference values |
| `RDF` | RDF terms and their intrinsic validated components |
| `Text` | Shared exact text-identity implementation |

`DatabaseTypesFoundation` mirrors only the domains that require Foundation
conversion. Tests follow the same domain layout; cross-domain invariant tests
remain under `Invariants`.

## Current types

- `ByteString`: immutable byte value that retains `Array`, `ArraySlice`, or an
  external owner and provides constant-time zero-copy slicing.
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
