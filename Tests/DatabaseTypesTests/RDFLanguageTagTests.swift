import DatabaseTypes
import Testing

@Suite("RDF language-tag model")
struct RDFLanguageTagTests {
    @Test("BCP 47 well-formed tags are accepted and canonicalized")
    func wellFormedTags() throws {
        let values = [
            "en",
            "EN-Latn-US",
            "zh-min-nan",
            "x-private-1",
            "en-Latn-US-u-ca-gregory-x-private",
        ]

        for value in values {
            let tag = try RDFLanguageTag(value)
            #expect(tag.rawValue == value.lowercased())
        }
    }

    @Test("malformed language tags fail at construction")
    func malformedTags() {
        let values = [
            "",
            "en-",
            "-en",
            "en_US",
            "x",
            "en-a",
            "en-abcdefghi",
            "12",
            "日本語",
            "de-1901-1901",
            "en-abcde-abcde",
            "en-a-foo-a-bar",
        ]

        for value in values {
            #expect(throws: RDFLanguageTagError.self) {
                _ = try RDFLanguageTag(value)
            }
        }
    }

    @Test("language and direction determine the only legal RDF annotations")
    func literalAnnotations() throws {
        let language = try RDFLanguageTag("AR")
        let tagged = RDFLiteral(
            lexicalForm: "مرحبا",
            language: language
        )
        let directional = RDFLiteral(
            lexicalForm: "مرحبا",
            language: language,
            direction: .rightToLeft
        )

        #expect(tagged.datatypeIRI == .rdfLanguageString)
        #expect(tagged.languageTag?.rawValue == "ar")
        #expect(tagged.baseDirection == nil)
        #expect(directional.datatypeIRI == .rdfDirectionalLanguageString)
        #expect(directional.languageTag?.rawValue == "ar")
        #expect(directional.baseDirection == .rightToLeft)
    }

    @Test("reserved language datatypes cannot form ordinary typed literals")
    func reservedDatatypeInvariants() throws {
        #expect(
            throws: RDFTypedLiteralDatatypeError
                .languageDatatypeRequiresLanguage
        ) {
            _ = try RDFTypedLiteralDatatype(.rdfLanguageString)
        }
        #expect(
            throws: RDFTypedLiteralDatatypeError
                .directionalLanguageDatatypeRequiresLanguageAndDirection
        ) {
            _ = try RDFTypedLiteralDatatype(
                .rdfDirectionalLanguageString
            )
        }
    }
}
