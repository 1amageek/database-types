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

    private enum Backing: Sendable {
        case retainedArray([UInt8])
        case retainedSlice(ArraySlice<UInt8>)
        case externalOwner(any ByteStringOwner)
    }

    private let backing: Backing
    private let visibleRange: Range<Int>
    /// The logical index of the first visible byte. Slices keep the parent's
    /// index space so that `SubSequence` indices remain valid in the parent,
    /// as `Collection` requires.
    private let indexBase: Int

    public init() {
        self.backing = .retainedArray([])
        self.visibleRange = 0..<0
        self.indexBase = 0
    }

    /// Retains the array's copy-on-write storage.
    public init(_ bytes: [UInt8]) {
        self.backing = .retainedArray(bytes)
        self.visibleRange = 0..<bytes.count
        self.indexBase = 0
    }

    /// Retains the slice's copy-on-write storage without materializing bytes.
    public init(_ bytes: ArraySlice<UInt8>) {
        self.backing = .retainedSlice(bytes)
        self.visibleRange = 0..<bytes.count
        self.indexBase = 0
    }

    /// Retains an immutable external owner without copying its bytes.
    public init(retaining owner: any ByteStringOwner) {
        precondition(owner.count >= 0)
        self.backing = .externalOwner(owner)
        self.visibleRange = 0..<owner.count
        self.indexBase = 0
    }

    public init(arrayLiteral elements: UInt8...) {
        self.init(elements)
    }

    private init(
        backing: Backing,
        visibleRange: Range<Int>,
        indexBase: Int
    ) {
        self.backing = backing
        self.visibleRange = visibleRange
        self.indexBase = indexBase
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

    public var startIndex: Int { indexBase }
    public var endIndex: Int { indexBase + visibleRange.count }

    /// The byte count retained by this value's backing owner, when known.
    ///
    /// A bounded slice can expose fewer bytes through `count` while retaining
    /// the complete owner. Execution layers use this value when admitting
    /// retained memory before preserving the slice. An `ArraySlice` does not
    /// expose the allocation that it retains, so values initialized directly
    /// from one return `nil` until they are detached.
    public var retainedByteCount: Int? {
        switch backing {
        case .retainedArray(let bytes):
            return bytes.count
        case .retainedSlice:
            return nil
        case .externalOwner(let owner):
            return owner.count
        }
    }

    public subscript(position: Int) -> UInt8 {
        precondition(indices.contains(position))
        return withUnsafeBytes { bytes in
            bytes[position - indexBase]
        }
    }

    public subscript(bounds: Range<Int>) -> ByteString {
        precondition(
            bounds.lowerBound >= startIndex
                && bounds.upperBound <= endIndex
        )
        let lower = visibleRange.lowerBound + (bounds.lowerBound - indexBase)
        let upper = visibleRange.lowerBound + (bounds.upperBound - indexBase)
        return ByteString(
            backing: backing,
            visibleRange: lower..<upper,
            indexBase: bounds.lowerBound
        )
    }

    /// Exposes contiguous storage for one synchronous borrow.
    ///
    /// The pointer must not escape `body`.
    public func withUnsafeBytes<Result>(
        _ body: (UnsafeRawBufferPointer) -> Result
    ) -> Result {
        switch backing {
        case .retainedArray(let bytes):
            return bytes.withUnsafeBytes { source in
                body(
                    UnsafeRawBufferPointer(
                        rebasing: source[visibleRange]
                    )
                )
            }
        case .retainedSlice(let bytes):
            return bytes.withUnsafeBytes { source in
                body(
                    UnsafeRawBufferPointer(
                        rebasing: source[visibleRange]
                    )
                )
            }
        case .externalOwner(let owner):
            var outcome: ByteStringBorrowOutcome<Result> = .missing
            owner.borrowBytes { source in
                precondition(source.count == owner.count)
                precondition(source.isEmpty || source.baseAddress != nil)
                guard case .missing = outcome else {
                    preconditionFailure(
                        "ByteStringOwner invoked its borrow closure more than once"
                    )
                }
                outcome = .value(
                    body(
                        UnsafeRawBufferPointer(
                            rebasing: source[visibleRange]
                        )
                    )
                )
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
    }

    /// Exposes contiguous storage to a throwing synchronous borrow.
    ///
    /// The pointer must not escape `body`.
    public func withUnsafeBytes<Result>(
        _ body: (UnsafeRawBufferPointer) throws -> Result
    ) rethrows -> Result {
        switch backing {
        case .retainedArray(let bytes):
            return try bytes.withUnsafeBytes { source in
                try body(
                    UnsafeRawBufferPointer(
                        rebasing: source[visibleRange]
                    )
                )
            }
        case .retainedSlice(let bytes):
            return try bytes.withUnsafeBytes { source in
                try body(
                    UnsafeRawBufferPointer(
                        rebasing: source[visibleRange]
                    )
                )
            }
        case .externalOwner(let owner):
            var outcome: ByteStringBorrowOutcome<Result> = .missing
            try owner.borrowBytes { source in
                precondition(source.count == owner.count)
                precondition(source.isEmpty || source.baseAddress != nil)
                guard case .missing = outcome else {
                    preconditionFailure(
                        "ByteStringOwner invoked its borrow closure more than once"
                    )
                }
                outcome = .value(
                    try body(
                        UnsafeRawBufferPointer(
                            rebasing: source[visibleRange]
                        )
                    )
                )
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
        if case .retainedArray(let bytes) = backing,
           visibleRange == bytes.indices {
            return self
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
}

private enum ByteStringBorrowOutcome<Value> {
    case missing
    case value(Value)
}
