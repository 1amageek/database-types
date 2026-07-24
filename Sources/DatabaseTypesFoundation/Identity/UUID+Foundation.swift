import DatabaseTypes
#if canImport(FoundationEssentials)
import FoundationEssentials

public extension DatabaseTypes.UUID {
    /// Creates the Foundation-independent representation of a Foundation UUID.
    init(_ value: FoundationEssentials.UUID) {
        let components = withUnsafeBytes(of: value.uuid) { bytes in
            var high: UInt64 = 0
            var low: UInt64 = 0
            for offset in 0..<16 {
                if offset < 8 {
                    high = (high << 8) | UInt64(bytes[offset])
                } else {
                    low = (low << 8) | UInt64(bytes[offset])
                }
            }
            return (high, low)
        }
        self.init(high: components.0, low: components.1)
    }
}

public extension FoundationEssentials.UUID {
    /// Creates a Foundation UUID from its canonical database representation.
    init(_ value: DatabaseTypes.UUID) {
        self.init(uuid: (
            value[0], value[1], value[2], value[3],
            value[4], value[5], value[6], value[7],
            value[8], value[9], value[10], value[11],
            value[12], value[13], value[14], value[15]
        ))
    }
}
#else
import Foundation

public extension DatabaseTypes.UUID {
    /// Creates the Foundation-independent representation of a Foundation UUID.
    init(_ value: Foundation.UUID) {
        let components = withUnsafeBytes(of: value.uuid) { bytes in
            var high: UInt64 = 0
            var low: UInt64 = 0
            for offset in 0..<16 {
                if offset < 8 {
                    high = (high << 8) | UInt64(bytes[offset])
                } else {
                    low = (low << 8) | UInt64(bytes[offset])
                }
            }
            return (high, low)
        }
        self.init(high: components.0, low: components.1)
    }
}

public extension Foundation.UUID {
    /// Creates a Foundation UUID from its canonical database representation.
    init(_ value: DatabaseTypes.UUID) {
        self.init(uuid: (
            value[0], value[1], value[2], value[3],
            value[4], value[5], value[6], value[7],
            value[8], value[9], value[10], value[11],
            value[12], value[13], value[14], value[15]
        ))
    }
}
#endif
