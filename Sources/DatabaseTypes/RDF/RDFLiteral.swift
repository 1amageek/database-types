public struct RDFLiteral: Sendable, Hashable {
    public let lexicalForm: String
    public let annotation: RDFLiteralAnnotation

    public init(
        lexicalForm: String,
        annotation: RDFLiteralAnnotation
    ) {
        self.lexicalForm = lexicalForm
        self.annotation = annotation
    }

    public init(
        lexicalForm: String,
        datatype: RDFTypedLiteralDatatype
    ) {
        self.init(lexicalForm: lexicalForm, annotation: .typed(datatype))
    }

    public init(
        lexicalForm: String,
        datatype: String
    ) throws(RDFTypedLiteralDatatypeError) {
        self.init(
            lexicalForm: lexicalForm,
            datatype: try RDFTypedLiteralDatatype(datatype)
        )
    }

    public init(
        lexicalForm: String,
        language: RDFLanguageTag
    ) {
        self.init(
            lexicalForm: lexicalForm,
            annotation: .languageTagged(language)
        )
    }

    public init(
        lexicalForm: String,
        language: String
    ) throws(RDFLanguageTagError) {
        self.init(
            lexicalForm: lexicalForm,
            language: try RDFLanguageTag(language)
        )
    }

    public init(
        lexicalForm: String,
        language: RDFLanguageTag,
        direction: RDFDirection
    ) {
        self.init(
            lexicalForm: lexicalForm,
            annotation: .directionalLanguageTagged(language, direction)
        )
    }

    public var datatypeIRI: RDFIRI { annotation.datatype }
    public var languageTag: RDFLanguageTag? { annotation.language }
    public var baseDirection: RDFDirection? { annotation.direction }

    public static func == (
        lhs: RDFLiteral,
        rhs: RDFLiteral
    ) -> Bool {
        StringIdentity.equal(lhs.lexicalForm, rhs.lexicalForm)
            && lhs.annotation == rhs.annotation
    }

    public func hash(into hasher: inout Hasher) {
        StringIdentity.hash(lexicalForm, into: &hasher)
        hasher.combine(annotation)
    }
}
