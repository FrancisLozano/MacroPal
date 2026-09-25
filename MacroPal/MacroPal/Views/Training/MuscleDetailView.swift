//
//  MuscleDetailView.swift
//  MacroPal
//

import SwiftUI

/// One muscle from the body map: its level, the volume it has moved with a bar toward the
/// next level, and the exercises that volume came from, biggest first. Reached by tapping a
/// muscle on the map; the title menu switches muscles, for the small ones that are hard to hit.
struct MuscleDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .lb
    @State private var muscle: Muscle

    let sets: [LoggedSet]
    let bodyweightKg: Double?
    let sex: Sex

    init(muscle: Muscle, sets: [LoggedSet], bodyweightKg: Double?, sex: Sex) {
        _muscle = State(initialValue: muscle)
        self.sets = sets
        self.bodyweightKg = bodyweightKg
        self.sex = sex
    }

    var body: some View {
        let progress = MuscleLevelEngine.progress(for: muscle, sets: sets, bodyweightKg: bodyweightKg, sex: sex)

        NavigationStack {
            List {
                Section {
                    summary(progress)
                }

                if progress.contributions.isEmpty {
                    Section {
                        Text("No sets have worked your \(muscle.displayName.lowercased()) yet.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section {
                        ForEach(progress.contributions, id: \.exerciseName) { contribution in
                            row(contribution, total: progress.volumeKg)
                        }
                    } header: {
                        Text("Where it came from")
                    } footer: {
                        Text("A set counts fully toward the muscle it mainly works and partly toward the ones that help.")
                    }
                }
            }
            .navigationTitle(muscle.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarTitleMenu {
                Picker("Muscle", selection: $muscle) {
                    ForEach(Muscle.allCases) { muscle in
                        Text(muscle.displayName).tag(muscle)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Summary

    private func summary(_ progress: MuscleProgress) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            levelLine(progress)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(amount(progress.volumeKg))
                    .font(.title.bold())
                if let next = progress.nextLevelVolumeKg {
                    Text("of \(amount(next)) \(unit.symbol)")
                        .foregroundStyle(.secondary)
                    Spacer()
                    if next > progress.volumeKg {
                        Text("\(amount(next - progress.volumeKg)) \(unit.symbol) to go")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("\(unit.symbol) moved")
                        .foregroundStyle(.secondary)
                }
            }

            if let fraction = progress.fractionToNextLevel {
                ProgressView(value: fraction)
                    .tint(LevelPalette.color(forLevel: progress.level + 1))
            }

            if let note = note(progress) {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    /// "● Novice → Intermediate", or where the muscle stands when there's no next step.
    @ViewBuilder
    private func levelLine(_ progress: MuscleProgress) -> some View {
        if progress.level == 0 {
            Text("Not trained yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            HStack(spacing: 6) {
                Circle()
                    .fill(LevelPalette.color(forLevel: progress.level))
                    .frame(width: 10, height: 10)
                Text(levelName(progress.level))
                if progress.nextLevelVolumeKg != nil {
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(levelName(progress.level + 1))
                        .foregroundStyle(.secondary)
                }
            }
            .font(.subheadline.weight(.semibold))
            .accessibilityElement(children: .combine)
        }
    }

    /// What else the next level needs, or why there's no bar.
    private func note(_ progress: MuscleProgress) -> String? {
        let date = progress.nextLevelUnlocks?.formatted(.dateTime.month(.abbreviated).day())
        if progress.fractionToNextLevel != nil {
            let next = levelName(progress.level + 1)
            switch (progress.fractionToNextLevel == 1, date) {
            case (true, let date?): return "Volume reached. \(next) also takes time: it unlocks \(date)."
            case (false, let date?): return "\(next) also needs training until \(date)."
            default: return nil
            }
        }
        if progress.level == MuscleLevelEngine.levelNames.count { return "World Class, the top level." }
        if progress.level > 0 && bodyweightKg == nil { return "Log your weight to see how far the next level is." }
        if progress.level == 0 { return "Log a set that works it and it starts at Beginner." }
        return nil
    }

    // MARK: - Rows

    private func row(_ contribution: MuscleContribution, total: Double) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(contribution.exerciseName)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(amount(contribution.volumeKg)) \(unit.symbol)")
                    .fontWeight(.semibold)
                Text("\(Int((contribution.volumeKg / total * 100).rounded()))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    private func levelName(_ level: Int) -> String {
        MuscleLevelEngine.levelNames[level - 1]
    }

    /// Whole pounds or kilograms, "12,480".
    private func amount(_ kg: Double) -> String {
        unit.fromKg(kg).formatted(.number.precision(.fractionLength(0)))
    }
}

#Preview {
    let now = Date.now
    let sets = (0..<12).map { index in
        LoggedSet(date: now.addingTimeInterval(-Double(index) * 2 * 86_400), exerciseName: "Back Squat",
                  muscleGroup: .legs, weightKg: 80, reps: 8)
    }
    return Text("Body map")
        .sheet(isPresented: .constant(true)) {
            MuscleDetailView(muscle: .quads, sets: sets, bodyweightKg: 80, sex: .male)
        }
}
