import DatabaseTypes
import Testing

@Suite("RDF term identity")
struct RDFIdentityTests {
    private let composed = "é"
    private let decomposed = "e\u{301}"

    @Test("Literal identity preserves the exact Unicode scalar sequence")
    func literalIdentity() {
        let left = RDFLiteral(
            lexicalForm: composed,
            datatype: XSDDatatype.string.typedLiteralDatatype
        )
        let right = RDFLiteral(
            lexicalForm: decomposed,
            datatype: XSDDatatype.string.typedLiteralDatatype
        )

        #expect(left != right)
        #expect(Set([left, right]).count == 2)
    }

    @Test("IRI and blank-node identity is not Unicode-normalized")
    func resourceIdentity() throws {
        let iris: Set<RDFTerm> = [
            .iri(try RDFIRI("https://example.com/\(composed)")),
            .iri(try RDFIRI("https://example.com/\(decomposed)")),
        ]
        let blankNodes: Set<RDFTerm> = [
            .blankNode(try RDFBlankNodeIdentifier(composed)),
            .blankNode(try RDFBlankNodeIdentifier(decomposed)),
        ]

        #expect(iris.count == 2)
        #expect(blankNodes.count == 2)
    }

    @Test("Exact ordering is consistent with equality for nested RDF-star terms")
    func orderingConsistency() throws {
        let left = RDFTerm.tripleTerm(
            subject: .iri(try RDFIRI("https://example.com/subject")),
            predicate: try RDFPredicateIRI("https://example.com/predicate"),
            object: .literal(RDFLiteral(
                lexicalForm: composed,
                datatype: XSDDatatype.string.typedLiteralDatatype
            ))
        )
        let right = RDFTerm.tripleTerm(
            subject: .iri(try RDFIRI("https://example.com/subject")),
            predicate: try RDFPredicateIRI("https://example.com/predicate"),
            object: .literal(RDFLiteral(
                lexicalForm: decomposed,
                datatype: XSDDatatype.string.typedLiteralDatatype
            ))
        )

        #expect(left != right)
        #expect((left < right) != (right < left))
        #expect(Set([left, right]).count == 2)
    }

    @Test("RDF 1.2 language tags use ASCII case-insensitive identity")
    func languageTagIdentity() throws {
        let uppercase = RDFLiteral(
            lexicalForm: "hello",
            language: try RDFLanguageTag("EN-Latn-US")
        )
        let lowercase = RDFLiteral(
            lexicalForm: "hello",
            language: try RDFLanguageTag("en-latn-us")
        )
        let uppercaseTerm = RDFTerm.literal(uppercase)
        let lowercaseTerm = RDFTerm.literal(lowercase)

        #expect(uppercase == lowercase)
        #expect(uppercase.languageTag?.rawValue == "en-latn-us")
        #expect(lowercase.languageTag?.rawValue == "en-latn-us")
        #expect(Set([uppercase, lowercase]).count == 1)
        #expect(!(uppercaseTerm < lowercaseTerm))
        #expect(!(lowercaseTerm < uppercaseTerm))
    }

    @Test("Language-tagged lexical forms remain case-sensitive")
    func languageTaggedLexicalIdentity() throws {
        let uppercase = RDFLiteral(
            lexicalForm: "Hello",
            language: try RDFLanguageTag("en")
        )
        let lowercase = RDFLiteral(
            lexicalForm: "hello",
            language: try RDFLanguageTag("EN")
        )

        #expect(uppercase != lowercase)
        #expect(Set([uppercase, lowercase]).count == 2)
    }
}
