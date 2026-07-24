import DatabaseTypes
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

public extension ByteString {
    /// Retains Foundation data and borrows its immutable bytes without copying.
    init(retaining data: Data) {
        self.init(retaining: RetainedDataByteStringOwner(data: data))
    }
}

public extension Data {
    /// Copies a byte string into independently owned Foundation data.
    ///
    /// A copy is required because `Data` cannot retain an arbitrary
    /// `ByteStringOwner` through its public value-semantic API.
    init(copying bytes: ByteString) {
        self = bytes.withUnsafeBytes { source in
            Data(source)
        }
    }
}
