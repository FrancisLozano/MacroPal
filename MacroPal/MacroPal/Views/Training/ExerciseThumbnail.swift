//
//  ExerciseThumbnail.swift
//  MacroPal
//

import SwiftUI

/// Front and back figures with the muscles an exercise works highlighted — solid for the
/// main movers, lighter for assisting muscles.
struct ExerciseThumbnail: View {
    let exercise: Exercise?

    private static let highlight = LevelPalette.color(forLevel: 1)

    private var colors: [Muscle: Color] {
        guard let exercise else { return [:] }
        return Self.colors(for: ExerciseMuscleData.profile(forName: exercise.name, group: exercise.muscleGroup))
    }

    /// Primary muscles solid, secondary light — shared with the exercise screen's Overview.
    static func colors(for profile: ExerciseProfile) -> [Muscle: Color] {
        var colors: [Muscle: Color] = [:]
        for muscle in profile.secondaryMuscles { colors[muscle] = secondaryColor }
        for muscle in profile.primaryMuscles { colors[muscle] = primaryColor }
        return colors
    }

    static let primaryColor = highlight
    static let secondaryColor = highlight.opacity(0.45)

    var body: some View {
        HStack(spacing: 2) {
            BodyFigure(side: .front, colors: colors)
            BodyFigure(side: .back, colors: colors)
        }
        .padding(5)
        .frame(width: 64, height: 64)
        .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 10))
    }
}
