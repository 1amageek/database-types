# Database Types Package Instructions

## Responsibility

`DatabaseTypes` owns Foundation-independent value types that cross database
client, runtime, and storage package boundaries.

It does not own transport, wire framing, query execution, storage engines,
macros, or platform adapters.

## Naming

- Name declarations for their represented value, observable behavior,
  ownership, or lifecycle contract.
- Do not prefix declarations with `Database` merely because they belong to this
  package.
- Do not encode implementation language, ABI, binary format, toolchain,
  calling convention, or memory-layout strategy in declaration names.
- Use `Database` only when it is part of the declaration's actual semantic
  responsibility and removing it would change the meaning.
- Follow the Swift API Design Guidelines at every access level, including tests
  and host-boundary support declarations.
- Externally fixed symbol spellings belong only in ABI attributes or protocol
  constants.

## Runtime contract

- Keep the core target Foundation-independent and compatible with Swift
  Embedded.
- Preserve typed failures. Do not use silent fallback.
- Use immutable ownership and scoped borrows for performance-sensitive byte
  paths.
- Do not materialize `Array`, `Data`, or `String` values inside byte paths
  unless an explicit output or platform boundary requires it.
- Pointer values must not escape their synchronous borrow.

## Changes

- Do not add a type merely because a database package uses it. A type belongs
  here only when it is a runtime-independent value crossing package boundaries.
- Do not provide compatibility aliases for replaced names during initial
  development.
