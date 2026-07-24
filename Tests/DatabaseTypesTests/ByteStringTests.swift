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
    }

    @Test("External owners are borrowed without copying")
    func externalOwnerIsBorrowed() throws {
        let owner = TestByteStringOwner(
            bytes: [0x10, 0x20, 0x30, 0x40]
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
    }

    @Test("Detaching a slice releases its larger owner")
    func detachedSliceReleasesOwner() throws {
        let releaseProbe = ReleaseProbe()
        var owner: TestByteStringOwner? = TestByteStringOwner(
            bytes: [0x10, 0x20, 0x30, 0x40],
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
        owner = nil
        value = nil
        #expect(releaseProbe.count == 0)
        slice = nil
        #expect(releaseProbe.count == 1)
        #expect(detached == [0x20, 0x30])
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

    @Test("Ordering is lexicographic")
    func orderingIsLexicographic() {
        #expect(ByteString([0x00, 0xFF]) < ByteString([0x01]))
        #expect(ByteString([0x01]) < ByteString([0x01, 0x00]))
        #expect(!(ByteString([0x01]) < ByteString([0x01])))
    }
}

private enum ByteStringTestError: Error {
    case initializationFailed
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
    let releaseProbe: ReleaseProbe?

    init(
        bytes: [UInt8],
        releaseProbe: ReleaseProbe? = nil
    ) {
        self.bytes = bytes
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
