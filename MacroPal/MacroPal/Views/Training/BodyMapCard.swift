//
//  BodyMapCard.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// Front and back figures colored by how far each muscle has come, from your logged lifts
/// (see `MuscleLevelEngine` for how a level is decided).
struct BodyMapCard: View {
    @Query private var sessions: [WorkoutSession]
    @Query(sort: \WeightEntry.date, order: .reverse) private var weightEntries: [WeightEntry]
    @Query private var profiles: [UserProfile]

    private var bodyweightKg: Double? { weightEntries.first?.weightKg }

    private var levels: [Muscle: Int] {
        let sets = sessions.flatMap { session in
            session.setEntries.compactMap { entry -> LoggedSet? in
                guard let exercise = entry.exercise else { return nil }
                return LoggedSet(
                    date: session.date,
                    exerciseName: exercise.name,
                    muscleGroup: exercise.muscleGroup,
                    weightKg: entry.weightKg,
                    reps: entry.reps
                )
            }
        }
        return MuscleLevelEngine.levels(
            sets: sets,
            bodyweightKg: bodyweightKg,
            sex: profiles.first?.sex ?? .male
        )
    }

    var body: some View {
        let levels = levels
        let colors = levels.mapValues { LevelPalette.color(forLevel: $0) }

        VStack(alignment: .leading, spacing: 12) {
            Text("Progress")
                .font(.headline)

            HStack(spacing: 24) {
                BodyFigure(side: .front, colors: colors)
                BodyFigure(side: .back, colors: colors)
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                ForEach(Array(MuscleLevelEngine.levelNames.enumerated()), id: \.offset) { index, name in
                    Text(name)
                        .font(.caption2.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 24)
                        .background(LevelPalette.color(forLevel: index + 1), in: RoundedRectangle(cornerRadius: 6))
                }
            }

            Text(caption(hasLevels: !levels.isEmpty))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private func caption(hasLevels: Bool) -> String {
        if bodyweightKg == nil {
            "Log your weight to see strength levels — muscles you train show as Beginner until then."
        } else if !hasLevels {
            "Log a workout and the muscles you train will light up."
        } else {
            "Levels come from your recent lifts against your bodyweight, held back by how long you've trained each muscle."
        }
    }
}

#Preview {
    BodyMapCard()
        .modelContainer(for: [WorkoutSession.self, WorkoutSetEntry.self, Exercise.self, WeightEntry.self, UserProfile.self], inMemory: true)
}
