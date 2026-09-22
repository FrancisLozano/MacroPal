//
//  ExerciseProgressView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// One exercise's progress: the best estimated 1RM and how it's changed, how far it is to the
/// next strength level (see `LiftStandard`), and the history charted against that target.
struct ExerciseProgressView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \WeightEntry.date, order: .reverse) private var weightEntries: [WeightEntry]
    @Query private var profiles: [UserProfile]
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .lb

    @State private var selectedExercise: Exercise?

    private let viewModel = WorkoutProgressViewModel()

    private var loggedExercises: [Exercise] {
        viewModel.loggedExercises(from: sessions)
    }

    private var bodyweightKg: Double? { weightEntries.first?.weightKg }

    var body: some View {
        Group {
            if loggedExercises.isEmpty {
                ContentUnavailableView(
                    "No Workout Data",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Log a session to start tracking progress.")
                )
            } else {
                List {
                    Section {
                        Picker("Exercise", selection: $selectedExercise) {
                            ForEach(loggedExercises) { exercise in
                                Text(exercise.name).tag(Optional(exercise))
                            }
                        }
                    }
                    if let selectedExercise {
                        let points = viewModel.progression(for: selectedExercise, in: sessions)
                        if let best = points.map(\.estimated1RM).max() {
                            let standard = LiftStandard.evaluate(
                                exerciseName: selectedExercise.name,
                                group: selectedExercise.muscleGroup,
                                oneRepMaxKg: best,
                                bodyweightKg: bodyweightKg,
                                sex: profiles.first?.sex ?? .male
                            )
                            Section {
                                summary(points: points, best: best)
                                levelProgress(standard: standard, best: best, exercise: selectedExercise)
                            } footer: {
                                if standard != nil {
                                    Text("Levels use the same bodyweight standards as the body map, which can show a muscle lower until you've trained it for a while.")
                                }
                            }
                            Section {
                                WorkoutProgressChart(points: points, target: chartTarget(standard))
                                    .id(selectedExercise.persistentModelID) // clears a selection on switching
                            } header: {
                                Text("Estimated 1RM")
                            } footer: {
                                Text("Your best set each session, estimated with the Epley formula. Tap the chart to see a session.")
                            }
                        } else {
                            Text("No logged sets for this exercise.")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Exercise Progress")
        .onAppear {
            if selectedExercise == nil {
                selectedExercise = viewModel.mostRecentlyLoggedExercise(from: sessions) ?? loggedExercises.first
            }
        }
    }

    // MARK: - Summary

    private func summary(points: [ExerciseProgressPoint], best: Double) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Best estimated 1RM")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(unit.formattedLift(fromKg: best))
                        .font(.title.bold())
                    Text(unit.symbol)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let change = changeText(points: points, best: best) {
                Text(change)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    /// "+12 lb since Aug 3", or nil with a single session (nothing to compare yet).
    private func changeText(points: [ExerciseProgressPoint], best: Double) -> String? {
        guard points.count > 1, let first = points.first else { return nil }
        let delta = unit.fromKg(best) - unit.fromKg(first.estimated1RM)
        let amount = unit.formattedLift(fromKg: unit.toKg(abs(delta)))
        let sign = delta > 0 ? "+" : delta < 0 ? "−" : "±"
        return "\(sign)\(amount) \(unit.symbol)\nsince \(first.date.formatted(.dateTime.month(.abbreviated).day()))"
    }

    // MARK: - Level progress

    @ViewBuilder
    private func levelProgress(standard: LiftStandard?, best: Double, exercise: Exercise) -> some View {
        if let standard, let nextKg = standard.nextLevelKg {
            let nextLevel = standard.level + 1
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    levelChip(level: standard.level)
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    levelChip(level: nextLevel)
                    Spacer()
                }
                ProgressView(value: standard.progress(oneRepMaxKg: best))
                    .tint(LevelPalette.color(forLevel: nextLevel))
                HStack {
                    Text("\(unit.formattedLift(fromKg: best)) of \(unit.formattedLift(fromKg: nextKg)) \(unit.symbol)")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("\(unit.formattedLift(fromKg: nextKg - best)) \(unit.symbol) to go")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text(targetExplanation(nextLevel: nextLevel, nextKg: nextKg, exercise: exercise))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        } else if let standard {
            HStack(spacing: 8) {
                levelChip(level: standard.level)
                Text("The top of the standard for this lift.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } else if bodyweightKg == nil {
            Text("Log your weight to see how this lift compares to strength standards.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            Text("Bodyweight movements have no strength standard — the chart tracks your progress on its own.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    /// "Intermediate starts at an estimated 1RM of 1.5× your bodyweight." Dumbbell lifts are
    /// stated across both dumbbells, since the target weight shown is per dumbbell.
    private func targetExplanation(nextLevel: Int, nextKg: Double, exercise: Exercise) -> String {
        let name = MuscleLevelEngine.levelNames[nextLevel - 1]
        guard let bodyweightKg else { return "" }
        let profile = ExerciseMuscleData.profile(forName: exercise.name, group: exercise.muscleGroup)
        let multiple = (nextKg * profile.loadScale / bodyweightKg).formatted(.number.precision(.fractionLength(0...2)))
        if profile.loadScale == 2 {
            return "\(name) starts at \(multiple)× your bodyweight across both dumbbells."
        }
        return "\(name) starts at an estimated 1RM of \(multiple)× your bodyweight."
    }

    private func levelChip(level: Int) -> some View {
        let isRanked = level >= 1
        return Text(isRanked ? MuscleLevelEngine.levelNames[level - 1] : "Unranked")
            .font(.caption2.bold())
            .foregroundStyle(isRanked ? Color.white : Color.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                isRanked ? LevelPalette.color(forLevel: level) : Color(.tertiarySystemFill),
                in: RoundedRectangle(cornerRadius: 6)
            )
    }

    private func chartTarget(_ standard: LiftStandard?) -> WorkoutProgressChart.Target? {
        guard let standard, let nextKg = standard.nextLevelKg else { return nil }
        return .init(name: MuscleLevelEngine.levelNames[standard.level], weightKg: nextKg)
    }
}

#Preview {
    NavigationStack {
        ExerciseProgressView()
    }
    .modelContainer(for: [WorkoutSession.self, WorkoutSetEntry.self, Exercise.self, WeightEntry.self, UserProfile.self], inMemory: true)
}
