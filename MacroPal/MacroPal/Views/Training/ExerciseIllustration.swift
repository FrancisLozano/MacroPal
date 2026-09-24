//
//  ExerciseIllustration.swift
//  MacroPal
//

import SwiftUI
import UIKit

/// A line drawing of an exercise's start and end positions, side by side, above the sets on
/// the Workout tab. The drawings are Everkinetic's (CC BY-SA 4.0 — credited in Profile →
/// Acknowledgements), converted to template images so the lines take the text color in light
/// and dark mode. 33 of the 38 starter exercises have one; the rest, and exercises you create,
/// show nothing.
struct ExerciseIllustration: View {
    let start: String
    let end: String

    /// Nil when there's no drawing for this exercise.
    init?(exerciseName: String) {
        let slug = Self.slug(for: exerciseName)
        start = "exercise-\(slug)-start"
        end = "exercise-\(slug)-end"
        guard UIImage(named: start) != nil, UIImage(named: end) != nil else { return nil }
    }

    /// "One-Arm Dumbbell Row" → "one-arm-dumbbell-row", the asset names' middle part.
    static func slug(for name: String) -> String {
        name.lowercased()
            .map { $0.isLetter || $0.isNumber ? String($0) : "-" }
            .joined()
    }

    var body: some View {
        HStack(spacing: 16) {
            drawing(start)
            Image(systemName: "arrow.right")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
            drawing(end)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 170)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement()
        .accessibilityLabel("Drawing of the start and end positions")
    }

    private func drawing(_ name: String) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .foregroundStyle(.primary)
    }
}
