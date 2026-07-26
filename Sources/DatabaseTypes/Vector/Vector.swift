/// An immutable dense numeric vector that preserves its scalar width.
///
/// Array and slice initializers retain Swift copy-on-write storage. Constant-
/// time slices retain that storage and do not materialize element copies.
/// Similarity, distance, normalization, and indexing are not primitive value
/// responsibilities.
public struct Vector: Sendable, Hashable, Comparable {
    private enum Storage: Sendable {
        case int8(ArraySlice<Int8>)
        case int16(ArraySlice<Int16>)
        case int32(ArraySlice<Int32>)
        case int64(ArraySlice<Int64>)
        case uint8(ArraySlice<UInt8>)
        case uint16(ArraySlice<UInt16>)
        case uint32(ArraySlice<UInt32>)
        case uint64(ArraySlice<UInt64>)
        case float32(ArraySlice<Float>)
        case float64(ArraySlice<Double>)
    }

    private let storage: Storage
    private let retainedElementCount: Int?

    public init(int8 elements: [Int8]) {
        self.storage = .int8(elements[...])
        self.retainedElementCount = elements.count
    }

    public init(int8 elements: ArraySlice<Int8>) {
        self.storage = .int8(elements)
        self.retainedElementCount = nil
    }

    public init(int16 elements: [Int16]) {
        self.storage = .int16(elements[...])
        self.retainedElementCount = elements.count
    }

    public init(int16 elements: ArraySlice<Int16>) {
        self.storage = .int16(elements)
        self.retainedElementCount = nil
    }

    public init(int32 elements: [Int32]) {
        self.storage = .int32(elements[...])
        self.retainedElementCount = elements.count
    }

    public init(int32 elements: ArraySlice<Int32>) {
        self.storage = .int32(elements)
        self.retainedElementCount = nil
    }

    public init(int64 elements: [Int64]) {
        self.storage = .int64(elements[...])
        self.retainedElementCount = elements.count
    }

    public init(int64 elements: ArraySlice<Int64>) {
        self.storage = .int64(elements)
        self.retainedElementCount = nil
    }

    public init(uint8 elements: [UInt8]) {
        self.storage = .uint8(elements[...])
        self.retainedElementCount = elements.count
    }

    public init(uint8 elements: ArraySlice<UInt8>) {
        self.storage = .uint8(elements)
        self.retainedElementCount = nil
    }

    public init(uint16 elements: [UInt16]) {
        self.storage = .uint16(elements[...])
        self.retainedElementCount = elements.count
    }

    public init(uint16 elements: ArraySlice<UInt16>) {
        self.storage = .uint16(elements)
        self.retainedElementCount = nil
    }

    public init(uint32 elements: [UInt32]) {
        self.storage = .uint32(elements[...])
        self.retainedElementCount = elements.count
    }

    public init(uint32 elements: ArraySlice<UInt32>) {
        self.storage = .uint32(elements)
        self.retainedElementCount = nil
    }

    public init(uint64 elements: [UInt64]) {
        self.storage = .uint64(elements[...])
        self.retainedElementCount = elements.count
    }

    public init(uint64 elements: ArraySlice<UInt64>) {
        self.storage = .uint64(elements)
        self.retainedElementCount = nil
    }

    public init(float32 elements: [Float]) throws(VectorError) {
        for (offset, element) in elements.enumerated() {
            guard element.isFinite else {
                throw .nonFiniteFloat32(index: offset)
            }
        }
        self.storage = .float32(elements[...])
        self.retainedElementCount = elements.count
    }

    public init(float32 elements: ArraySlice<Float>) throws(VectorError) {
        for (offset, element) in elements.enumerated() {
            guard element.isFinite else {
                throw .nonFiniteFloat32(index: offset)
            }
        }
        self.storage = .float32(elements)
        self.retainedElementCount = nil
    }

    public init(float64 elements: [Double]) throws(VectorError) {
        for (offset, element) in elements.enumerated() {
            guard element.isFinite else {
                throw .nonFiniteFloat64(index: offset)
            }
        }
        self.storage = .float64(elements[...])
        self.retainedElementCount = elements.count
    }

