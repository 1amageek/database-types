/// The canonical identifier component of an entity reference.
///
/// A scalar identifier remains distinct from a one-component composite
/// identifier. Encoding and storage-key policy belong to upper layers.
public indirect enum ReferenceIdentifier: Sendable {
    case bool(Bool)
    case int8(Int8)
    case int16(Int16)
    case int32(Int32)
    case int64(Int64)
    case uint8(UInt8)
    case uint16(UInt16)
    case uint32(UInt32)
    case uint64(UInt64)
    case string(String)
    case bytes(ByteString)
    case uuid(UUID)
    case composite([ReferenceIdentifier])

}
