import DatabaseTypes
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

public extension ExactDecimal {
    /// Creates a canonical decimal when the Foundation value fits its exact
    /// coefficient and scale representation.
    init(_ value: Decimal) throws(ExactDecimalConversionError) {
        guard !value.isNaN else {
            throw .nonFiniteValue
        }
        self = try Self.parseFoundationDescription(String(describing: value))
    }

    private static func parseFoundationDescription(
        _ description: String
    ) throws(ExactDecimalConversionError) -> Self {
        let bytes = Array(description.utf8)
        guard !bytes.isEmpty else {
            throw .invalidRepresentation
        }

        var cursor = 0
        var isNegative = false
        if bytes[cursor] == 45 || bytes[cursor] == 43 {
            isNegative = bytes[cursor] == 45
            cursor += 1
        }
        guard cursor < bytes.count else {
            throw .invalidRepresentation
        }

        var digits: [UInt8] = []
        digits.reserveCapacity(bytes.count)
        var fractionalDigitCount: Int64 = 0
        var hasDecimalSeparator = false

        while cursor < bytes.count {
            let byte = bytes[cursor]
            if byte >= 48, byte <= 57 {
                digits.append(byte - 48)
                if hasDecimalSeparator {
                    fractionalDigitCount += 1
                }
                cursor += 1
                continue
            }
            if byte == 46, !hasDecimalSeparator {
                hasDecimalSeparator = true
                cursor += 1
                continue
            }
            break
        }
        guard !digits.isEmpty else {
            throw .invalidRepresentation
        }

        var exponent: Int64 = 0
        if cursor < bytes.count, bytes[cursor] == 69 || bytes[cursor] == 101 {
            cursor += 1
            guard cursor < bytes.count else {
                throw .invalidRepresentation
            }
            var exponentIsNegative = false
            if bytes[cursor] == 45 || bytes[cursor] == 43 {
                exponentIsNegative = bytes[cursor] == 45
                cursor += 1
            }
            guard cursor < bytes.count else {
                throw .invalidRepresentation
            }

            var hasExponentDigit = false
            while cursor < bytes.count {
                let byte = bytes[cursor]
                guard byte >= 48, byte <= 57 else {
                    throw .invalidRepresentation
                }
                hasExponentDigit = true
                let multiplied = exponent.multipliedReportingOverflow(by: 10)
                guard !multiplied.overflow else {
                    throw .scaleOutOfRange
                }
                let added = multiplied.partialValue.addingReportingOverflow(
                    Int64(byte - 48)
                )
                guard !added.overflow else {
                    throw .scaleOutOfRange
                }
                exponent = added.partialValue
                cursor += 1
            }
            guard hasExponentDigit else {
                throw .invalidRepresentation
            }
            if exponentIsNegative {
                exponent = -exponent
            }
        }
        guard cursor == bytes.count else {
            throw .invalidRepresentation
        }

        while digits.first == 0 {
            digits.removeFirst()
        }
        guard !digits.isEmpty else {
            return Self(coefficient: 0, scale: 0)
        }

        let initialScale = fractionalDigitCount.subtractingReportingOverflow(
            exponent
        )
        guard !initialScale.overflow else {
            throw .scaleOutOfRange
        }
        var scale = initialScale.partialValue
        while digits.last == 0 {
            digits.removeLast()
            let decremented = scale.subtractingReportingOverflow(1)
            guard !decremented.overflow else {
                throw .scaleOutOfRange
            }
            scale = decremented.partialValue
        }

        let maximumMagnitude = isNegative
            ? UInt128(Int128.max) + 1
            : UInt128(Int128.max)
        var magnitude: UInt128 = 0
        for digit in digits {
            guard magnitude <= (maximumMagnitude - UInt128(digit)) / 10 else {
                throw .coefficientOutOfRange
            }
            magnitude = magnitude * 10 + UInt128(digit)
        }

        let coefficient: Int128
        if isNegative {
            if magnitude == UInt128(Int128.max) + 1 {
                coefficient = Int128.min
            } else {
                guard let signed = Int128(exactly: magnitude) else {
                    throw .coefficientOutOfRange
                }
                coefficient = -signed
            }
        } else {
            guard let signed = Int128(exactly: magnitude) else {
                throw .coefficientOutOfRange
            }
            coefficient = signed
        }

        guard let canonicalScale = Int32(exactly: scale) else {
            throw .scaleOutOfRange
        }
        return Self(
            coefficient: coefficient,
            scale: canonicalScale
        )
    }
}

public extension Decimal {
    /// Creates a Foundation decimal when it can preserve the canonical value
    /// exactly.
    init(_ value: ExactDecimal) throws(ExactDecimalConversionError) {
        guard value.scale >= -127, value.scale <= 128 else {
            throw .valueOutOfRange
        }

        let lexicalForm: String
        do {
            lexicalForm = try value.decimalLexicalForm(
                maximumUTF8Count: 160
            )
        } catch {
            throw .valueOutOfRange
        }

        guard let converted = Decimal(
            string: lexicalForm,
            locale: Locale(identifier: "en_US_POSIX")
        ), !converted.isNaN else {
            throw .valueOutOfRange
        }

        do {
            guard try ExactDecimal(converted) == value else {
                throw ExactDecimalConversionError.valueOutOfRange
            }
        } catch let error as ExactDecimalConversionError {
            throw error
        } catch {
            throw .valueOutOfRange
        }
        self = converted
    }
}