    public init(float64 elements: ArraySlice<Double>) throws(VectorError) {
        for (offset, element) in elements.enumerated() {
            guard element.isFinite else {
                throw .nonFiniteFloat64(index: offset)
            }
        }
        self.storage = .float64(elements)
        self.retainedElementCount = nil
    }

    private init(
        storage: Storage,
        retainedElementCount: Int?
    ) {
        self.storage = storage
        self.retainedElementCount = retainedElementCount
    }

    public var elementType: VectorElementType {
        switch storage {
        case .int8: .int8
        case .int16: .int16
        case .int32: .int32
        case .int64: .int64
        case .uint8: .uint8
        case .uint16: .uint16
        case .uint32: .uint32
        case .uint64: .uint64
        case .float32: .float32
        case .float64: .float64
        }
    }

    public var count: Int {
        switch storage {
        case .int8(let elements): elements.count
        case .int16(let elements): elements.count
        case .int32(let elements): elements.count
        case .int64(let elements): elements.count
        case .uint8(let elements): elements.count
        case .uint16(let elements): elements.count
        case .uint32(let elements): elements.count
        case .uint64(let elements): elements.count
        case .float32(let elements): elements.count
        case .float64(let elements): elements.count
        }
    }

    /// The canonical payload byte count retained by this vector, when known.
    ///
    /// A subvector keeps the source storage alive, so its retained payload can
    /// be larger than its visible `count`. This value excludes container
    /// metadata and uses the scalar width represented by `elementType`.
    /// An `ArraySlice` cannot reveal its complete retained allocation, so a
    /// vector initialized directly from one returns `nil` until detached.
    public var retainedByteCount: Int? {
        retainedElementCount.map { $0 * elementType.byteCount }
    }

    public func subvector(in bounds: Range<Int>) -> Self {
        precondition(bounds.lowerBound >= 0 && bounds.upperBound <= count)
        switch storage {
        case .int8(let elements):
            return Self(
                storage: .int8(Self.slice(elements, in: bounds)),
                retainedElementCount: retainedElementCount
            )
        case .int16(let elements):
            return Self(
                storage: .int16(Self.slice(elements, in: bounds)),
                retainedElementCount: retainedElementCount
            )
        case .int32(let elements):
            return Self(
                storage: .int32(Self.slice(elements, in: bounds)),
                retainedElementCount: retainedElementCount
            )
        case .int64(let elements):
            return Self(
                storage: .int64(Self.slice(elements, in: bounds)),
                retainedElementCount: retainedElementCount
            )
        case .uint8(let elements):
            return Self(
                storage: .uint8(Self.slice(elements, in: bounds)),
                retainedElementCount: retainedElementCount
            )
        case .uint16(let elements):
            return Self(
                storage: .uint16(Self.slice(elements, in: bounds)),
                retainedElementCount: retainedElementCount
            )
        case .uint32(let elements):
            return Self(
                storage: .uint32(Self.slice(elements, in: bounds)),
                retainedElementCount: retainedElementCount
            )
        case .uint64(let elements):
            return Self(
                storage: .uint64(Self.slice(elements, in: bounds)),
                retainedElementCount: retainedElementCount
            )
        case .float32(let elements):
            return Self(
                storage: .float32(Self.slice(elements, in: bounds)),
                retainedElementCount: retainedElementCount
            )
        case .float64(let elements):
            return Self(
                storage: .float64(Self.slice(elements, in: bounds)),
                retainedElementCount: retainedElementCount
            )
        }
    }

    /// Copies only the visible elements into independent retained storage.
    ///
    /// Use this when a small subvector must stop retaining a larger source
    /// buffer.
    public func detached() -> Self {
        switch storage {
        case .int8(let elements):
            return Self(int8: Array(elements))
        case .int16(let elements):
            return Self(int16: Array(elements))
        case .int32(let elements):
            return Self(int32: Array(elements))
        case .int64(let elements):
            return Self(int64: Array(elements))
        case .uint8(let elements):
            return Self(uint8: Array(elements))
        case .uint16(let elements):
            return Self(uint16: Array(elements))
        case .uint32(let elements):
            return Self(uint32: Array(elements))
        case .uint64(let elements):
            return Self(uint64: Array(elements))
        case .float32(let elements):
            do {
                return try Self(float32: Array(elements))
            } catch {
                preconditionFailure(
                    "A validated Float32 vector became invalid while detaching"
                )
            }
        case .float64(let elements):
            do {
                return try Self(float64: Array(elements))
            } catch {
                preconditionFailure(
                    "A validated Float64 vector became invalid while detaching"
                )
            }
        }
    }

