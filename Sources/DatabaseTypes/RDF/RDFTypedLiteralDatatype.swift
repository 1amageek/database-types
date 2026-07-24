/// A datatype IRI that can annotate an RDF typed literal directly.
///
/// `rdf:langString` and `rdf:dirLangString` are excluded because RDF 1.2
/// requires their language and direction components to be present.
public struct RDFTypedLiteralDatatype: Sendable, Hashable, Comparable,
    CustomStringConvertible
{
    public let iri: RDFIRI

    public init(
        _ iri: RDFIRI
    ) throws(RDFTypedLiteralDatatypeError) {
        guard iri != .rdfLanguageString else {
            throw .languageDatatypeRequiresLanguage
        }
        guard iri != .rdfDirectionalLanguageString else {
            throw .directionalLanguageDatatypeRequiresLanguageAndDirection
        }
        self.iri = iri
    }

    public init(
        _ rawValue: String
    ) throws(RDFTypedLiteralDatatypeError) {
        let iri: RDFIRI
        do {
            iri = try RDFIRI(rawValue)
        } catch let error {
            throw .invalidIRI(error)
        }
        try self.init(iri)
    }

    init(validatedIRI iri: RDFIRI) {
        self.iri = iri
    }

    public static let xsdString = Self(validatedIRI: .xsdString)

    public var rawValue: String { iri.rawValue }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.iri < rhs.iri
    }

    public var description: String { iri.rawValue }
}
