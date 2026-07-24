extension FieldValue {
    public var isNull: Bool {
        if case .null = self {
            return true
        }
        return false
    }

    public var boolValue: Bool? {
        guard case .bool(let value) = self else { return nil }
        return value
    }

    public var int8Value: Int8? {
        guard case .int8(let value) = self else { return nil }
        return value
    }

    public var int16Value: Int16? {
        guard case .int16(let value) = self else { return nil }
        return value
    }

    public var int32Value: Int32? {
        guard case .int32(let value) = self else { return nil }
        return value
    }

    public var int64Value: Int64? {
        guard case .int64(let value) = self else { return nil }
        return value
    }

    public var uint8Value: UInt8? {
        guard case .uint8(let value) = self else { return nil }
        return value
    }

    public var uint16Value: UInt16? {
        guard case .uint16(let value) = self else { return nil }
        return value
    }

    public var uint32Value: UInt32? {
        guard case .uint32(let value) = self else { return nil }
        return value
    }

    public var uint64Value: UInt64? {
        guard case .uint64(let value) = self else { return nil }
        return value
    }

    public var float32Value: Float? {
        guard case .float32(let value) = self else { return nil }
        return value
    }

    public var float64Value: Double? {
        guard case .float64(let value) = self else { return nil }
        return value
    }

    public var decimalValue: (coefficient: Int64, scale: Int32)? {
        guard case .decimal(let coefficient, let scale) = self else {
            return nil
        }
        return (coefficient, scale)
    }

    public var stringValue: String? {
        guard case .string(let value) = self else { return nil }
        return value
    }

    public var bytesValue: ByteString? {
        guard case .bytes(let value) = self else { return nil }
        return value
    }

    public var dateValue: CivilDate? {
        guard case .date(let value) = self else { return nil }
        return value
    }

    public var timestampValue: Timestamp? {
        guard case .timestamp(let value) = self else { return nil }
        return value
    }

    public var uuidValue: UUID? {
        guard case .uuid(let value) = self else { return nil }
        return value
    }

    public var arrayValue: [FieldValue]? {
        guard case .array(let value) = self else { return nil }
        return value
    }

    public var objectValue: [ObjectField]? {
        guard case .object(let value) = self else { return nil }
        return value
    }

    public var referenceValue: EntityIdentity? {
        guard case .reference(let value) = self else { return nil }
        return value
    }

    public var rdfTermValue: RDFTerm? {
        guard case .rdfTerm(let value) = self else { return nil }
        return value
    }
}
