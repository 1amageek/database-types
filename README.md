# Database Types

Canonical, Foundation-independent primitive values for Swift databases.

`database-types` provides precise value semantics for data that must cross
storage, query, and transport boundaries without losing representation
identity. The core library is designed for both native Swift and Embedded
Swift. Foundation conversions are available as a separate, opt-in product.

## What it provides

| Domain | Types and guarantees |
|---|---|
| Field values | A closed `FieldValue` algebra with explicit numeric widths, recursive arrays and objects, deterministic equality, hashing, and ordering |
| Bytes | Immutable `ByteString` ownership, constant-time bounded slices, scoped borrowing, and explicit detachment |
| Decimal | Canonical `ExactDecimal` values backed by an `Int128` coefficient and `Int32` scale |
| Time | Separate civil dates, civil times, local date-times, absolute timestamps, fixed durations, and calendar-relative periods |
| Identity | Canonical UUIDs, reference identifiers, and entity references |
| Spatial and numeric | Validated WGS 84 coordinates and fixed-width dense vectors |
| RDF | Validated IRIs, blank nodes, literals, language tags, datatypes, subjects, predicates, and terms |

Every public value is `Sendable`. Invalid intrinsic state is rejected at
construction with typed errors rather than normalized into a different value
or accepted as a placeholder.

## Products

### `DatabaseTypes`

The core primitive library. It does not import Foundation and owns:

- canonical representation and intrinsic validation;
- exact equality, hashing, and deterministic structural ordering;
- immutable byte ownership and synchronous scoped borrowing;
- representation-preserving numeric, temporal, spatial, vector, identity, and
  RDF values.

### `DatabaseTypesFoundation`

An optional native adapter for explicit conversion between canonical values and
Foundation `Data`, `Date`, `Decimal`, `DateComponents`, and `UUID`.

Foundation never enters the `DatabaseTypes` target or its Embedded dependency
graph.

## Installation

```swift
dependencies: [
    .package(
        url: "https://github.com/1amageek/database-types.git",
        from: "26.0730.0"
    ),
]
```

Add the core product to a target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(
            name: "DatabaseTypes",
            package: "database-types"
        ),
    ]
)
```

Add `DatabaseTypesFoundation` only to native targets that need Foundation
conversion.

## Quick start

```swift
import DatabaseTypes

let createdOn = try CivilDate(
    year: 2026,
    month: 7,
    day: 24
)

let payload = ByteString([0x44, 0x42])
let amount = ExactDecimal(
    coefficient: 12_345,
    scale: 2
)

let object = try FieldObject([
    (key: "amount", value: .decimal(amount)),
    (key: "createdOn", value: .date(createdOn)),
    (key: "payload", value: .bytes(payload)),
])

let value = FieldValue.object(object)
```

`FieldObject` rejects duplicate keys and stores fields in canonical UTF-8
order. Input order therefore does not affect equality, hashing, or comparison.

## Representation guarantees

### Numeric identity

Numeric width is part of `FieldValue` identity. For example, `.int8(1)`,
`.int64(1)`, and `.uint64(1)` are different values. Floating-point identity
preserves the IEEE bit pattern. Numeric coercion is intentionally left to the
operation requesting it.

`ExactDecimal` stores:

```text
coefficient × 10^(-scale)
```

It removes redundant trailing decimal zeros and gives zero one canonical
representation. Arithmetic returns an exact representable value or a typed
failure; non-terminating division is not rounded silently.

### Temporal identity

The temporal types do not conflate calendar values with absolute time:

```text
CivilDate + CivilTime
          │
          ▼
 CivilDateTime ── explicit time-zone policy ──> Timestamp

 TimeSpan: fixed elapsed time
 CalendarPeriod: calendar-relative months and days
```

`Timestamp` is an absolute Unix-epoch value with nanosecond resolution.
`CivilDateTime` has no time zone and does not identify an instant until a
consumer applies an explicit time-zone and resolution policy.

### Byte ownership

`ByteString` stores one immutable owner and one visible range. Array, slice,
and external inputs are adapted to that single representation, and bounded
slices reuse it without copying payload bytes:

```text
retained owner
└── ByteString
    └── bounded ByteString slice
```

Every `ByteString`, including a slice, exposes collection indices as
`0..<count`. The retained owner's storage offset stays internal, so nested
slicing composes offsets without leaking a parent collection's index space.
This preserves the original FoundationDB byte-string contract used by storage
and wire codecs.

Use `withUnsafeBytes` for a synchronous borrow. The pointer must not escape the
closure. Its `rethrows` contract adds no failure path to nonthrowing work and
preserves the original failure for throwing work. The borrow does not
materialize the visible bytes. Its body is serialized for caller-side
specialization so imported standard-WASI consumers do not depend on runtime
construction of cross-module generic result metadata. Use
`detached()` when a small slice must stop retaining a larger backing owner.
`retainedByteCount` reports the complete retained allocation for resource
admission and can therefore be larger than a slice's visible `count`. It is
`nil` whenever the owner cannot measure that allocation accurately. Visible
`count` is never substituted for unknown retained memory. This includes direct
`ArraySlice` values and backend result owners that retain an opaque batch. For
an owned Swift `Array`, the reported value includes reserved element capacity,
not only initialized elements.

`Vector` follows the same ownership contract. A subvector keeps its original
numeric allocation, `retainedByteCount` includes reserved scalar capacity when
known, and
`detached()` creates an independently owned visible vector when releasing the
larger owner matters.

## Scope

This package defines primitive values only. It deliberately does not provide:

- schemas, queries, execution plans, or database runtime behavior;
- storage engines, transactions, indexes, or persistence policy;
- wire framing, serialization formats, transports, or protocol versions;
- model mapping, implicit numeric coercion, or implicit Foundation conversion.

Those concerns can consume these values without changing their canonical
identity.

## Requirements

| Use | Requirement |
|---|---|
| Package | Swift 6.4 or newer |
| Embedded | A Swift 6.4 or newer Wasm Embedded SDK built for the same toolchain version |
| Foundation adapter | macOS 15, iOS 18, tvOS 18, watchOS 11, or visionOS 2 |

## Verification

Run the native test suite with Xcode:

```bash
xcodebuild test \
  -scheme database-types-Package \
  -destination 'platform=macOS,arch=arm64'
```

Compile the core with a matching compiler and Embedded SDK:

```bash
swift build \
  --configuration release \
  --product DatabaseTypes \
  --swift-sdk <swift-6.4-or-newer_wasm-embedded>
```

## Documentation

See the
[Database Value Specification](Documentation/DatabaseValueSpecification.md)
for the complete value algebra, invariants, comparison rules, ownership
contracts, and conversion policy.
