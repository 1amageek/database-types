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
