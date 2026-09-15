//
//  ServingAmountUnit.swift
//  MacroPal
//

import Foundation

/// A unit for entering a food or ingredient amount. Shared across every serving-amount
/// picker (Log Food, a new meal's ingredients, an ingredient's own edit screen, and a new
/// food's default serving) rather than duplicated per screen like the app's other small
/// per-file enums — with six cases and exact conversion constants, duplicating this one is
/// a real correctness risk, not just boilerplate.
enum ServingAmountUnit: Hashable, CaseIterable {
    case grams
    case ounces
    case cups
    case tablespoons
    case teaspoons
    /// The food's own named unit (e.g. "medium apple") or, on the "define a new food"
    /// screen, "grams per serving" being defined — either way, its gram equivalent isn't
    /// fixed here; see `fixedGramsPerUnit`.
    case count

    /// Grams in exactly one of this unit, for the units with a fixed, food-independent
    /// conversion — the international avoirdupois ounce (US nutrition labels), and
    /// cups/tablespoons/teaspoons approximated at water density (1 mL ≈ 1 g). That's a
    /// convenience approximation, not each ingredient's real density (a cup of flour and a
    /// cup of water don't weigh the same) — the same simplification most quick-entry
    /// nutrition trackers make when a food's own density isn't known. `nil` for `.count`,
    /// whose gram equivalent depends on context — the caller supplies its own fallback
    /// (a food's `defaultServingSizeG` when logging, or a fixed 1 when defining one).
    var fixedGramsPerUnit: Double? {
        switch self {
        case .grams: return 1
        case .ounces: return 28.349523125
        case .cups: return 236.588
        case .tablespoons: return 14.7868
        case .teaspoons: return 4.92892
        case .count: return nil
        }
    }

    var displayName: String {
        switch self {
        case .grams: return "Grams"
        case .ounces: return "Ounces"
        case .cups: return "Cups"
        case .tablespoons: return "Tbsp"
        case .teaspoons: return "Tsp"
        case .count: return "Serving"
        }
    }

    /// "Amount (g)"-style label for the amount field itself, keyed to this unit.
    var amountFieldLabel: String {
        switch self {
        case .grams: return "Amount (g)"
        case .ounces: return "Amount (oz)"
        case .cups: return "Amount (cups)"
        case .tablespoons: return "Amount (tbsp)"
        case .teaspoons: return "Amount (tsp)"
        case .count: return "Amount"
        }
    }
}

/// Parses a serving-amount string that may be a plain decimal ("1.5"), a simple fraction
/// ("1/2"), or a mixed number ("1 1/2") — so "2/3" or "1 1/2" works the same as typing
/// "0.667" or "1.5". Returns `nil` for anything else, including a zero denominator.
enum AmountParsing {
    static func parseAmount(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        let parts = trimmed.split(separator: " ", maxSplits: 1).map(String.init)
        if parts.count == 2, let whole = Double(parts[0]), let fractional = parseFraction(parts[1]) {
            return whole + fractional
        }

        if let fraction = parseFraction(trimmed) {
            return fraction
        }

        return Double(trimmed)
    }

    private static func parseFraction(_ text: String) -> Double? {
        let components = text.split(separator: "/")
        guard components.count == 2,
              let numerator = Double(components[0]),
              let denominator = Double(components[1]),
              denominator != 0 else { return nil }
        return numerator / denominator
    }
}
