import DatabaseTypes
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Keeps immutable Foundation data alive while a byte string borrows it.
final class RetainedDataByteStringOwner: ByteStringOwner, Sendable {
    let data: Data

    init(data: Data) {
        self.data = data
    }

    var count: Int {
        data.count
    }

    func borrowBytes(
        _ body: (UnsafeRawBufferPointer) throws -> Void
    ) rethrows {
        try data.withUnsafeBytes(body)
    }
}
