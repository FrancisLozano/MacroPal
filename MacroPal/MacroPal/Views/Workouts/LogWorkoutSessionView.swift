//
//  LogWorkoutSessionView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

struct LogWorkoutSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var date: Date = .now
    @State private var notes: String = ""
    @State private var viewModel = WorkoutViewModel()
    @State private var isPresentingAddSetSheet = false

    var body: some View {
        Form {
            Section("Session") {
                DatePicker("Date", selection: $date)
                TextField("Notes (optional)", text: $notes, axis: .vertical)
            }
            Section("Sets") {
                if viewModel.draftSets.isEmpty {
                    Text("No sets added yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(viewModel.draftSets.enumerated()), id: \.element.id) { index, draft in
                        HStack {
                            Text("\(index + 1).")
                                .foregroundStyle(.secondary)
                            VStack(alignment: .leading) {
                                Text(draft.exercise.name)
                                Text(setSummary(draft))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: viewModel.removeSet)
                }
                Button {
                    isPresentingAddSetSheet = true
                } label: {
                    Label("Add Set", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Log Workout")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(viewModel.draftSets.isEmpty)
            }
        }
        .sheet(isPresented: $isPresentingAddSetSheet) {
            NavigationStack {
                AddSetView(viewModel: viewModel)
            }
        }
    }

    private func setSummary(_ draft: DraftSetEntry) -> String {
        var parts = ["\(draft.weightKg.formatted()) kg × \(draft.reps)"]
        if let rpe = draft.rpe {
            parts.append("RPE \(rpe.formatted())")
        }
        return parts.joined(separator: " · ")
    }

    private func save() {
        viewModel.saveSession(
            date: date,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes,
            context: modelContext
        )
        dismiss()
    }
}

/// Sub-form for adding one set to the in-progress session, defaulting weight/reps to the
/// previous set's values.
private struct AddSetView: View {
    @Environment(\.dismiss) private var dismiss

    var viewModel: WorkoutViewModel

    @State private var exercise: Exercise?
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @State private var rpeText: String = ""
    @State private var isPresentingExercisePicker = false

    private var isValid: Bool {
        exercise != nil && Double(weightText) != nil && Int(repsText) != nil
    }

    var body: some View {
        Form {
            Section("Exercise") {
                Button {
                    isPresentingExercisePicker = true
                } label: {
                    HStack {
                        Text(exercise?.name ?? "Choose an exercise")
                            .foregroundStyle(exercise == nil ? Color.secondary : Color.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
            }
            Section("Set Details") {
                HStack {
                    Text("Weight")
                    Spacer()
                    TextField("0", text: $weightText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    Text("kg")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Reps")
                    Spacer()
                    TextField("reps", text: $repsText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("RPE (optional)")
                    Spacer()
                    TextField("RPE", text: $rpeText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .navigationTitle("Add Set")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") { addSet() }
                    .disabled(!isValid)
            }
        }
        .sheet(isPresented: $isPresentingExercisePicker) {
            NavigationStack {
                ExercisePickerView { selected in
                    exercise = selected
                }
            }
        }
        .onAppear {
            let defaults = viewModel.nextSetDefaults
            exercise = defaults.exercise
            if defaults.weightKg > 0 { weightText = defaults.weightKg.formatted() }
            if defaults.reps > 0 { repsText = String(defaults.reps) }
        }
    }

    private func addSet() {
        guard let exercise, let weightKg = Double(weightText), let reps = Int(repsText) else { return }
        viewModel.addSet(exercise: exercise, weightKg: weightKg, reps: reps, rpe: Double(rpeText))
        dismiss()
    }
}

#Preview {
    NavigationStack {
        LogWorkoutSessionView()
    }
    .modelContainer(for: [Exercise.self, WorkoutSession.self, WorkoutSetEntry.self], inMemory: true)
}
