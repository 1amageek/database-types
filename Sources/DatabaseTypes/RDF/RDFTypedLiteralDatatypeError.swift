public enum RDFTypedLiteralDatatypeError: Error, Sendable, Equatable {
    case invalidIRI(RDFIRIError)
    case languageDatatypeRequiresLanguage
    case directionalLanguageDatatypeRequiresLanguageAndDirection
}
