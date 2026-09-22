//
//  PlanDayDetailView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// One planned workout as a list of exercises. Tap an exercise to track its sets; the ellipsis
/// edits its sets × reps, moves it up or down, or removes it.
///
/// Rows live in a `ScrollView` rather than a `List` so their buttons stay live as exercises
/// come and go (see the Daily Log chevron bug).
struct PlanDayDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    let day: PlanDay

    @State private var isPresentingExercisePicker = false

    private var todaysSession: WorkoutSession? {
        sessions.first { Calendar.current.isDateInToday($0.date) }
    }

    private func setsLoggedToday(for planExercise: PlanExercise) -> Int {
        guard let exercise = planExercise.exercise else { return 0 }
        return todaysSession?.setEntries.filter { $0.exercise == exercise }.count ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if day.exercises.isEmpty {
                    Text("Add the exercises you do on \(day.name) day.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 24)
                }
                let exercises = day.sortedExercises
                ForEach(exercises) { planExercise in
                    PlanExerciseRow(
                        planExercise: planExercise,
                        setsLoggedToday: setsLoggedToday(for: planExercise),
                        canMoveUp: planExercise !== exercises.first,
                        canMoveDown: planExercise !== exercises.last,
                        onMove: { offset in
                            withAnimation { day.move(planExercise, by: offset) }
                        }
                    ) {
                        remove(planExercise)
                    }
                }
                Button {
                    isPresentingExercisePicker = true
                } label: {
                    Label("Add Exercise", systemImage: "plus")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .navigationTitle(day.name)
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
