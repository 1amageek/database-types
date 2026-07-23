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

    private enum Storage: Sendable {
        case array([UInt8])
        case owner(any ByteStringOwner)
    }

    private let storage: Storage
    private let storageRange: Range<Int>

    public init() {
        self.storage = .array([])
        self.storageRange = 0..<0
    }

    /// Retains the array's copy-on-write storage.
    public init(_ bytes: [UInt8]) {
        self.storage = .array(bytes)
        self.storageRange = 0..<bytes.count
    }

    /// Retains an immutable external owner without copying its bytes.
    public init(retaining owner: any ByteStringOwner) {
        precondition(owner.count >= 0)
        self.storage = .owner(owner)
        self.storageRange = 0..<owner.count
    }

    public init(arrayLiteral elements: UInt8...) {
        self.init(elements)
    }

    private init(
        storage: Storage,
        storageRange: Range<Int>
    ) {
        self.storage = storage
        self.storageRange = storageRange
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

        var initializationFailure: Failure?
        let bytes = [UInt8](unsafeUninitializedCapacity: count) {
            buffer,
            initializedCount in
            do {
                try initialize(UnsafeMutableRawBufferPointer(buffer))
                initializedCount = count
            } catch let failure as Failure {
                initializationFailure = failure
                initializedCount = 0
            } catch {
                preconditionFailure(
                    "Byte string initialization threw an unexpected error type"
                )
            }
        }
        if let initializationFailure {
            throw initializationFailure
        }
        return ByteString(bytes)
    }

    public var startIndex: Int { 0 }
    public var endIndex: Int { storageRange.count }

    public subscript(position: Int) -> UInt8 {
        precondition(indices.contains(position))
        return withUnsafeBytes { bytes in
            bytes[position]
        }
    }

    public subscript(bounds: Range<Int>) -> ByteString {
        precondition(
            bounds.lowerBound >= startIndex
                && bounds.upperBound <= endIndex
        )
        return ByteString(
            storage: storage,
            storageRange: (storageRange.lowerBound + bounds.lowerBound)..<(
                storageRange.lowerBound + bounds.upperBound
            )
        )
    }

    /// Exposes contiguous storage for one synchronous borrow.
    ///
    /// The pointer must not escape `body`.
    public func withUnsafeBytes<Result>(
        _ body: (UnsafeRawBufferPointer) throws -> Result
    ) rethrows -> Result {
        switch storage {
        case .array(let bytes):
            return try bytes.withUnsafeBytes { source in
                try body(
                    UnsafeRawBufferPointer(
                        rebasing: source[storageRange]
                    )
                )
            }
        case .owner(let owner):
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
                            rebasing: source[storageRange]
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
        if case .array(let bytes) = storage,
           storageRange == bytes.indices {
            return self
        }
        return ByteString.copying(count: count) { destination in
            withUnsafeBytes { source in
                destination.copyMemory(from: source)
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
}

private enum ByteStringBorrowOutcome<Value> {
    case missing
    case value(Value)
}
