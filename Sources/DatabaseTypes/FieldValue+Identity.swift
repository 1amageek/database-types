extension FieldValue: Hashable {
    public static func == (left: FieldValue, right: FieldValue) -> Bool {
        switch (left, right) {
        case (.null, .null):
            return true
        case (.bool(let left), .bool(let right)):
            return left == right
        case (.int8(let left), .int8(let right)):
            return left == right
        case (.int16(let left), .int16(let right)):
            return left == right
        case (.int32(let left), .int32(let right)):
            return left == right
        case (.int64(let left), .int64(let right)):
            return left == right
        case (.uint8(let left), .uint8(let right)):
            return left == right
        case (.uint16(let left), .uint16(let right)):
            return left == right
        case (.uint32(let left), .uint32(let right)):
            return left == right
        case (.uint64(let left), .uint64(let right)):
            return left == right
        case (.float32(let left), .float32(let right)):
            return left.bitPattern == right.bitPattern
        case (.float64(let left), .float64(let right)):
            return left.bitPattern == right.bitPattern
        case (.decimal(let left), .decimal(let right)):
            return left == right
        case (.string(let left), .string(let right)):
            return StringIdentity.equal(left, right)
        case (.bytes(let left), .bytes(let right)):
            return left == right
        case (.date(let left), .date(let right)):
            return left == right
        case (.time(let left), .time(let right)):
            return left == right
        case (.dateTime(let left), .dateTime(let right)):
            return left == right
        case (.timestamp(let left), .timestamp(let right)):
            return left == right
        case (.timeSpan(let left), .timeSpan(let right)):
            return left == right
        case (.calendarPeriod(let left), .calendarPeriod(let right)):
            return left == right
        case (.geographicPoint(let left), .geographicPoint(let right)):
            return left == right
        case (
            .geographicPosition(let left),
            .geographicPosition(let right)
        ):
            return left == right
        case (.vector(let left), .vector(let right)):
            return left == right
        case (.uuid(let left), .uuid(let right)):
            return left == right
        case (.array(let left), .array(let right)):
            return left == right
        case (.object(let left), .object(let right)):
            return left == right
        case (.reference(let left), .reference(let right)):
            return left == right
        case (.rdfTerm(let left), .rdfTerm(let right)):
            return left == right
        default:
            return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .null:
            hasher.combine(0 as UInt8)
        case .bool(let value):
            hasher.combine(1 as UInt8)
            hasher.combine(value)
        case .int8(let value):
            hasher.combine(2 as UInt8)
            hasher.combine(value)
        case .int16(let value):
            hasher.combine(3 as UInt8)
            hasher.combine(value)
        case .int32(let value):
            hasher.combine(4 as UInt8)
            hasher.combine(value)
        case .int64(let value):
            hasher.combine(5 as UInt8)
            hasher.combine(value)
        case .uint8(let value):
            hasher.combine(6 as UInt8)
            hasher.combine(value)
        case .uint16(let value):
            hasher.combine(7 as UInt8)
            hasher.combine(value)
        case .uint32(let value):
            hasher.combine(8 as UInt8)
            hasher.combine(value)
        case .uint64(let value):
            hasher.combine(9 as UInt8)
            hasher.combine(value)
        case .float32(let value):
            hasher.combine(10 as UInt8)
            hasher.combine(value.bitPattern)
        case .float64(let value):
            hasher.combine(11 as UInt8)
            hasher.combine(value.bitPattern)
        case .decimal(let value):
            hasher.combine(12 as UInt8)
            hasher.combine(value)
        case .string(let value):
            hasher.combine(13 as UInt8)
            StringIdentity.hash(value, into: &hasher)
        case .bytes(let value):
            hasher.combine(14 as UInt8)
            hasher.combine(value)
        case .date(let value):
            hasher.combine(15 as UInt8)
            hasher.combine(value)
        case .time(let value):
            hasher.combine(16 as UInt8)
            hasher.combine(value)
        case .dateTime(let value):
            hasher.combine(17 as UInt8)
            hasher.combine(value)
        case .timestamp(let value):
            hasher.combine(18 as UInt8)
            hasher.combine(value)
        case .timeSpan(let value):
            hasher.combine(19 as UInt8)
            hasher.combine(value)
        case .calendarPeriod(let value):
            hasher.combine(20 as UInt8)
            hasher.combine(value)
        case .geographicPoint(let value):
            hasher.combine(21 as UInt8)
            hasher.combine(value)
        case .geographicPosition(let value):
            hasher.combine(22 as UInt8)
            hasher.combine(value)
        case .vector(let value):
            hasher.combine(23 as UInt8)
            hasher.combine(value)
        case .uuid(let value):
            hasher.combine(24 as UInt8)
            hasher.combine(value)
        case .array(let values):
            hasher.combine(25 as UInt8)
            hasher.combine(values)
        case .object(let fields):
            hasher.combine(26 as UInt8)
            hasher.combine(fields)
        case .reference(let identity):
            hasher.combine(27 as UInt8)
            hasher.combine(identity)
        case .rdfTerm(let term):
            hasher.combine(28 as UInt8)
            hasher.combine(term)
        }
    }
}
