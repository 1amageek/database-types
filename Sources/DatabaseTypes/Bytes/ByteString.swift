/// An immutable byte string with value semantics.
///
/// A byte string retains its backing owner and creates constant-time slices
/// without copying payload bytes. Use `detached()` only when the value must stop
/// retaining a larger backing owner.
public struct ByteString:
    Sendable,
    Hashable,
    Comparable,
    RandomAccessCollection,
    ExpressibleByArrayLiteral {
    public typealias Element = UInt8
    public typealias Index = Int
    public typealias SubSequence = ByteString
    public typealias ArrayLiteralElement = UInt8

    private let owner: any ByteStringOwner
    private let visibleRange: Range<Int>

    public init() {
        self.owner = ArrayByteStringOwner([])
        self.visibleRange = 0..<0
    }

    /// Retains the array's copy-on-write storage.
    public init(_ bytes: [UInt8]) {
        self.owner = ArrayByteStringOwner(bytes)
        self.visibleRange = 0..<bytes.count
    }

    /// Creates a byte string by allocating and filling its final storage once.
    public init(repeating byte: UInt8, count: Int) {
        self.init([UInt8](repeating: byte, count: count))
    }

    /// Retains the slice's copy-on-write storage without materializing bytes.
    public init(_ bytes: ArraySlice<UInt8>) {
        self.owner = ArraySliceByteStringOwner(bytes)
        self.visibleRange = 0..<bytes.count
    }

    /// Encodes a string directly into final UTF-8 byte storage.
    public init(utf8 string: String) {
        let utf8 = string.utf8
        self = ByteString.copying(count: utf8.count) { destination in
            var offset = 0
            for byte in utf8 {
                destination[offset] = byte
                offset += 1
            }
        }
    }

    /// Retains an immutable external owner without copying its bytes.
    public init<Owner: ByteStringOwner>(retaining owner: Owner) {
        precondition(owner.count >= 0)
        if let retainedByteCount = owner.retainedByteCount {
            precondition(retainedByteCount >= owner.count)
        }
        self.owner = owner
        self.visibleRange = 0..<owner.count
    }

    public init(arrayLiteral elements: UInt8...) {
        self.init(elements)
    }

    private init(
        owner: any ByteStringOwner,
        visibleRange: Range<Int>
    ) {
        precondition(
            visibleRange.lowerBound >= 0
                && visibleRange.upperBound <= owner.count
        )
        self.owner = owner
        self.visibleRange = visibleRange
    }

    /// Allocates the final byte string storage once.
    public static func copying(
        count: Int,
        _ initialize: (UnsafeMutableRawBufferPointer) -> Void
    ) -> ByteString {
        precondition(count >= 0)
        guard count > 0 else {
            return ByteString()
        }
        let bytes = [UInt8](unsafeUninitializedCapacity: count) {
            buffer,
            initializedCount in
            initialize(UnsafeMutableRawBufferPointer(buffer))
            initializedCount = count
        }
        return ByteString(bytes)
    }

    /// Allocates the final storage once while preserving a typed failure.
    public static func copying<Failure: Error>(
        count: Int,
        _ initialize: (
            UnsafeMutableRawBufferPointer
        ) throws(Failure) -> Void
    ) throws(Failure) -> ByteString {
        precondition(count >= 0)
        guard count > 0 else {
            return ByteString()
        }

        var initializationResult: Result<Void, Failure>?
        let bytes = [UInt8](unsafeUninitializedCapacity: count) {
            buffer,
            initializedCount in
            let result = Result<Void, Failure>(catching: {
                () throws(Failure) -> Void in
                try initialize(UnsafeMutableRawBufferPointer(buffer))
            })
            initializationResult = result
            switch result {
            case .success:
                initializedCount = count
            case .failure:
                initializedCount = 0
            }
        }
        guard let initializationResult else {
            preconditionFailure(
                "Byte string storage did not invoke its initializer"
            )
        }
        switch initializationResult {
        case .success:
            return ByteString(bytes)
        case .failure(let failure):
            throw failure
        }
    }

    public var startIndex: Int { visibleRange.lowerBound }
    public var endIndex: Int { visibleRange.upperBound }

    /// The byte count retained by this value's backing owner, when known.
    ///
    /// A bounded slice can expose fewer bytes through `count` while retaining
    /// the complete owner. Execution layers use this value when admitting
    /// retained memory before preserving the slice. The value is `nil` when an
    /// owner cannot measure the complete allocation accurately. The visible
    /// byte count is never substituted for unknown retained memory.
    public var retainedByteCount: Int? {
        guard let retainedByteCount = owner.retainedByteCount else {
            return nil
        }
        precondition(retainedByteCount >= owner.count)
        return retainedByteCount
    }

    public subscript(position: Int) -> UInt8 {
        precondition(indices.contains(position))
        return withUnsafeBytes { bytes in
            bytes[position - startIndex]
        }
    }

    public subscript(bounds: Range<Int>) -> ByteString {
        precondition(
            bounds.lowerBound >= startIndex
                && bounds.upperBound <= endIndex
        )
        return ByteString(
            owner: owner,
            visibleRange: bounds
        )
    }

    /// Exposes contiguous storage for one synchronous borrow.
    ///
    /// The pointer must not escape `body`.
    public func withUnsafeBytes<Result>(
        _ body: (UnsafeRawBufferPointer) throws -> Result
    ) rethrows -> Result {
        var outcome: ByteStringBorrowOutcome<Result> = .missing
        try owner.borrowBytes { source in
            Self.validate(source, for: owner)
            guard case .missing = outcome else {
                preconditionFailure(
                    "ByteStringOwner invoked its borrow closure more than once"
                )
            }
            outcome = .value(try body(
                UnsafeRawBufferPointer(rebasing: source[visibleRange])
            ))
        }
        switch outcome {
        case .missing:
            preconditionFailure(
                "ByteStringOwner did not invoke its borrow closure"
            )
        case .value(let result):
            return result
        }
    }

    /// Exposes the byte string to generic contiguous collection algorithms.
    public func withContiguousStorageIfAvailable<Result>(
        _ body: (UnsafeBufferPointer<UInt8>) throws -> Result
    ) rethrows -> Result? {
        try withUnsafeBytes { bytes in
            try body(bytes.bindMemory(to: UInt8.self))
        }
    }

    /// Materializes an independent array for array-only APIs.
    public func copyBytes() -> [UInt8] {
        withUnsafeBytes { bytes in
            Array(bytes)
        }
    }

    /// Stops retaining a larger backing owner or an enclosing byte string.
    public func detached() -> ByteString {
        guard !isEmpty else {
            return ByteString()
        }
        if visibleRange == 0..<owner.count {
            if owner is ArrayByteStringOwner
                || owner.retainedByteCount == count {
                return self
            }
        }
        return ByteString.copying(count: count) { destination in
            withUnsafeBytes { source in
                destination.copyMemory(from: source)
            }
        }
    }

    /// Returns a byte string with one byte appended using one final allocation.
    public func appending(_ byte: UInt8) -> ByteString {
        let (resultCount, overflow) = count.addingReportingOverflow(1)
        precondition(!overflow, "ByteString size overflow")
        return ByteString.copying(count: resultCount) { destination in
            withUnsafeBytes { source in
                UnsafeMutableRawBufferPointer(
                    rebasing: destination[..<source.count]
                ).copyMemory(from: source)
            }
            destination[count] = byte
        }
    }

    /// Returns the concatenation using one final allocation.
    public func appending(contentsOf suffix: ByteString) -> ByteString {
        guard !suffix.isEmpty else { return self }
        guard !isEmpty else { return suffix }
        let (resultCount, overflow) = count.addingReportingOverflow(
            suffix.count
        )
        precondition(!overflow, "ByteString size overflow")
        return ByteString.copying(count: resultCount) { destination in
            withUnsafeBytes { source in
                UnsafeMutableRawBufferPointer(
                    rebasing: destination[..<source.count]
                ).copyMemory(from: source)
            }
            suffix.withUnsafeBytes { source in
                UnsafeMutableRawBufferPointer(
                    rebasing: destination[count..<resultCount]
                ).copyMemory(from: source)
            }
        }
    }

    public static func == (
        lhs: ByteString,
        rhs: ByteString
    ) -> Bool {
        guard lhs.count == rhs.count else {
            return false
        }
        return lhs.withUnsafeBytes { left in
            rhs.withUnsafeBytes { right in
                left.elementsEqual(right)
            }
        }
    }

    public static func < (
        lhs: ByteString,
        rhs: ByteString
    ) -> Bool {
        lhs.withUnsafeBytes { left in
            rhs.withUnsafeBytes { right in
                let sharedCount = Swift.min(left.count, right.count)
                for offset in 0..<sharedCount {
                    if left[offset] != right[offset] {
                        return left[offset] < right[offset]
                    }
                }
                return left.count < right.count
            }
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(count)
        withUnsafeBytes { bytes in
            for byte in bytes {
                hasher.combine(byte)
            }
        }
    }

    private static func validate(
        _ bytes: UnsafeRawBufferPointer,
        for owner: any ByteStringOwner
    ) {
        precondition(
            bytes.count == owner.count,
            "ByteStringOwner returned an inconsistent byte count"
        )
        precondition(
            bytes.isEmpty || bytes.baseAddress != nil,
            "ByteStringOwner returned no address for nonempty bytes"
        )
    }
}

private enum ByteStringBorrowOutcome<Value> {
    case missing
    case value(Value)
}

private struct ArrayByteStringOwner: ByteStringOwner {
    let bytes: [UInt8]

    init(_ bytes: [UInt8]) {
        self.bytes = bytes
    }

    var count: Int { bytes.count }
    var retainedByteCount: Int? { bytes.capacity }

    func borrowBytes(
        _ body: (UnsafeRawBufferPointer) throws -> Void
    ) rethrows {
        try bytes.withUnsafeBytes(body)
    }
}

private struct ArraySliceByteStringOwner: ByteStringOwner {
    let bytes: ArraySlice<UInt8>

    init(_ bytes: ArraySlice<UInt8>) {
        self.bytes = bytes
    }

    var count: Int { bytes.count }

    func borrowBytes(
        _ body: (UnsafeRawBufferPointer) throws -> Void
    ) rethrows {
        try bytes.withUnsafeBytes(body)
    }
}
