//
//  ExerciseTrackView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// Track one exercise's sets for today. Each row is a set: reps × weight, how heavy that is
/// against your best estimated 1RM, and a check to log it. Rows start prefilled from your last
/// set so a repeat set is a single tap.
struct ExerciseTrackView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .lb
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    let planExercise: PlanExercise

    @State private var rows: [SetRow] = []
    @FocusState private var isEditing: Bool

    private let viewModel = WorkoutViewModel()

    struct SetRow: Identifiable {
        let id = UUID()
        var weightText: String
        var repsText: String
        /// Non-nil once the set is logged; unchecking deletes it.
        var entry: WorkoutSetEntry?
    }

    private var exercise: Exercise? { planExercise.exercise }

    private var referenceKg: Double? {
        guard let exercise else { return nil }
        return WorkoutViewModel.bestEstimated1RMKg(for: exercise, in: sessions)
    }

    private var loggedCount: Int {
        rows.filter { $0.entry != nil }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                header
                ForEach($rows) { $row in
                    setRow($row, number: (rows.firstIndex { $0.id == row.id } ?? 0) + 1)
                }
                Button {
                    rows.append(blankRow())
                } label: {
                    Label("Add Set", systemImage: "plus")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(exercise?.name ?? "Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: buildRows)
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text(exercise?.name ?? "Unknown exercise")
                .font(.title3.bold())
                .multilineTextAlignment(.center)
            Text("Sets: \(planExercise.targetSets)  ·  \(loggedCount) done")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14))
    }

    private func setRow(_ row: Binding<SetRow>, number: Int) -> some View {
        let isLogged = row.wrappedValue.entry != nil
        return HStack(spacing: 10) {
            Text("\(number)")
                .font(.title3.bold())
                .frame(width: 32, height: 40)
                .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    TextField("0", text: row.repsText)
                        .keyboardType(.numberPad)
                        .frame(width: 34)
                    Text("reps ×")
                        .foregroundStyle(.secondary)
                    TextField("0", text: row.weightText)
                        .keyboardType(.decimalPad)
                        .frame(width: 56)
                    Text(unit.symbol)
                        .foregroundStyle(.secondary)
                }
                .focused($isEditing)
                .multilineTextAlignment(.trailing)
                .disabled(isLogged)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 8))

                intensityBar(for: row.wrappedValue)
            }

            Spacer(minLength: 0)

            Button {
                toggle(row)
            } label: {
                Image(systemName: isLogged ? "checkmark.circle.fill" : "checkmark.circle")
                    .font(.title)
                    .foregroundStyle(isLogged ? Color.green : Color.secondary)
            }
            .buttonStyle(.plain)
            .disabled(!isLogged && !isValid(row.wrappedValue))
            .accessibilityLabel(isLogged ? "Unlog set \(number)" : "Log set \(number)")
        }
        .padding(12)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14))
    }

    /// "30% of 130 lb" with a colored bar; hidden until there's a logged history to compare to.
    @ViewBuilder
    private func intensityBar(for row: SetRow) -> some View {
        if let referenceKg, let weight = Double(row.weightText), weight > 0 {
            let fraction = unit.toKg(weight) / referenceKg
            VStack(alignment: .leading, spacing: 3) {
                Text("\(Int((fraction * 100).rounded()))% of \(unit.formattedLift(fromKg: referenceKg)) \(unit.symbol)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ProgressView(value: min(fraction, 1))
                    .tint(intensityColor(fraction))
            }
        }
    }

    private func intensityColor(_ fraction: Double) -> Color {
        switch fraction {
        case ..<0.4: .green
        case ..<0.6: .yellow
        case ..<0.8: .orange
        default: .red
        }
    }

    private func isValid(_ row: SetRow) -> Bool {
        guard let weight = Double(row.weightText), let reps = Int(row.repsText) else { return false }
        return weight >= 0 && reps > 0
    }

    private func toggle(_ row: Binding<SetRow>) {
        if let entry = row.wrappedValue.entry {
            row.wrappedValue.entry = nil
            modelContext.delete(entry)
        } else if let exercise, isValid(row.wrappedValue),
                  let weight = Double(row.wrappedValue.weightText), let reps = Int(row.wrappedValue.repsText) {
            row.wrappedValue.entry = viewModel.logSet(
                exercise: exercise, weightKg: unit.toKg(weight), reps: reps, context: modelContext
            )
            isEditing = false
            fillForward(from: row.wrappedValue)
        }
    }

    /// Copies a just-logged set into the later rows that don't have a weight yet, so on a
    /// first-ever session the weight only has to be typed once. Rows with a weight are left
    /// alone — that's either a prefill from history or something the user typed.
    private func fillForward(from logged: SetRow) {
        guard let index = rows.firstIndex(where: { $0.id == logged.id }) else { return }
        for later in rows.indices where later > index && rows[later].entry == nil && rows[later].weightText.isEmpty {
            rows[later].weightText = logged.weightText
            rows[later].repsText = logged.repsText
        }
    }

    /// Today's already-logged sets first (checked), then blank rows up to the target, all
    /// prefilled from the last set of this exercise.
    private func buildRows() {
        guard rows.isEmpty, let exercise else { return }
        let logged = (sessions.first { Calendar.current.isDateInToday($0.date) }?.setEntries ?? [])
            .filter { $0.exercise == exercise }
            .sorted { $0.setNumber < $1.setNumber }
        rows = logged.map { entry in
            SetRow(
                weightText: unit.formattedLift(fromKg: entry.weightKg),
                repsText: String(entry.reps),
                entry: entry
            )
        }
        while rows.count < planExercise.targetSets {
            rows.append(blankRow())
        }
    }

    private func blankRow() -> SetRow {
        if let last = rows.last(where: { !$0.weightText.isEmpty }) ?? rows.last {
            return SetRow(weightText: last.weightText, repsText: last.repsText)
        }
        if let exercise, let last = WorkoutViewModel.lastSet(for: exercise, in: sessions) {
            return SetRow(weightText: unit.formattedLift(fromKg: last.weightKg), repsText: String(last.reps))
        }
        return SetRow(weightText: "", repsText: String(planExercise.targetReps))
    }
}
