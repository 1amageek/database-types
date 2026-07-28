import DatabaseTypes
import Synchronization
import Testing

@Suite("ByteString")
struct ByteStringTests {
    @Test("Array initialization shares copy-on-write storage")
    func arrayInitializationSharesStorage() throws {
        var source: [UInt8] = [0x10, 0x20, 0x30, 0x40]
        let sourceAddress = try #require(
            source.withUnsafeBytes { bytes in
                bytes.baseAddress.map(UInt.init(bitPattern:))
            }
        )

        let value = ByteString(source)
        let valueAddress = try #require(
            value.withUnsafeBytes { bytes in
                bytes.baseAddress.map(UInt.init(bitPattern:))
            }
        )

        #expect(valueAddress == sourceAddress)
        source[0] = 0xFF
        #expect(value[0] == 0x10)
    }

    @Test("Repeating initialization fills the requested byte count")
    func repeatingInitialization() {
        #expect(ByteString(repeating: 0xA5, count: 4) == [0xA5, 0xA5, 0xA5, 0xA5])
        #expect(ByteString(repeating: 0xA5, count: 0).isEmpty)
    }

    @Test("ArraySlice initialization retains visible storage without copying")
    func arraySliceInitializationSharesStorage() throws {
        var source: [UInt8] = [0x10, 0x20, 0x30, 0x40, 0x50]
        let sourceSlice = source[1..<4]
        let sourceAddress = try #require(
            sourceSlice.withUnsafeBytes { bytes in
                bytes.baseAddress.map(UInt.init(bitPattern:))
            }
        )

        let value = ByteString(sourceSlice)
        let valueAddress = try #require(
            value.withUnsafeBytes { bytes in
                bytes.baseAddress.map(UInt.init(bitPattern:))
            }
        )

        #expect(valueAddress == sourceAddress)
        #expect(value == [0x20, 0x30, 0x40])
        #expect(value.retainedByteCount == nil)

        source[1] = 0xFF
        #expect(value[0] == 0x20)

        let detached = value.detached()
        let detachedAddress = try #require(
            detached.withUnsafeBytes { bytes in
                bytes.baseAddress.map(UInt.init(bitPattern:))
            }
        )
        #expect(detachedAddress != valueAddress)
        #expect(detached == value)
        #expect(detached.retainedByteCount == 3)
    }

    @Test("Slices retain the same backing storage")
    func slicesShareStorage() throws {
        let value: ByteString = [0x10, 0x20, 0x30, 0x40]
        let slice = value[1..<3]
        let valueAddress = try #require(
            value.withUnsafeBytes { bytes in
                bytes.baseAddress.map(UInt.init(bitPattern:))
            }
        )
        let sliceAddress = try #require(
            slice.withUnsafeBytes { bytes in
                bytes.baseAddress.map(UInt.init(bitPattern:))
            }
        )

        #expect(sliceAddress == valueAddress + 1)
        #expect(slice == [0x20, 0x30])
        #expect(value.retainedByteCount == 4)
        #expect(slice.retainedByteCount == 4)
    }

    @Test("External owners are borrowed without copying")
    func externalOwnerIsBorrowed() throws {
        let owner = TestByteStringOwner(
            bytes: [0x10, 0x20, 0x30, 0x40],
            retainedByteCount: 4
        )
        let value = ByteString(retaining: owner)
        let ownerAddress = try #require(
            owner.byteAddress
        )
        let valueAddress = try #require(
            value.withUnsafeBytes { bytes in
                bytes.baseAddress.map(UInt.init(bitPattern:))
            }
        )

        #expect(valueAddress == ownerAddress)
        #expect(value == [0x10, 0x20, 0x30, 0x40])
        #expect(value.retainedByteCount == owner.count)
    }

    @Test("Detaching a slice releases its larger owner")
    func detachedSliceReleasesOwner() throws {
        let releaseProbe = ReleaseProbe()
        var owner: TestByteStringOwner? = TestByteStringOwner(
            bytes: [0x10, 0x20, 0x30, 0x40],
            retainedByteCount: 4,
            releaseProbe: releaseProbe
        )
        var value: ByteString? = ByteString(retaining: owner!)
        var slice: ByteString? = value?[1..<3]
        let detached = try #require(slice?.detached())
        let sliceAddress = try #require(
            slice?.withUnsafeBytes { bytes in
                bytes.baseAddress.map(UInt.init(bitPattern:))
            }
        )
        let detachedAddress = try #require(
            detached.withUnsafeBytes { bytes in
                bytes.baseAddress.map(UInt.init(bitPattern:))
            }
        )

        #expect(sliceAddress != detachedAddress)
        #expect(slice?.retainedByteCount == 4)
        #expect(detached.retainedByteCount == 2)
        owner = nil
        value = nil
        #expect(releaseProbe.count == 0)
        slice = nil
        #expect(releaseProbe.count == 1)
        #expect(detached == [0x20, 0x30])
    }

    @Test("External owners distinguish visible bytes from retained memory")
    func externalOwnerRetainedMemoryAccounting() {
        let unknownOwner = TestByteStringOwner(
            bytes: [0x10, 0x20],
            retainedByteCount: nil
        )
        let largerOwner = TestByteStringOwner(
            bytes: [0x10, 0x20],
            retainedByteCount: 4_096
        )

        let unknown = ByteString(retaining: unknownOwner)
        let larger = ByteString(retaining: largerOwner)

        #expect(unknown.count == 2)
        #expect(unknown.retainedByteCount == nil)
        #expect(unknown.detached().retainedByteCount == 2)
        #expect(larger.count == 2)
        #expect(larger.retainedByteCount == 4_096)
        #expect(larger.detached().retainedByteCount == 2)
    }

    @Test("Hash collections preserve distinct owner-backed values")
    func hashCollectionBehavior() {
        let first = ByteString(retaining: TestByteStringOwner(
            bytes: [0x10, 0x20],
            retainedByteCount: 2
        ))
        let second = ByteString(retaining: TestByteStringOwner(
            bytes: [0x30, 0x40],
            retainedByteCount: 2
        ))

        #expect(Set([first, second]).count == 2)
        #expect(Set([first, first]).count == 1)
        #expect(Dictionary(uniqueKeysWithValues: [
            (first, 1),
            (second, 2),
        ])[second] == 2)
    }

    @Test("Exact-size initialization preserves typed failures")
    func exactSizeInitializationPreservesFailures() {
        #expect(throws: ByteStringTestError.initializationFailed) {
            _ = try ByteString.copying(count: 4) {
                (_: UnsafeMutableRawBufferPointer)
                    throws(ByteStringTestError) in
                throw .initializationFailed
            }
        }
    }

    @Test("Throwing borrows preserve failures")
    func borrowingPreservesFailures() {
        let value: ByteString = [0x10, 0x20]
        #expect(throws: ByteStringTestError.borrowFailed) {
            _ = try value.withUnsafeBytes { _ in
                throw ByteStringTestError.borrowFailed
            }
        }
    }

    @Test("Appending a byte preserves the source and adds a suffix")
    func appendingByteAddsSuffix() {
        let source: ByteString = [0x10, 0x20]

        let result = source.appending(0x30)

        #expect(source == [0x10, 0x20])
        #expect(result == [0x10, 0x20, 0x30])
    }

    @Test("UTF-8 initialization writes canonical bytes")
    func utf8InitializationWritesCanonicalBytes() {
        #expect(ByteString(utf8: "Aé") == [0x41, 0xC3, 0xA9])
    }

    @Test("Appending bytes preserves order and empty identity")
    func appendingBytesPreservesOrder() {
        let source: ByteString = [0x10, 0x20]
        let suffix: ByteString = [0x30, 0x40]

        #expect(source.appending(contentsOf: suffix) == [0x10, 0x20, 0x30, 0x40])
        #expect(source.appending(contentsOf: ByteString()) == source)
        #expect(ByteString().appending(contentsOf: suffix) == suffix)
    }

    @Test("Ordering is lexicographic")
    func orderingIsLexicographic() {
        #expect(ByteString([0x00, 0xFF]) < ByteString([0x01]))
        #expect(ByteString([0x01]) < ByteString([0x01, 0x00]))
        #expect(!(ByteString([0x01]) < ByteString([0x01])))
    }

    @Test("Slices keep the parent index space so shared indices stay valid")
    func slicesKeepParentIndexSpace() throws {
        let value: ByteString = [0x00, 0x01, 0x02, 0x03, 0x04]
        let slice = value[2..<4]

        // A SubSequence must share indices with its base.
        #expect(slice.startIndex == 2)
        #expect(slice.endIndex == 4)
        #expect(slice[2] == 0x02)
        #expect(slice[3] == 0x03)

        // An index found on the base reads the same element on the slice.
        let indexOfTwo = try #require(value.firstIndex(of: 0x02))
        #expect(indexOfTwo == 2)
        #expect(slice[indexOfTwo] == 0x02)

        // Dropping a prefix does not rebase the remaining indices.
        let dropped = value.dropFirst(3)
        #expect(dropped.startIndex == 3)
        let indexOfThree = try #require(dropped.firstIndex(of: 0x03))
        #expect(indexOfThree == 3)
        #expect(value[indexOfThree] == 0x03)

        // Slicing a slice keeps composing into the original index space.
        let nested = slice[3..<4]
        #expect(nested.startIndex == 3)
        #expect(nested[3] == 0x03)
        #expect(nested == [0x03])
    }
}

private enum ByteStringTestError: Error {
    case initializationFailed
    case borrowFailed
}

private final class ReleaseProbe: Sendable {
    private let state = Mutex(0)

    var count: Int {
        state.withLock { $0 }
    }

    func recordRelease() {
        state.withLock { $0 += 1 }
    }
}

private final class TestByteStringOwner: ByteStringOwner {
    let bytes: [UInt8]
    let retainedByteCount: Int?
    let releaseProbe: ReleaseProbe?

    init(
        bytes: [UInt8],
        retainedByteCount: Int?,
        releaseProbe: ReleaseProbe? = nil
    ) {
        self.bytes = bytes
        self.retainedByteCount = retainedByteCount
        self.releaseProbe = releaseProbe
    }

    deinit {
        releaseProbe?.recordRelease()
    }

    var count: Int { bytes.count }

    var byteAddress: UInt? {
        bytes.withUnsafeBytes { buffer in
            buffer.baseAddress.map(UInt.init(bitPattern:))
        }
    }

    func borrowBytes(
        _ body: (UnsafeRawBufferPointer) throws -> Void
    ) rethrows {
        try bytes.withUnsafeBytes(body)
    }
}
