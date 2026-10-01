//
//  Appearance.swift
//  MacroPal
//

import SwiftUI

/// Light, dark, or follow the phone. A device preference, like `WeightUnit`, so it lives in
/// `@AppStorage` rather than on `UserProfile`.
enum Appearance: String, CaseIterable, Identifiable {
    case automatic, light, dark

    static let storageKey = "appearance"

    var id: Self { self }

    var displayName: String {
        switch self {
        case .automatic: "Automatic"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    /// `nil` hands the choice back to the system.
    var colorScheme: ColorScheme? {
        switch self {
        case .automatic: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
