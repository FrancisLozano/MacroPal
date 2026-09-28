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
    private var prior: PriorTraining? { profiles.first?.priorTraining }

    var body: some View {
        let sets = LoggedSet.all(in: sessions)
        let levels = MuscleLevelEngine.levels(sets: sets, bodyweightKg: bodyweightKg, sex: sex, prior: prior)
        let colors = levels.mapValues { LevelPalette.color(forLevel: $0) }

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
                // The figures are drawings; VoiceOver gets one element that reads every level
                // and opens the detail, whose title menu picks the muscle.
                .accessibilityElement()
                .accessibilityLabel("Body map")
                .accessibilityValue(Self.spokenLevels(levels))
                .accessibilityHint("Shows each muscle's volume and progress to its next level.")
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { selectedMuscle = colors.keys.sorted { $0.displayName < $1.displayName }.first ?? .chest }

                if let prompt = prompt(hasColors: !colors.isEmpty) {
                    Text(prompt)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let summary = Self.summary(levels) {
                    // The colors in words, so the map doesn't depend on the ⓘ legend.
                    Text(summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .accessibilityHidden(true)
                }
            }
            .padding()
        }
        .sheet(isPresented: $isShowingInfo) {
            MuscleLevelInfoView()
        }
        .sheet(item: $selectedMuscle) { muscle in
            MuscleDetailView(muscle: muscle, sets: sets, bodyweightKg: bodyweightKg, sex: sex, prior: prior)
        }
    }

    /// The highest level reached and which muscles hold it: "Novice: Chest, Quads, +2 more",
    /// or "All 13 trained muscles are Beginner" when they're level.
    static func summary(_ levels: [Muscle: Int]) -> String? {
        guard let top = levels.values.max() else { return nil }
        let name = MuscleLevelEngine.levelNames[top - 1]
        if levels.values.allSatisfy({ $0 == top }) {
            return levels.count == 1
                ? "\(levels.keys.first!.displayName) is \(name)"
                : "All \(levels.count) trained muscles are \(name)"
        }
        let leaders = muscles(at: top, in: levels)
        let shown = leaders.prefix(3).map(\.displayName).joined(separator: ", ")
        let more = leaders.count > 3 ? ", +\(leaders.count - 3) more" : ""
        return "\(name): \(shown)\(more)"
    }

    /// Every level for VoiceOver, highest first: "Novice: Chest, Quads. Beginner: Abs, Biceps.
    /// Not trained: Calves."
    static func spokenLevels(_ levels: [Muscle: Int]) -> String {
        guard !levels.isEmpty else { return "No muscles trained yet" }
        var parts = Set(levels.values).sorted(by: >).map { level in
            let names = muscles(at: level, in: levels).map(\.displayName).joined(separator: ", ")
            return "\(MuscleLevelEngine.levelNames[level - 1]): \(names)"
        }
        let untrained = Muscle.allCases.filter { levels[$0] == nil }
        if !untrained.isEmpty {
            parts.append("Not trained: " + untrained.map(\.displayName).joined(separator: ", "))
        }
        return parts.joined(separator: ". ")
    }

    /// Muscles at `level`, head to toe (the enum's order).
    private static func muscles(at level: Int, in levels: [Muscle: Int]) -> [Muscle] {
        Muscle.allCases.filter { levels[$0] == level }
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
