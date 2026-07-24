# Database Types Package Instructions

## Responsibility

`DatabaseTypes` owns only Foundation-independent primitive value
representations at the bottom of the database stack.

It owns:

- immutable byte ownership and bounded byte views;
- scalar representations whose complete meaning is their value and intrinsic
  invariants;
- the closed primitive field-value algebra and only the atomic value components
  strictly required to represent it;
- comparison, hashing, intrinsic validation, and scoped borrowing required by
  those primitive representations.

It does not own:

- query, schema, operation, capability, command, job, or maintenance types;
- request, response, envelope, wire codec, framing, or decode-budget types;
- model adaptation, persistence policy, macros, or migrations;
- database execution, graph algorithms, indexes, relationships, or runtime
  services;
- storage transactions, selectors, ranges, conflicts, or backend adapters;
- client transport, retry, authentication, timeout, or correlation state;
- Foundation, Codable, URLSession, JavaScript, C ABI, WASI, or Cloudflare
  adapters.

Cross-package use is not evidence that a declaration belongs here.

## Primitive Admission Gate

Before adding or moving a declaration, every answer must be yes:

1. Is it a primitive value representation rather than a DTO, descriptor,
   operation, service, or policy?
2. Can it be fully defined without query, schema, wire, client, runtime,
   storage, or backend concepts?
3. Can it be used without injected services or runtime context?
4. Will it change only when the represented primitive or its intrinsic
   invariants change?
5. Is no upper layer the semantic owner?

If any answer is no, place the declaration in its semantic owner. Do not widen
this package to reduce imports or dependencies.

A supporting API such as an external byte owner may be public only when it is
strictly required to construct or borrow a primitive without violating
ownership.

## Naming

- Name declarations for their represented primitive, observable behavior,
  ownership, or lifecycle contract.
- Do not prefix declarations with `Database` merely because they belong to this
  package.
- Do not encode implementation language, ABI, binary format, toolchain,
  calling convention, or memory-layout strategy in declaration names.
- Follow the Swift API Design Guidelines at every access level, including tests
  and host-boundary support declarations.

## Runtime Contract

- Keep the core target Foundation-independent and compatible with Swift
  Embedded.
- Preserve typed failures. Do not use silent fallback.
- Use immutable ownership and scoped borrows for performance-sensitive byte
  paths.
- Do not materialize `Array`, `Data`, or `String` values inside byte paths
  unless an explicit output or platform boundary requires it.
- Pointer values must not escape their synchronous borrow.
- Do not provide compatibility aliases or duplicate models during initial
  development.
