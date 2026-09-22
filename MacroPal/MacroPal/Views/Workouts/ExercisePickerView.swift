//
//  ExercisePickerView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// Search an existing `Exercise` catalog, or create a new one inline. Calls `onSelect`
/// with the chosen/created exercise and dismisses itself. Pass `suggestedGroups` to open on
/// just those muscle groups, with a switch to see everything.
struct ExercisePickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var suggestedGroups: [MuscleGroup] = []
    let onSelect: (Exercise) -> Void

    @State private var searchText = ""
    @State private var showsSuggestedOnly = true
    @State private var isPresentingNewExerciseForm = false

    private var results: [Exercise] {
        let descriptor: FetchDescriptor<Exercise>
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            descriptor = FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.name)])
        } else {
            descriptor = FetchDescriptor<Exercise>(
                predicate: #Predicate { $0.name.localizedStandardContains(searchText) },
                sortBy: [SortDescriptor(\.name)]
            )
        }
        let fetched = (try? modelContext.fetch(descriptor)) ?? []
        // Searching always looks across everything; the suggestion filter only narrows browsing.
        guard showsSuggestedOnly, !suggestedGroups.isEmpty, searchText.isEmpty else { return fetched }
        return fetched.filter { suggestedGroups.contains($0.muscleGroup) }
    }

    var body: some View {
        // The suggested/all switch sits outside the `List` so it stays live as the list changes.
        VStack(spacing: 0) {
            if !suggestedGroups.isEmpty {
                Picker("Show", selection: $showsSuggestedOnly) {
                    Text("Suggested").tag(true)
                    Text("All").tag(false)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            List {
                ForEach(results) { exercise in
                    Button {
                        onSelect(exercise)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading) {
                            Text(exercise.name)
                                .foregroundStyle(Color.primary)
                            Text(exercise.muscleGroup.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search exercises")
        .navigationTitle("Choose Exercise")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingNewExerciseForm = true
                } label: {
                    Label("New Exercise", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingNewExerciseForm) {
            NavigationStack {
                NewExerciseView(muscleGroup: suggestedGroups.first ?? .fullBody) { newExercise in
                    onSelect(newExercise)
                    dismiss()
                }
            }
        }
    }
}

private struct NewExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let onCreate: (Exercise) -> Void

    @State private var name = ""
    @State private var muscleGroup: MuscleGroup
    @State private var equipment = ""

    /// `muscleGroup` starts on the plan day's first suggested group, so a custom exercise shows
    /// up under that day's "Suggested" list rather than only under All.
    init(muscleGroup: MuscleGroup, onCreate: @escaping (Exercise) -> Void) {
        _muscleGroup = State(initialValue: muscleGroup)
        self.onCreate = onCreate
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        Form {
            Section("Name") {
                TextField("Exercise name", text: $name)
            }
            Section("Details") {
                Picker("Muscle Group", selection: $muscleGroup) {
                    ForEach(MuscleGroup.allCases) { group in
                        Text(group.displayName).tag(group)
                    }
                }
                TextField("Equipment (optional)", text: $equipment)
            }
        }
        .navigationTitle("New Exercise")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!isValid)
            }
        }
    }

    private func save() {
        let exercise = Exercise(
            name: name.trimmingCharacters(in: .whitespaces),
            muscleGroup: muscleGroup,
            equipment: equipment.trimmingCharacters(in: .whitespaces)
        )
        modelContext.insert(exercise)
        onCreate(exercise)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        ExercisePickerView { _ in }
    }
    .modelContainer(for: Exercise.self, inMemory: true)
}
