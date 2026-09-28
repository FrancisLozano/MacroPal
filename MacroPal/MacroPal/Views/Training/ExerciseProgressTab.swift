//
//  ExerciseProgressTab.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// The exercise screen's Progress tab, measured in volume (weight × reps, summed): the total
/// moved on this exercise and this week against last, the level of each muscle it mainly works
/// (from every exercise, as on the body map; tap one for its detail), volume per session as a
/// chart, then every session's sets. Swiping a day deletes that day's sets of this exercise.
/// 1RM isn't shown — volume is what the user tracks (usability.md, 2026-09-23).
struct ExerciseProgressTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \WeightEntry.date, order: .reverse) private var weightEntries: [WeightEntry]
    @Query private var profiles: [UserProfile]
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .lb

    let exercise: Exercise

    @State private var selectedMuscle: Muscle?

    private let viewModel = WorkoutProgressViewModel()

    private var bodyweightKg: Double? { weightEntries.first?.weightKg }
    private var sex: Sex { profiles.first?.sex ?? .male }
    private var prior: PriorTraining? { profiles.first?.priorTraining }

    var body: some View {
        let history = viewModel.history(for: exercise, in: sessions, bodyweightKg: bodyweightKg)
        let sets = LoggedSet.all(in: sessions)

        List {
            if history.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Sets Yet",
                        systemImage: "chart.bar",
                        description: Text("Log a set on the Workout tab to start tracking this exercise.")
                    )
                }
            } else {
                Section {
                    summary(viewModel.volumeSummary(history))
                } footer: {
                    Text("Volume is weight × reps, added up over every set — both dumbbells, and part of your bodyweight for moves like pull-ups, as on the body map.")
                }
            }

            muscleLevels(sets)

            if !history.isEmpty {
                Section {
                    ExerciseVolumeChart(days: history)
                } header: {
                    Text("Volume per Session")
                } footer: {
                    Text("Tap a bar to see that session.")
                }
                Section("History") {
                    ForEach(history) { day in
                        historyRow(day)
                            .swipeActions {
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    day.sets.forEach(modelContext.delete)
                                }
                            }
                    }
                }
            }
        }
        .sheet(item: $selectedMuscle) { muscle in
            MuscleDetailView(muscle: muscle, sets: sets, bodyweightKg: bodyweightKg, sex: sex, prior: prior)
        }
    }

    /// Each primary muscle's level, from every set that works it — not just this exercise's.
    @ViewBuilder
    private func muscleLevels(_ sets: [LoggedSet]) -> some View {
        let muscles = ExerciseMuscleData.profile(forName: exercise.name, group: exercise.muscleGroup).primaryMuscles
        if !muscles.isEmpty {
            Section {
                ForEach(muscles) { muscle in
                    Button {
                        selectedMuscle = muscle
                    } label: {
                        muscleRow(muscle, progress: MuscleLevelEngine.progress(for: muscle, sets: sets, bodyweightKg: bodyweightKg, sex: sex, prior: prior))
                    }
                    .foregroundStyle(.primary)
                }
            } header: {
                Text(muscles.count == 1 ? "Muscle Level" : "Muscle Levels")
            } footer: {
                Text("Counts every exercise that works the muscle, as on the body map.")
            }
        }
    }

    private func muscleRow(_ muscle: Muscle, progress: MuscleProgress) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(muscle.displayName)
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            MuscleLevelSummary(progress: progress, hasBodyweight: bodyweightKg != nil)
        }
        .padding(.vertical, 4)
        .accessibilityHint("Shows where this muscle's volume came from.")
    }

    /// "Total volume 12,480 lb", then this week against last.
    private func summary(_ volume: VolumeSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Total volume")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(unit.formattedLift(fromKg: volume.totalKg))
                        .font(.title.bold())
                    Text(unit.symbol)
                        .foregroundStyle(.secondary)
                }
            }
            HStack(alignment: .top) {
                weekColumn("This week", kg: volume.thisWeekKg)
                weekColumn("Last week", kg: volume.lastWeekKg)
                Spacer(minLength: 0)
                if let change = weekChange(volume) {
                    Text(change)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(volume.thisWeekKg >= volume.lastWeekKg ? .green : .secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func weekColumn(_ title: String, kg: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(unit.formattedLift(fromKg: kg)) \(unit.symbol)")
                .font(.subheadline.weight(.semibold))
        }
        .frame(minWidth: 100, alignment: .leading)
    }

    /// "+18%" against last week; nil when there was nothing last week to compare to.
    private func weekChange(_ volume: VolumeSummary) -> String? {
        guard volume.lastWeekKg > 0 else { return nil }
        let percent = Int(((volume.thisWeekKg / volume.lastWeekKg - 1) * 100).rounded())
        return percent >= 0 ? "+\(percent)%" : "−\(-percent)%"
    }

    private func setsLine(_ sets: [WorkoutSetEntry]) -> String {
        if exercise.isBodyweight {
            return sets.map { String($0.reps) }.joined(separator: ", ") + " reps"
        }
        return sets.map { "\(unit.formattedLift(fromKg: $0.weightKg)) × \($0.reps)" }.joined(separator: ", ")
    }

    /// "Sep 20 · Legs & Abs", each set as "135 × 10" (as logged; "12, 12, 10 reps" for a
    /// bodyweight move), and the day's volume.
    private func historyRow(_ day: ExerciseHistoryDay) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(day.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                    .font(.headline)
                if let planDayName = day.planDayName {
                    Text(planDayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(unit.formattedLift(fromKg: day.volumeKg)) \(unit.symbol)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Volume \(unit.formattedLift(fromKg: day.volumeKg)) \(unit.symbol)")
            }
            Text(setsLine(day.sets))
                .font(.subheadline)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    let container = try! ModelContainer(
        for: WorkoutSession.self, WorkoutSetEntry.self, Exercise.self, WeightEntry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let squat = Exercise(name: "Back Squat", muscleGroup: .legs, equipment: "Barbell")
    container.mainContext.insert(squat)
    return NavigationStack {
        ExerciseProgressTab(exercise: squat)
    }
    .modelContainer(container)
}
