//
//  WeightUnit.swift
//  MacroPal
//

import Foundation

/// Display unit for body weight. Everything is still stored in kg; views convert at the edges.
enum WeightUnit: String, CaseIterable, Identifiable {
    case lb, kg

    static let storageKey = "weightUnit"

    /// The saved preference, for code that can't use `@AppStorage` (e.g. `State` initializers).
    static var stored: WeightUnit {
        UserDefaults.standard.string(forKey: storageKey).flatMap(WeightUnit.init(rawValue:)) ?? .lb
    }

    var id: Self { self }

    var symbol: String { rawValue }

    private static let kgPerLb = 0.45359237

    func fromKg(_ kg: Double) -> Double {
        self == .kg ? kg : kg / Self.kgPerLb
    }

    func toKg(_ value: Double) -> Double {
        self == .kg ? value : value * Self.kgPerLb
    }

    /// Lift weights, trailing ".0" dropped: "135", "62.5".
    func formattedLift(fromKg kg: Double) -> String {
        fromKg(kg).formatted(.number.precision(.fractionLength(0...1)))
    }

    /// e.g. "154.3" — one decimal, no unit symbol.
    func formatted(fromKg kg: Double) -> String {
        fromKg(kg).formatted(.number.precision(.fractionLength(1)))
    }
}
