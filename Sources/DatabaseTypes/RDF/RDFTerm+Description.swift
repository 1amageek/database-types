extension RDFTerm: CustomStringConvertible {
    public var description: String {
        switch self {
        case .iri(let value):
            return "<\(value.rawValue)>"
        case .blankNode(let identifier):
            return "_:\(identifier.rawValue)"
        case .literal(let literal):
            return literal.description
        case .tripleTerm(let subject, let predicate, let object):
            return "<<( \(subject) <\(predicate.rawValue)> \(object) )>>"
        }
    }
}
