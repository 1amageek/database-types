public struct ObjectField: Sendable {
    public let number: UInt32
    public let name: String
    public let value: FieldValue

    public init(
        number: UInt32,
        name: String,
        value: FieldValue
    ) throws(ObjectFieldError) {
        guard number > 0 else {
            throw .invalidNumber(number)
        }
        self.number = number
        self.name = name
        self.value = value
    }
}
