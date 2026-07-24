extension RDFLiteral: CustomStringConvertible {
    public var description: String {
        let lexical = Self.escape(lexicalForm)
        if let language = languageTag {
            if let direction = baseDirection {
                return "\"\(lexical)\"@\(language.rawValue)--\(direction.rawValue)"
            }
            return "\"\(lexical)\"@\(language.rawValue)"
        }
        return "\"\(lexical)\"^^<\(datatypeIRI.rawValue)>"
    }

    private static func escape(_ value: String) -> String {
        var result = ""
        result.reserveCapacity(value.utf8.count)
        for character in value {
            switch character {
            case "\\": result += "\\\\"
            case "\"": result += "\\\""
            case "\n": result += "\\n"
            case "\r": result += "\\r"
            case "\t": result += "\\t"
            default: result.append(character)
            }
        }
        return result
    }
}
