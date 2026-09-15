//
//  AmountParsingTests.swift
//  MacroPalTests
//

import Testing
@testable import MacroPal

struct AmountParsingTests {
    @Test func parsesPlainDecimal() {
        #expect(AmountParsing.parseAmount("1.5") == 1.5)
        #expect(AmountParsing.parseAmount("100") == 100)
    }

    @Test func parsesSimpleFraction() {
        #expect(AmountParsing.parseAmount("1/2") == 0.5)
        #expect(AmountParsing.parseAmount("2/3") == 2.0 / 3.0)
    }

    @Test func parsesMixedNumber() {
        #expect(AmountParsing.parseAmount("1 1/2") == 1.5)
        #expect(AmountParsing.parseAmount("2 3/4") == 2.75)
    }

    @Test func rejectsZeroDenominator() {
        #expect(AmountParsing.parseAmount("1/0") == nil)
    }

    @Test func rejectsEmptyOrGarbage() {
        #expect(AmountParsing.parseAmount("") == nil)
        #expect(AmountParsing.parseAmount("   ") == nil)
        #expect(AmountParsing.parseAmount("abc") == nil)
    }

    @Test func fixedGramsPerUnitConversions() {
        #expect(ServingAmountUnit.grams.fixedGramsPerUnit == 1)
        #expect(ServingAmountUnit.ounces.fixedGramsPerUnit == 28.349523125)
        #expect(ServingAmountUnit.cups.fixedGramsPerUnit == 236.588)
        #expect(ServingAmountUnit.tablespoons.fixedGramsPerUnit == 14.7868)
        #expect(ServingAmountUnit.teaspoons.fixedGramsPerUnit == 4.92892)
        #expect(ServingAmountUnit.count.fixedGramsPerUnit == nil)
    }
}
