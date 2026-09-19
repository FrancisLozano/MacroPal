//
//  ExerciseLogCard.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// One planned exercise with its sets logged today and a single weight × reps row to log the
/// next one. The row is prefilled from your last set of this exercise, so repeating a set is
/// one tap.
struct ExerciseLogCard: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .lb

    let planExercise: PlanExercise
    /// Newest-first, shared from the parent so each card doesn't run its own query.
    let sessions: [WorkoutSession]
    let onRemove: () -> Void

    @State private var weightText = ""
    @State private var repsText = ""
    @FocusState private var focusedField: Field?

    private enum Field { case weight, reps }

    private let viewModel = WorkoutViewModel()

    private var exercise: Exercise? { planExercise.exercise }

    private var todaysSets: [WorkoutSetEntry] {
        guard let exercise,
              let session = sessions.first(where: { Calendar.current.isDateInToday($0.date) })
        else { return [] }
        return session.setEntries
            .filter { $0.exercise == exercise }
            .sorted { $0.setNumber < $1.setNumber }
    }

    private var canLog: Bool {
        guard let weight = Double(weightText), let reps = Int(repsText) else { return false }
        return exercise != nil && weight >= 0 && reps > 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise?.name ?? "Unknown exercise")
                        .font(.headline)
                    Text("Target \(planExercise.targetSets) × \(planExercise.targetReps)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(todaysSets.count)/\(planExercise.targetSets)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(todaysSets.count >= planExercise.targetSets ? Color.green : Color.secondary)
            }

            ForEach(Array(todaysSets.enumerated()), id: \.element.persistentModelID) { index, set in
                HStack {
                    Text("Set \(index + 1)")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(unit.formattedLift(fromKg: set.weightKg)) \(unit.symbol) × \(set.reps)")
                }
                .font(.subheadline)
                .contextMenu {
                    Button("Delete Set", role: .destructive) {
                        modelContext.delete(set)
                    }
                }
            }

            HStack(spacing: 8) {
                TextField("0", text: $weightText)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .weight)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                Text(unit.symbol)
                    .foregroundStyle(.secondary)
                Text("×")
                    .foregroundStyle(.secondary)
                TextField("reps", text: $repsText)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .reps)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                Button("Log", action: logSet)
                    .buttonStyle(.borderedProminent)
                    .disabled(!canLog)
            }
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
        .contextMenu {
            Button("Remove from Plan", role: .destructive, action: onRemove)
        }
        .onAppear(perform: prefill)
    }

    /// Weight/reps from the last set of this exercise (today's or any earlier session), else
    /// the plan's target reps with an empty weight.
    private func prefill() {
        guard weightText.isEmpty, repsText.isEmpty else { return }
        if let exercise, let last = WorkoutViewModel.lastSet(for: exercise, in: sessions) {
            weightText = unit.formattedLift(fromKg: last.weightKg)
            repsText = String(last.reps)
        } else {
            repsText = String(planExercise.targetReps)
        }
    }

    private func logSet() {
        guard let exercise, let weight = Double(weightText), let reps = Int(repsText) else { return }
        viewModel.logSet(exercise: exercise, weightKg: unit.toKg(weight), reps: reps, context: modelContext)
        focusedField = nil
    }
}
