//
//  PlanDayDetailView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// One planned workout: each exercise is a card where sets are logged inline. Add exercises
/// from the toolbar; press and hold a card to remove it.
///
/// Cards live in a `ScrollView` rather than a `List` so their buttons stay live as exercises
/// come and go (see the Daily Log chevron bug).
struct PlanDayDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

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
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(day.sortedExercises) { planExercise in
                            ExerciseLogCard(planExercise: planExercise, sessions: sessions) {
                                remove(planExercise)
                            }
                        }
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
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
                ExercisePickerView(suggestedGroups: RoutineTemplate.muscleGroups(forDayNamed: day.name)) { exercise in
                    let planExercise = PlanExercise(order: day.exercises.count, exercise: exercise)
                    planExercise.day = day
                    modelContext.insert(planExercise)
                }
            }
        }
    }

    private func remove(_ planExercise: PlanExercise) {
        modelContext.delete(planExercise)
        // Close the gap so `order` stays contiguous for the next append.
        for (order, remaining) in day.sortedExercises.filter({ $0 !== planExercise }).enumerated() {
            remaining.order = order
        }
    }
}
