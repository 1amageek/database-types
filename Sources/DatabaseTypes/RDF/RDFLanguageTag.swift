/// A well-formed BCP 47 language tag with canonical ASCII-lowercase storage.
public struct RDFLanguageTag: Sendable, Hashable, Comparable,
    CustomStringConvertible
{
    public let rawValue: String

    public init(_ rawValue: String) throws(RDFLanguageTagError) {
        guard !rawValue.isEmpty else { throw .empty }
        guard RDFLanguageTagParser.validate(rawValue) else {
            throw .invalidSyntax
        }
        self.rawValue = StringIdentity.canonicalASCIILowercase(rawValue)
    }

    init(validatedRawValue rawValue: String) {
        self.rawValue = rawValue
    }

    public static let english = Self(validatedRawValue: "en")

    /// Validates one borrowed UTF-8 range without materializing a `String`.
    ///
    /// The buffer remains owned by the caller and is borrowed only for this
    /// synchronous invocation.
    public static func isValid(
        utf8 bytes: UnsafeRawBufferPointer,
        in range: Range<Int>
    ) -> Bool {
        guard range.lowerBound >= 0,
              range.upperBound <= bytes.count else {
            return false
        }
        return RDFLanguageTagBytesValidator.validate(bytes, range: range)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        StringIdentity.equal(lhs.rawValue, rhs.rawValue)
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        StringIdentity.less(lhs.rawValue, rhs.rawValue)
    }

    public func hash(into hasher: inout Hasher) {
        StringIdentity.hash(rawValue, into: &hasher)
    }

    public var description: String { rawValue }
}
