//
//  PlanDayDetailView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// One planned workout: its exercises with target sets × reps. Add exercises from the toolbar.
struct PlanDayDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let day: PlanDay

    @State private var isPresentingExercisePicker = false

    var body: some View {
        Group {
            if day.exercises.isEmpty {
                ContentUnavailableView(
                    "No Exercises Yet",
                    systemImage: "dumbbell",
                    description: Text("Add the exercises you do on \(day.name) day.")
                )
            } else {
                List {
                    ForEach(day.sortedExercises) { planExercise in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(planExercise.exercise?.name ?? "Unknown exercise")
                                Text(planExercise.exercise?.muscleGroup.displayName ?? "")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(planExercise.targetSets) × \(planExercise.targetReps)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete(perform: deleteExercises)
                }
            }
        }
        .navigationTitle(day.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingExercisePicker = true
                } label: {
                    Label("Add Exercise", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingExercisePicker) {
            NavigationStack {
                ExercisePickerView { exercise in
                    let planExercise = PlanExercise(order: day.exercises.count, exercise: exercise)
                    planExercise.day = day
                    modelContext.insert(planExercise)
                }
            }
        }
    }

    private func deleteExercises(at offsets: IndexSet) {
        let sorted = day.sortedExercises
        for index in offsets {
            modelContext.delete(sorted[index])
        }
        // Close the gap so `order` stays contiguous for the next append.
        for (order, remaining) in day.sortedExercises.filter({ !$0.isDeleted }).enumerated() {
            remaining.order = order
        }
    }
}