    /// Borrows contiguous Int8 elements when this vector has Int8 width.
    public func withInt8Elements<Result>(
        _ body: (UnsafeBufferPointer<Int8>) throws -> Result
    ) rethrows -> Result? {
        guard case .int8(let elements) = storage else { return nil }
        return try elements.withUnsafeBufferPointer(body)
    }

    /// Borrows contiguous Int16 elements when this vector has Int16 width.
    public func withInt16Elements<Result>(
        _ body: (UnsafeBufferPointer<Int16>) throws -> Result
    ) rethrows -> Result? {
        guard case .int16(let elements) = storage else { return nil }
        return try elements.withUnsafeBufferPointer(body)
    }

    /// Borrows contiguous Int32 elements when this vector has Int32 width.
    public func withInt32Elements<Result>(
        _ body: (UnsafeBufferPointer<Int32>) throws -> Result
    ) rethrows -> Result? {
        guard case .int32(let elements) = storage else { return nil }
        return try elements.withUnsafeBufferPointer(body)
    }

    /// Borrows contiguous Int64 elements when this vector has Int64 width.
    public func withInt64Elements<Result>(
        _ body: (UnsafeBufferPointer<Int64>) throws -> Result
    ) rethrows -> Result? {
        guard case .int64(let elements) = storage else { return nil }
        return try elements.withUnsafeBufferPointer(body)
    }

    /// Borrows contiguous UInt8 elements when this vector has UInt8 width.
    public func withUInt8Elements<Result>(
        _ body: (UnsafeBufferPointer<UInt8>) throws -> Result
    ) rethrows -> Result? {
        guard case .uint8(let elements) = storage else { return nil }
        return try elements.withUnsafeBufferPointer(body)
    }

    /// Borrows contiguous UInt16 elements when this vector has UInt16 width.
    public func withUInt16Elements<Result>(
        _ body: (UnsafeBufferPointer<UInt16>) throws -> Result
    ) rethrows -> Result? {
        guard case .uint16(let elements) = storage else { return nil }
        return try elements.withUnsafeBufferPointer(body)
    }

    /// Borrows contiguous UInt32 elements when this vector has UInt32 width.
    public func withUInt32Elements<Result>(
        _ body: (UnsafeBufferPointer<UInt32>) throws -> Result
    ) rethrows -> Result? {
        guard case .uint32(let elements) = storage else { return nil }
        return try elements.withUnsafeBufferPointer(body)
    }

    /// Borrows contiguous UInt64 elements when this vector has UInt64 width.
    public func withUInt64Elements<Result>(
        _ body: (UnsafeBufferPointer<UInt64>) throws -> Result
    ) rethrows -> Result? {
        guard case .uint64(let elements) = storage else { return nil }
        return try elements.withUnsafeBufferPointer(body)
    }

    /// Borrows contiguous Float32 elements when this vector has Float32 width.
    public func withFloat32Elements<Result>(
        _ body: (UnsafeBufferPointer<Float>) throws -> Result
    ) rethrows -> Result? {
        guard case .float32(let elements) = storage else { return nil }
        return try elements.withUnsafeBufferPointer(body)
    }

    /// Borrows contiguous Float64 elements when this vector has Float64 width.
    public func withFloat64Elements<Result>(
        _ body: (UnsafeBufferPointer<Double>) throws -> Result
    ) rethrows -> Result? {
        guard case .float64(let elements) = storage else { return nil }
        return try elements.withUnsafeBufferPointer(body)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs.storage, rhs.storage) {
        case (.int8(let left), .int8(let right)): left == right
        case (.int16(let left), .int16(let right)): left == right
        case (.int32(let left), .int32(let right)): left == right
        case (.int64(let left), .int64(let right)): left == right
        case (.uint8(let left), .uint8(let right)): left == right
        case (.uint16(let left), .uint16(let right)): left == right
        case (.uint32(let left), .uint32(let right)): left == right
        case (.uint64(let left), .uint64(let right)): left == right
        case (.float32(let left), .float32(let right)):
            floatingElementsEqual(left, right)
        case (.float64(let left), .float64(let right)):
            floatingElementsEqual(left, right)
        default:
            false
        }
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        guard lhs.elementType == rhs.elementType else {
            return lhs.elementType < rhs.elementType
        }

