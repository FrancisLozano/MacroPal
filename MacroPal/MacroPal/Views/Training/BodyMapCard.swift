//
//  BodyMapCard.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// Front and back figures colored by how far each muscle has come, from your logged lifts
/// (see `MuscleLevelEngine`). The ⓘ explains the level colors and what it takes to move up.
struct BodyMapCard: View {
    @Query private var sessions: [WorkoutSession]
    @Query(sort: \WeightEntry.date, order: .reverse) private var weightEntries: [WeightEntry]
    @Query private var profiles: [UserProfile]
    @State private var isShowingInfo = false

    private var bodyweightKg: Double? { weightEntries.first?.weightKg }

    private var loggedSets: [LoggedSet] {
        sessions.flatMap { session in
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
    }

    /// Each trained muscle's level color; untrained muscles are absent.
    private var muscleColors: [Muscle: Color] {
        MuscleLevelEngine.levels(sets: loggedSets, bodyweightKg: bodyweightKg, sex: profiles.first?.sex ?? .male)
            .mapValues { LevelPalette.color(forLevel: $0) }
    }

    var body: some View {
        let colors = muscleColors

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Progress")
                    .font(.headline)
                Spacer()
                Button {
                    isShowingInfo = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .accessibilityLabel("How levels work")
            }

            HStack(spacing: 24) {
                BodyFigure(side: .front, colors: colors)
                BodyFigure(side: .back, colors: colors)
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)

            if let prompt = prompt(hasColors: !colors.isEmpty) {
                Text(prompt)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .sheet(isPresented: $isShowingInfo) {
            MuscleLevelInfoView()
        }
    }

    /// Only shown when something's missing that the figures can't make obvious on their own.
    private func prompt(hasColors: Bool) -> String? {
        if bodyweightKg == nil {
            "Log your weight to see strength levels — muscles you train show as Beginner until then."
        } else if !hasColors {
            "Log a workout and the muscles you train will light up."
        } else {
            nil
        }
    }
}

#Preview {
    BodyMapCard()
        .modelContainer(for: [WorkoutSession.self, WorkoutSetEntry.self, Exercise.self, WeightEntry.self, UserProfile.self], inMemory: true)
}
