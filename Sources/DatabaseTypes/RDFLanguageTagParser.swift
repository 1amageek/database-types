enum RDFLanguageTagParser {
    static func validate(_ source: String) -> Bool {
        if let result = source.utf8.withContiguousStorageIfAvailable({ bytes in
            RDFLanguageTagBytesValidator.validate(
                UnsafeRawBufferPointer(bytes),
                range: 0..<bytes.count
            )
        }) {
            return result
        }

        // A String is not required to expose contiguous UTF-8 storage. This
        // uncommon semantic-construction boundary may materialize its small
        // language tag; storage and wire validation always use borrowed bytes.
        let bytes = Array(source.utf8)
        return bytes.withUnsafeBytes { buffer in
            RDFLanguageTagBytesValidator.validate(
                buffer,
                range: 0..<buffer.count
            )
        }
    }
}
