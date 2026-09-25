//
//  BodyMapCard.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// Front and back figures colored by how far each muscle has come — the volume it has moved
/// over time against your bodyweight (see `MuscleLevelEngine`). The ⓘ explains the level colors and what it takes to move up;
/// tapping a muscle opens its detail — volume, the exercises behind it, the way to the next level.
struct BodyMapCard: View {
    @Query private var sessions: [WorkoutSession]
    @Query(sort: \WeightEntry.date, order: .reverse) private var weightEntries: [WeightEntry]
    @Query private var profiles: [UserProfile]
    @State private var isShowingInfo = false
    @State private var selectedMuscle: Muscle?

    private var bodyweightKg: Double? { weightEntries.first?.weightKg }
    private var sex: Sex { profiles.first?.sex ?? .male }

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
    private func muscleColors(for sets: [LoggedSet]) -> [Muscle: Color] {
        MuscleLevelEngine.levels(sets: sets, bodyweightKg: bodyweightKg, sex: sex)
            .mapValues { LevelPalette.color(forLevel: $0) }
    }

    var body: some View {
        let sets = loggedSets
        let colors = muscleColors(for: sets)

        TrainingSection("Progress") {
            Button {
                isShowingInfo = true
            } label: {
                Image(systemName: "info.circle")
            }
            .accessibilityLabel("How levels work")
        } content: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 24) {
                    BodyFigure(side: .front, colors: colors) { selectedMuscle = $0 }
                    BodyFigure(side: .back, colors: colors) { selectedMuscle = $0 }
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                // The figures are drawings; VoiceOver gets one element that opens the detail,
                // whose title menu picks the muscle.
                .accessibilityElement()
                .accessibilityLabel("Body map")
                .accessibilityHint("Shows each muscle's volume and progress to its next level.")
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { selectedMuscle = colors.keys.sorted { $0.displayName < $1.displayName }.first ?? .chest }

                if let prompt = prompt(hasColors: !colors.isEmpty) {
                    Text(prompt)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .sheet(isPresented: $isShowingInfo) {
            MuscleLevelInfoView()
        }
        .sheet(item: $selectedMuscle) { muscle in
            MuscleDetailView(muscle: muscle, sets: sets, bodyweightKg: bodyweightKg, sex: sex)
        }
    }

    /// Only shown when something's missing that the figures can't make obvious on their own.
    private func prompt(hasColors: Bool) -> String? {
        if bodyweightKg == nil {
            "Log your weight to see levels — muscles you train show as Beginner until then."
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
