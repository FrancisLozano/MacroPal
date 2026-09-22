//
//  BodyMapCard.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// Front and back figures colored either by how far each muscle has come, from your logged
/// lifts (see `MuscleLevelEngine`), or by how much it's been trained this week (see
/// `WeeklyMuscleVolume`).
struct BodyMapCard: View {
    enum Mode: String, CaseIterable, Identifiable {
        case level, weekly
        var id: Self { self }
        var title: String {
            switch self {
            case .level: "Level"
            case .weekly: "Weekly"
            }
        }
    }

    @Query private var sessions: [WorkoutSession]
    @Query(sort: \WeightEntry.date, order: .reverse) private var weightEntries: [WeightEntry]
    @Query private var profiles: [UserProfile]
    @AppStorage("bodyMapMode") private var mode: Mode = .level

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

    /// Each trained muscle's color in the current mode; untrained muscles are absent.
    private var muscleColors: [Muscle: Color] {
        switch mode {
        case .level:
            MuscleLevelEngine.levels(sets: loggedSets, bodyweightKg: bodyweightKg, sex: profiles.first?.sex ?? .male)
                .mapValues { LevelPalette.color(forLevel: $0) }
        case .weekly:
            WeeklyMuscleVolume.sets(from: loggedSets)
                .mapValues { VolumePalette.color(forBand: WeeklyMuscleVolume.band(forSets: $0)) }
        }
    }

    var body: some View {
        let colors = muscleColors

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Progress")
                    .font(.headline)
                Spacer()
                Picker("Show", selection: $mode) {
                    ForEach(Mode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }

            HStack(spacing: 24) {
                BodyFigure(side: .front, colors: colors)
                BodyFigure(side: .back, colors: colors)
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)

            legend

            Text(caption(hasColors: !colors.isEmpty))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    @ViewBuilder
    private var legend: some View {
        switch mode {
        case .level:
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                ForEach(Array(MuscleLevelEngine.levelNames.enumerated()), id: \.offset) { index, name in
                    legendChip(name, color: LevelPalette.color(forLevel: index + 1), textColor: .white)
                }
            }
        case .weekly:
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                ForEach(Array(WeeklyMuscleVolume.bandNames.enumerated()), id: \.offset) { index, name in
                    legendChip(
                        name,
                        color: VolumePalette.color(forBand: index + 1),
                        textColor: VolumePalette.labelColor(forBand: index + 1)
                    )
                }
            }
        }
    }

    private func legendChip(_ name: String, color: Color, textColor: Color) -> some View {
        Text(name)
            .font(.caption2.bold())
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity, minHeight: 24)
            .background(color, in: RoundedRectangle(cornerRadius: 6))
    }

    private func caption(hasColors: Bool) -> String {
        switch mode {
        case .level:
            if bodyweightKg == nil {
                "Log your weight to see strength levels — muscles you train show as Beginner until then."
            } else if !hasColors {
                "Log a workout and the muscles you train will light up."
            } else {
                "Levels come from your recent lifts against your bodyweight, held back by how long you've trained each muscle."
            }
        case .weekly:
            if !hasColors {
                "Nothing logged yet this week — muscles fill in as you log sets."
            } else {
                "Sets per muscle this week. Main movers count as a full set, assisting muscles as half."
            }
        }
    }
}

#Preview {
    BodyMapCard()
        .modelContainer(for: [WorkoutSession.self, WorkoutSetEntry.self, Exercise.self, WeightEntry.self, UserProfile.self], inMemory: true)
}
