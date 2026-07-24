/// A closed algebra of values that a field can contain.
///
/// The enum preserves the declared numeric width and representation. Numeric
/// coercion belongs to the consumer performing that operation and does not
/// change value identity, hashing, or ordering.
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
    case vector(Vector)
    case uuid(UUID)
    case array([FieldValue])
    case object([ObjectField])
    case reference(EntityReference)
    case rdfTerm(RDFTerm)
}
