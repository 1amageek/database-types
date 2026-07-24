/// The application-scoped identifier of an RDF blank node.
///
/// The identifier is not a serialized Turtle label. Its exact Unicode scalar
/// sequence is part of node identity and is therefore preserved.
public struct RDFBlankNodeIdentifier:
    Sendable,
    Hashable,
    Comparable,
    CustomStringConvertible {
    public let rawValue: String

    public init(_ rawValue: String) throws(RDFBlankNodeIdentifierError) {
        guard !rawValue.isEmpty else {
            throw .empty
        }
        self.rawValue = rawValue
    }

    public static func == (
        lhs: Self,
        rhs: Self
    ) -> Bool {
        StringIdentity.equal(lhs.rawValue, rhs.rawValue)
    }

    public static func < (
        lhs: Self,
        rhs: Self
    ) -> Bool {
        StringIdentity.less(lhs.rawValue, rhs.rawValue)
    }

    public func hash(into hasher: inout Hasher) {
        StringIdentity.hash(rawValue, into: &hasher)
    }

    public var description: String { rawValue }
}