        switch (lhs.storage, rhs.storage) {
        case (.int8(let left), .int8(let right)):
            return elementsPrecede(left, right)
        case (.int16(let left), .int16(let right)):
            return elementsPrecede(left, right)
        case (.int32(let left), .int32(let right)):
            return elementsPrecede(left, right)
        case (.int64(let left), .int64(let right)):
            return elementsPrecede(left, right)
        case (.uint8(let left), .uint8(let right)):
            return elementsPrecede(left, right)
        case (.uint16(let left), .uint16(let right)):
            return elementsPrecede(left, right)
        case (.uint32(let left), .uint32(let right)):
            return elementsPrecede(left, right)
        case (.uint64(let left), .uint64(let right)):
            return elementsPrecede(left, right)
        case (.float32(let left), .float32(let right)):
            return floatingElementsPrecede(left, right)
        case (.float64(let left), .float64(let right)):
            return floatingElementsPrecede(left, right)
        default:
            return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(elementType)
        hasher.combine(count)
        switch storage {
        case .int8(let elements): hash(elements, into: &hasher)
        case .int16(let elements): hash(elements, into: &hasher)
        case .int32(let elements): hash(elements, into: &hasher)
        case .int64(let elements): hash(elements, into: &hasher)
        case .uint8(let elements): hash(elements, into: &hasher)
        case .uint16(let elements): hash(elements, into: &hasher)
        case .uint32(let elements): hash(elements, into: &hasher)
        case .uint64(let elements): hash(elements, into: &hasher)
        case .float32(let elements):
            for element in elements {
                hasher.combine(element.bitPattern)
            }
        case .float64(let elements):
            for element in elements {
                hasher.combine(element.bitPattern)
            }
        }
    }

    private static func slice<Element>(
        _ elements: ArraySlice<Element>,
        in bounds: Range<Int>
    ) -> ArraySlice<Element> {
        let lowerBound = elements.startIndex + bounds.lowerBound
        let upperBound = elements.startIndex + bounds.upperBound
        return elements[lowerBound..<upperBound]
    }

    private static func elementsPrecede<Element>(
        _ left: ArraySlice<Element>,
        _ right: ArraySlice<Element>
    ) -> Bool where Element: Comparable {
        left.lexicographicallyPrecedes(right)
    }

    private static func floatingElementsEqual<Element>(
        _ left: ArraySlice<Element>,
        _ right: ArraySlice<Element>
    ) -> Bool where Element: BinaryFloatingPoint {
        guard left.count == right.count else { return false }
        var leftIndex = left.startIndex
        var rightIndex = right.startIndex
        while leftIndex != left.endIndex {
            let leftElement = left[leftIndex]
            let rightElement = right[rightIndex]
            guard leftElement == rightElement,
                  leftElement.sign == rightElement.sign else {
                return false
            }
            left.formIndex(after: &leftIndex)
            right.formIndex(after: &rightIndex)
        }
        return true
    }

    private static func floatingElementsPrecede<Element>(
        _ left: ArraySlice<Element>,
        _ right: ArraySlice<Element>
    ) -> Bool where Element: BinaryFloatingPoint {
        var leftIndex = left.startIndex
        var rightIndex = right.startIndex
        while leftIndex != left.endIndex && rightIndex != right.endIndex {
            let leftElement = left[leftIndex]
            let rightElement = right[rightIndex]
            if leftElement != rightElement
                || leftElement.sign != rightElement.sign {
                return leftElement.isTotallyOrdered(
                    belowOrEqualTo: rightElement
                )
            }
            left.formIndex(after: &leftIndex)
            right.formIndex(after: &rightIndex)
        }
        return left.count < right.count
    }

    private func hash<Element>(
        _ elements: ArraySlice<Element>,
        into hasher: inout Hasher
    ) where Element: Hashable {
        for element in elements {
            hasher.combine(element)
        }
    }
}
