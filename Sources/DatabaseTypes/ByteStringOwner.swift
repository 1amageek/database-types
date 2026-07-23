/// Owns stable, immutable, contiguous bytes.
///
/// Every borrow must expose the same byte count and contents for the complete
/// lifetime of the owner. Borrows may overlap or nest. Implementations must not
/// hold a non-recursive lock while invoking `body`.
public protocol ByteStringOwner: Sendable {
    var count: Int { get }

    /// Exposes the owned bytes for the duration of one synchronous borrow.
    ///
    /// The implementation must invoke `body` exactly once. The pointer must not
    /// escape `body`.
    func borrowBytes(
        _ body: (UnsafeRawBufferPointer) throws -> Void
    ) rethrows
}
