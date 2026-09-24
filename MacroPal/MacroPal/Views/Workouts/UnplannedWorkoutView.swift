//
//  UnplannedWorkoutView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// A workout outside the plan, logged the same way as a plan day: pick an exercise, then check
/// off sets on the tracking screen. Each set saves the moment it's checked, so there's no Save
/// step and nothing to lose by closing the sheet. Opens straight into the exercise picker.
///
/// Replaces the old draft-then-save form, which took 12 taps across three stacked sheets to log
/// 3 sets of one new exercise; this takes 8 (open, pick, weight, reps, three checks, Done) —
/// 6 when the exercise has history to prefill from.
struct UnplannedWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    @State private var date: Date = .now
    /// Exercises picked in this sheet that may not have a logged set yet.
    @State private var addedExercises: [Exercise] = []
    @State private var path: [Exercise] = []
    @State private var isPresentingPicker = false
    @State private var hasOpenedPicker = false

    /// Sets already logged on `date`, per exercise — so reopening the sheet (or picking an
    /// earlier day) shows what's there.
    private var setsOnDate: [(exercise: Exercise, count: Int)] {
        let entries = sessions
            .filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
            .flatMap(\.setEntries)
        var counts: [PersistentIdentifier: (exercise: Exercise, count: Int)] = [:]
        var order: [PersistentIdentifier] = []
        for entry in entries.sorted(by: { $0.setNumber < $1.setNumber }) {
            guard let exercise = entry.exercise else { continue }
            let id = exercise.persistentModelID
            if counts[id] == nil { order.append(id) }
            counts[id, default: (exercise, 0)].count += 1
        }
        var result = order.compactMap { counts[$0] }
        for exercise in addedExercises where counts[exercise.persistentModelID] == nil {
            result.append((exercise, 0))
        }
        return result
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: .date)
                }
                Section {
                    ForEach(setsOnDate, id: \.exercise.persistentModelID) { item in
                        NavigationLink(value: item.exercise) {
                            HStack(spacing: 12) {
                                ExerciseThumbnail(exercise: item.exercise)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.exercise.name)
                                        .font(.headline)
                                    Text(item.count == 1 ? "1 set" : "\(item.count) sets")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    Button {
                        isPresentingPicker = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus")
                    }
                } footer: {
                    Text("Sets save as you check them off.")
                }
            }
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                RestTimerBar()
            }
            .toolbar { doneButton }
            .navigationDestination(for: Exercise.self) { exercise in
                ExerciseScreen(exercise: exercise, date: date)
                    .toolbar { doneButton }
            }
            .sheet(isPresented: $isPresentingPicker) {
                NavigationStack {
                    ExercisePickerView { exercise in
                        if !addedExercises.contains(exercise) {
                            addedExercises.append(exercise)
                        }
                        path = [exercise]
                    }
                }
            }
            .onAppear {
                // Open straight into the picker the first time — picking an exercise is always
                // the first thing to do.
                guard !hasOpenedPicker else { return }
                hasOpenedPicker = true
                isPresentingPicker = true
            }
        }
        // The sheet covers RootView's card, so it needs its own.
        .restOverCard()
    }

    private var doneButton: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button("Done") { dismiss() }
        }
    }
}

#Preview {
    UnplannedWorkoutView()
        .modelContainer(for: [WorkoutSession.self, WorkoutSetEntry.self, Exercise.self], inMemory: true)
}
