//
//  HeightUnit.swift
//  MacroPal
//

import Foundation

/// Display unit for height. `UserProfile.heightCm` is always stored in cm; this only changes
/// how it's shown and entered.
enum HeightUnit: String, CaseIterable, Identifiable {
    case cm, feetInches

    static let storageKey = "heightUnit"

    var id: Self { self }

    var displayName: String {
        switch self {
        case .cm: "cm"
        case .feetInches: "ft/in"
        }
    }

    private static let cmPerInch = 2.54

    /// Whole feet and the leftover inches (rounded to the nearest inch), e.g. 170 cm → 5 ft 7 in.
    static func feetAndInches(fromCm cm: Double) -> (feet: Int, inches: Int) {
        let totalInches = Int((cm / cmPerInch).rounded())
        return (totalInches / 12, totalInches % 12)
    }

    static func cm(feet: Int, inches: Int) -> Double {
        Double(feet * 12 + inches) * cmPerInch
    }

    /// "170 cm" or "5′7″".
    func formatted(cm: Double) -> String {
        switch self {
        case .cm:
            return "\(cm.formatted(.number.precision(.fractionLength(0...1)))) cm"
        case .feetInches:
            let (feet, inches) = Self.feetAndInches(fromCm: cm)
            return "\(feet)′\(inches)″"
        }
    }
}
