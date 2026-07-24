public indirect enum RDFTerm: Sendable, Hashable, Comparable {
    case iri(RDFIRI)
    case blankNode(RDFBlankNodeIdentifier)
    case literal(RDFLiteral)
    case tripleTerm(
        subject: RDFSubject,
        predicate: RDFPredicateIRI,
        object: RDFTerm
    )
}

extension RDFTerm {
    public static func == (
        lhs: RDFTerm,
        rhs: RDFTerm
    ) -> Bool {
        switch (lhs, rhs) {
        case (.iri(let left), .iri(let right)):
            return left == right
        case (.blankNode(let left), .blankNode(let right)):
            return left == right
        case (.literal(let left), .literal(let right)):
            return left == right
        case (
            .tripleTerm(let leftSubject, let leftPredicate, let leftObject),
            .tripleTerm(let rightSubject, let rightPredicate, let rightObject)
        ):
            return leftSubject == rightSubject
                && leftPredicate == rightPredicate
                && leftObject == rightObject
        default:
            return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(Self.rank(self))
        switch self {
        case .iri(let value):
            hasher.combine(value)
        case .blankNode(let value):
            hasher.combine(value)
        case .literal(let literal):
            literal.hash(into: &hasher)
        case .tripleTerm(let subject, let predicate, let object):
            subject.hash(into: &hasher)
            predicate.hash(into: &hasher)
            object.hash(into: &hasher)
        }
    }

    public static func < (lhs: RDFTerm, rhs: RDFTerm) -> Bool {
        switch (lhs, rhs) {
        case (.blankNode(let left), .blankNode(let right)):
            return left < right
        case (.iri(let left), .iri(let right)):
            return left < right
        case (.literal(let left), .literal(let right)):
            return compare(left, right)
        case (
            .tripleTerm(let leftSubject, let leftPredicate, let leftObject),
            .tripleTerm(let rightSubject, let rightPredicate, let rightObject)
        ):
            if leftSubject != rightSubject {
                return leftSubject < rightSubject
            }
            if leftPredicate != rightPredicate {
                return leftPredicate < rightPredicate
            }
            return leftObject < rightObject
        default:
            return rank(lhs) < rank(rhs)
        }
    }

    private static func rank(_ term: RDFTerm) -> UInt8 {
        switch term {
        case .blankNode: return 0
        case .iri: return 1
        case .literal: return 2
        case .tripleTerm: return 3
        }
    }

    private static func compare(
        _ lhs: RDFLiteral,
        _ rhs: RDFLiteral
    ) -> Bool {
        if lhs.annotation != rhs.annotation {
            return lhs.annotation < rhs.annotation
        }
        return StringIdentity.less(lhs.lexicalForm, rhs.lexicalForm)
    }
}
