/// Owns stable, immutable, contiguous bytes.
///
/// Every borrow must expose the same byte count and contents for the complete
/// lifetime of the owner. `count` and `retainedByteCount` must also remain
/// stable. Borrows may overlap or nest. Implementations must not hold a
/// non-recursive lock while invoking `body`.
public protocol ByteStringOwner: Sendable {
    /// The complete contiguous byte region exposed by every borrow.
    var count: Int { get }

    /// The total backing byte-storage allocation kept alive by this owner, when
    /// measurable.
    ///
    /// This can be greater than `count` when the exposed bytes are a view into a
    /// larger result or allocation. Return `nil` when the retained allocation
    /// cannot be measured accurately; the visible byte count is not a valid
    /// substitute.
    var retainedByteCount: Int? { get }

    /// Whether the exposed byte region is already backed by self-contained
    /// storage.
    ///
    /// Return `true` only when copying the complete exposed region cannot
    /// release an enclosing owner or unrelated retained allocation. This lets
    /// `ByteString.detached()` preserve already-detached storage without a
    /// runtime type check.
    var isStorageSelfContained: Bool { get }

    /// Exposes the owned bytes for the duration of one synchronous borrow.
    ///
    /// The implementation must invoke `body` exactly once. The pointer must not
    /// escape `body`.
    func borrowBytes(
        _ body: (UnsafeRawBufferPointer) throws -> Void
    ) rethrows
}

public extension ByteStringOwner {
    var retainedByteCount: Int? { nil }

    var isStorageSelfContained: Bool {
        retainedByteCount == count
    }
}
