public enum RDFLiteralAnnotation: Sendable, Hashable, Comparable {
    case typed(RDFTypedLiteralDatatype)
    case languageTagged(RDFLanguageTag)
    case directionalLanguageTagged(
        RDFLanguageTag,
        RDFDirection
    )

    public var datatype: RDFIRI {
        switch self {
        case .typed(let datatype):
            return datatype.iri
        case .languageTagged:
            return .rdfLanguageString
        case .directionalLanguageTagged:
            return .rdfDirectionalLanguageString
        }
    }

    public var language: RDFLanguageTag? {
        switch self {
        case .typed:
            return nil
        case .languageTagged(let language),
             .directionalLanguageTagged(let language, _):
            return language
        }
    }

    public var direction: RDFDirection? {
        switch self {
        case .typed, .languageTagged:
            return nil
        case .directionalLanguageTagged(_, let direction):
            return direction
        }
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.typed(let left), .typed(let right)):
            return left < right
        case (.languageTagged(let left), .languageTagged(let right)):
            return left < right
        case (
            .directionalLanguageTagged(let leftLanguage, let leftDirection),
            .directionalLanguageTagged(let rightLanguage, let rightDirection)
        ):
            if leftLanguage != rightLanguage {
                return leftLanguage < rightLanguage
            }
            return leftDirection < rightDirection
        default:
            return rank(lhs) < rank(rhs)
        }
    }

    private static func rank(_ annotation: Self) -> UInt8 {
        switch annotation {
        case .typed: return 0
        case .languageTagged: return 1
        case .directionalLanguageTagged: return 2
        }
    }
}
