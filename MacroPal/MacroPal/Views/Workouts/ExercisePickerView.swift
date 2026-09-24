//
//  ExercisePickerView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// Search an existing `Exercise` catalog, or create a new one inline. Calls `onSelect`
/// with the chosen/created exercise and dismisses itself. Pass `suggestedGroups` to open on
/// just those muscle groups, with a switch to see everything. Either way the list is under
/// muscle-group headings — Chest, Triceps, Biceps, Back, Shoulders, Legs, Abs.
struct ExercisePickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var suggestedGroups: [MuscleGroup] = []
    let onSelect: (Exercise) -> Void

    @State private var searchText = ""
    @State private var showsSuggestedOnly = true
    @State private var isPresentingNewExerciseForm = false

    private var results: [Exercise] {
        let all = (try? modelContext.fetch(FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.name)]))) ?? []
        // Searching always looks across everything; the suggestion filter only narrows browsing.
        if !Self.words(in: searchText).isEmpty {
            return all.filter { Self.matches(name: $0.name, query: searchText) }
        }
        guard showsSuggestedOnly, !suggestedGroups.isEmpty else { return all }
        return all.filter { suggestedGroups.contains($0.muscleGroup) }
    }

    /// True when every word typed appears somewhere in the name, in any order and ignoring
    /// case, accents and punctuation — so "single arm tricep ext" finds "Single-Arm Overhead
    /// Cable Triceps Extension". Matching the whole query as one piece missed hyphens and
    /// words in between.
    static func matches(name: String, query: String) -> Bool {
        let nameWords = words(in: name)
        return words(in: query).allSatisfy { typed in
            nameWords.contains { $0.hasPrefix(typed) } || nameWords.joined().contains(typed)
        }
    }

    /// Lowercased, accent-free words, split on anything that isn't a letter or digit.
    static func words(in text: String) -> [String] {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
    }

    /// `exercises` under their group's heading, in `MuscleGroup.choices` order, leaving out
    /// empty groups. Keeps the order within each group.
    static func sections(_ exercises: [Exercise]) -> [(group: MuscleGroup, exercises: [Exercise])] {
        let byGroup = Dictionary(grouping: exercises, by: \.muscleGroup)
        return (MuscleGroup.choices + [.arms]).compactMap { group in
            byGroup[group].map { (group, $0) }
        }
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
            let sections = Self.sections(results)
            List {
                ForEach(sections, id: \.group) { section in
                    Section(section.group.displayName) {
                        ForEach(section.exercises) { exercise in
                            Button {
                                onSelect(exercise)
                                dismiss()
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(exercise.name)
                                        .foregroundStyle(Color.primary)
                                    if !exercise.equipment.isEmpty {
                                        Text(exercise.equipment)
                                            .font(.caption)
                                            .foregroundStyle(Color.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            // A fresh List whenever the headings change (Suggested ↔ All, searching): rows are
            // buttons, and a List whose sections change shape can leave them dead to taps.
            .id(sections.map(\.group))
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
                    ForEach(MuscleGroup.choices) { group in
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
