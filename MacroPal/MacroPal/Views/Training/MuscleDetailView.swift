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
    let prior: PriorTraining?

    init(muscle: Muscle, sets: [LoggedSet], bodyweightKg: Double?, sex: Sex, prior: PriorTraining? = nil) {
        _muscle = State(initialValue: muscle)
        self.sets = sets
        self.bodyweightKg = bodyweightKg
        self.sex = sex
        self.prior = prior
    }

    var body: some View {
        let progress = MuscleLevelEngine.progress(for: muscle, sets: sets, bodyweightKg: bodyweightKg, sex: sex, prior: prior)

        NavigationStack {
            List {
                Section {
                    MuscleLevelSummary(progress: progress, hasBodyweight: bodyweightKg != nil)
                        .padding(.vertical, 4)
                }

                if progress.contributions.isEmpty && progress.priorVolumeKg == 0 {
                    Section {
                        Text("No sets have worked your \(muscle.displayName.lowercased()) yet.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section {
                        if let prior, progress.priorVolumeKg > 0 {
                            priorRow(prior, volumeKg: progress.priorVolumeKg, total: progress.volumeKg)
                        }
                        ForEach(progress.contributions, id: \.exerciseName) { contribution in
                            row(contribution, total: progress.volumeKg)
                        }
                    } header: {
                        Text("Where it came from")
                    } footer: {
                        Text("A set counts fully toward the muscle it mainly works and partly toward the ones that help. Any share at all counts as training the muscle.")
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

    // MARK: - Rows

    private func row(_ contribution: MuscleContribution, total: Double) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(contribution.exerciseName)
                Text(role(contribution))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
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

    /// Past training, credited as a lump: "Before MacroPal · 18 months".
    private func priorRow(_ prior: PriorTraining, volumeKg: Double, total: Double) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Before MacroPal")
                Text("Past training · \(prior.months) \(prior.months == 1 ? "month" : "months")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(amount(volumeKg)) \(unit.symbol)")
                    .fontWeight(.semibold)
                Text("\(Int((volumeKg / total * 100).rounded()))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    /// "Primary", or "Secondary · 40% of each set" for an assist.
    private func role(_ contribution: MuscleContribution) -> String {
        if contribution.isPrimary && contribution.involvement >= 1 { return "Primary" }
        let share = "\(Int((contribution.involvement * 100).rounded()))% of each set"
        return "\(contribution.isPrimary ? "Primary" : "Secondary") · \(share)"
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
