/// A closed algebra of values that a field can contain.
///
/// The enum preserves the declared numeric width and representation. Numeric
/// coercion belongs to the consumer performing that operation and does not
/// change value identity, hashing, or ordering.
///
/// Equality, hashing, and ordering walk `array` and `object` children
/// iteratively, so their call-stack use stays constant regardless of the
/// value's structural depth and they cannot overflow the stack. Constructing
/// and releasing a value is still inherently recursive in the language runtime,
/// so bounding depth remains a decode-time responsibility of the upper layer
/// that materializes untrusted input: this primitive layer does not own a
/// decode depth budget and assumes the values it receives are already
/// depth-bounded.
public indirect enum FieldValue: Sendable {
    case null
    case bool(Bool)
    case int8(Int8)
    case int16(Int16)
    case int32(Int32)
    case int64(Int64)
    case uint8(UInt8)
    case uint16(UInt16)
    case uint32(UInt32)
    case uint64(UInt64)
    case float32(Float)
    case float64(Double)
    case decimal(ExactDecimal)
    case string(String)
    case bytes(ByteString)
    case date(CivilDate)
    case time(CivilTime)
    case dateTime(CivilDateTime)
    case timestamp(Timestamp)
    case timeSpan(TimeSpan)
    case calendarPeriod(CalendarPeriod)
    case geographicPoint(GeographicPoint)
    case geographicPosition(GeographicPosition)
    case vector(Vector)
    case uuid(UUID)
    case array([FieldValue])
    case object(FieldObject)
    case reference(EntityReference)
    case rdfTerm(RDFTerm)
}
