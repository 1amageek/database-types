/// An immutable dense numeric vector that preserves its scalar width.
///
/// Array and slice initializers retain Swift copy-on-write storage. Constant-
/// time slices retain that storage and do not materialize element copies.
/// Similarity, distance, normalization, and indexing are not primitive value
/// responsibilities.
public struct Vector: Sendable, Hashable, Comparable {
    private enum Storage: Sendable {
        case float32(ArraySlice<Float>)
        case float64(ArraySlice<Double>)
    }

    private let storage: Storage

    public init(float32 elements: [Float]) throws(VectorError) {
        try self.init(float32: elements[...])
    }

    public init(float32 elements: ArraySlice<Float>) throws(VectorError) {
        for (offset, element) in elements.enumerated() {
            guard element.isFinite else {
                throw .nonFiniteFloat32(index: offset)
            }
        }
        self.storage = .float32(elements)
    }

    public init(float64 elements: [Double]) throws(VectorError) {
        try self.init(float64: elements[...])
    }

    public init(float64 elements: ArraySlice<Double>) throws(VectorError) {
        for (offset, element) in elements.enumerated() {
            guard element.isFinite else {
                throw .nonFiniteFloat64(index: offset)
            }
        }
        self.storage = .float64(elements)
    }

    private init(storage: Storage) {
        self.storage = storage
    }

    public var elementType: VectorElementType {
        switch storage {
        case .float32: .float32
        case .float64: .float64
        }
    }

    public var count: Int {
        switch storage {
        case .float32(let elements): elements.count
        case .float64(let elements): elements.count
        }
    }

    public func subvector(in bounds: Range<Int>) -> Self {
        precondition(bounds.lowerBound >= 0 && bounds.upperBound <= count)
        switch storage {
        case .float32(let elements):
            let lowerBound = elements.startIndex + bounds.lowerBound
            let upperBound = elements.startIndex + bounds.upperBound
            return Self(storage: .float32(elements[lowerBound..<upperBound]))
        case .float64(let elements):
            let lowerBound = elements.startIndex + bounds.lowerBound
            let upperBound = elements.startIndex + bounds.upperBound
            return Self(storage: .float64(elements[lowerBound..<upperBound]))
        }
    }

    /// Copies only the visible elements into independent retained storage.
    ///
    /// Use this when a small subvector must stop retaining a larger source
    /// buffer.
    public func detached() -> Self {
        switch storage {
        case .float32(let elements):
            return Self(storage: .float32(Array(elements)[...]))
        case .float64(let elements):
            return Self(storage: .float64(Array(elements)[...]))
        }
    }

    /// Borrows contiguous Float32 elements when this vector has Float32 width.
    public func withFloat32Elements<Result>(
        _ body: (UnsafeBufferPointer<Float>) throws -> Result
    ) rethrows -> Result? {
        guard case .float32(let elements) = storage else {
            return nil
        }
        return try elements.withUnsafeBufferPointer(body)
    }

    /// Borrows contiguous Float64 elements when this vector has Float64 width.
    public func withFloat64Elements<Result>(
        _ body: (UnsafeBufferPointer<Double>) throws -> Result
    ) rethrows -> Result? {
        guard case .float64(let elements) = storage else {
            return nil
        }
        return try elements.withUnsafeBufferPointer(body)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs.storage, rhs.storage) {
        case (.float32(let left), .float32(let right)):
            guard left.count == right.count else { return false }
            return zip(left, right).allSatisfy {
                $0.bitPattern == $1.bitPattern
            }
        case (.float64(let left), .float64(let right)):
            guard left.count == right.count else { return false }
            return zip(left, right).allSatisfy {
                $0.bitPattern == $1.bitPattern
            }
        default:
            return false
        }
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        guard lhs.elementType == rhs.elementType else {
            return lhs.elementType < rhs.elementType
        }

        switch (lhs.storage, rhs.storage) {
        case (.float32(let left), .float32(let right)):
            return elementsPrecede(left, right)
        case (.float64(let left), .float64(let right)):
            return elementsPrecede(left, right)
        default:
            return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(elementType)
        hasher.combine(count)
        switch storage {
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

    private static func elementsPrecede<Element>(
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
}
