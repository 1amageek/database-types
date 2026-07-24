import DatabaseTypes
import Testing

@Suite("ExactDecimal")
struct ExactDecimalTests {
    @Test func normalizesAndAddsWithoutFloatingPoint() throws {
        let left = ExactDecimal(coefficient: 120, scale: 2)
        let right = ExactDecimal(coefficient: 3, scale: 1)

        #expect(left == ExactDecimal(coefficient: 12, scale: 1))
        #expect(
            try left.adding(right)
                == ExactDecimal(coefficient: 15, scale: 1)
        )
    }

    @Test func multipliesAndDividesExactly() throws {
        let left = ExactDecimal(coefficient: 25, scale: 1)
        let right = ExactDecimal(coefficient: 4, scale: 0)

        #expect(
            try left.multiplying(by: right)
                == ExactDecimal(coefficient: 10, scale: 0)
        )
        #expect(
            try left.dividing(by: right)
                == ExactDecimal(coefficient: 625, scale: 3)
        )
    }

    @Test func inexactDivisionAndOverflowAreTypedFailures() {
        let one = ExactDecimal(coefficient: 1, scale: 0)
        let three = ExactDecimal(coefficient: 3, scale: 0)
        #expect(throws: ExactDecimalError.inexactResult) {
            _ = try one.dividing(by: three)
        }

        let maximum = ExactDecimal(coefficient: Int128.max, scale: 0)
        #expect(throws: ExactDecimalError.numericOverflow) {
            _ = try maximum.adding(one)
        }
    }

    @Test func comparesExtremeScalesWithoutAligningLargeCoefficients() {
        let enormous = ExactDecimal(
            coefficient: 1,
            scale: Int32.min
        )
        let tiny = ExactDecimal(
            coefficient: Int128.max,
            scale: Int32.max
        )

        #expect(enormous.compare(to: tiny) == 1)
        #expect(tiny.compare(to: enormous) == -1)
        #expect(enormous.compare(to: enormous) == 0)
    }

    @Test func zeroArithmeticDoesNotExpandExtremeScales() throws {
        let zero = ExactDecimal(coefficient: 0, scale: Int32.max)
        let enormous = ExactDecimal(coefficient: 1, scale: Int32.min)

        #expect(try enormous.adding(zero) == enormous)
        #expect(try enormous.subtracting(zero) == enormous)
        #expect(try enormous.multiplying(by: zero) == zero)
    }

    @Test func multiplicationNormalizesWideProducts() throws {
        let left = ExactDecimal(
            coefficient: 4_611_686_018_427_387_904,
            scale: 0
        )
        let right = ExactDecimal(coefficient: 5, scale: 0)

        #expect(
            try left.multiplying(by: right)
                == ExactDecimal(
                    coefficient: 2_305_843_009_213_693_952,
                    scale: -1
                )
        )
    }

    @Test func divisionUsesTerminatingDecimalFactorsWithoutExpansionOverflow() throws {
        let maximum = ExactDecimal(
            coefficient: Int128.max,
            scale: 0
        )
        let ten = ExactDecimal(coefficient: 10, scale: 0)
        let one = ExactDecimal(coefficient: 1, scale: 0)
        let forty = ExactDecimal(coefficient: 40, scale: 0)

        #expect(
            try maximum.dividing(by: ten)
                == ExactDecimal(
                    coefficient: Int128.max,
                    scale: 1
                )
        )
        #expect(
            try one.dividing(by: forty)
                == ExactDecimal(coefficient: 25, scale: 3)
        )
        #expect(
            throws: ExactDecimalError.numericOverflow
        ) {
            _ = try ExactDecimal(
                coefficient: Int128.min,
                scale: 0
            ).dividing(by: ExactDecimal(coefficient: -1, scale: 0))
        }
    }

    @Test func remainderUsesModularScalingForExtremePowers() throws {
        let positive = ExactDecimal(coefficient: 1, scale: -100)
        let negative = ExactDecimal(coefficient: -1, scale: -100)
        let three = ExactDecimal(coefficient: 3, scale: 0)
        let muchLargerDivisor = ExactDecimal(coefficient: 1, scale: -101)

        #expect(
            try positive.remainder(dividingBy: three)
                == ExactDecimal(coefficient: 1, scale: 0)
        )
        #expect(
            try negative.remainder(dividingBy: three)
                == ExactDecimal(coefficient: -1, scale: 0)
        )
        #expect(
            try positive.remainder(dividingBy: muchLargerDivisor)
                == positive
        )
    }

    @Test func decimalLexicalFormIsFixedPointAndBounded() throws {
        #expect(
            try ExactDecimal(
                coefficient: 123,
                scale: 2
            ).decimalLexicalForm(maximumUTF8Count: 16) == "1.23"
        )
        #expect(
            try ExactDecimal(
                coefficient: -123,
                scale: 5
            ).decimalLexicalForm(maximumUTF8Count: 16) == "-0.00123"
        )
        #expect(
            try ExactDecimal(
                coefficient: 123,
                scale: -2
            ).decimalLexicalForm(maximumUTF8Count: 16) == "12300"
        )

        let large = ExactDecimal(coefficient: 1, scale: 129)
        let lexical = try large.decimalLexicalForm(maximumUTF8Count: 132)
        #expect(lexical.utf8.count == 131)
        #expect(!lexical.contains("e"))
        #expect(
            throws: ExactDecimalLexicalError.representationTooLarge(
                required: 131,
                maximum: 130
            )
        ) {
            _ = try large.decimalLexicalForm(maximumUTF8Count: 130)
        }
    }

    @Test func zeroOrdersBelowEveryPositiveFractionAndAboveEveryNegative() {
        let zero = ExactDecimal(coefficient: 0, scale: 0)
        let halves = [
            ExactDecimal(coefficient: 5, scale: 1),      // 0.5
            ExactDecimal(coefficient: 1, scale: 1),      // 0.1
            ExactDecimal(coefficient: 1, scale: 30),     // 1e-30
            ExactDecimal(coefficient: Int128.max, scale: Int32.max),
        ]
        for positive in halves {
            #expect(zero.compare(to: positive) == -1)
            #expect(positive.compare(to: zero) == 1)
            #expect(zero < positive)
            #expect(!(positive < zero))
        }

        let negatives = [
            ExactDecimal(coefficient: -5, scale: 1),     // -0.5
            ExactDecimal(coefficient: -1, scale: 30),    // -1e-30
            ExactDecimal(coefficient: Int128.min, scale: Int32.min),
        ]
        for negative in negatives {
            #expect(zero.compare(to: negative) == 1)
            #expect(negative.compare(to: zero) == -1)
            #expect(negative < zero)
            #expect(!(zero < negative))
        }

        #expect(zero.compare(to: zero) == 0)
    }
}
