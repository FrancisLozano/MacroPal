//
//  AlternateExercisePicker.swift
//  MacroPal
//

import SwiftUI

extension View {
    /// Choose Alternate for a plan slot whose exercise can't be done (machine taken, no cable
    /// free): pick another exercise, suggested from the same muscle group, then do it for just
    /// this workout or put it in the plan (usability.md, 2026-10-16). Used from the exercise
    /// screen's toolbar and the plan day row's ⋯ menu.
    func alternateExercisePicker(isPresented: Binding<Bool>, planExercise: PlanExercise, date: Date) -> some View {
        modifier(AlternateExercisePicker(isPresented: isPresented, planExercise: planExercise, date: date))
    }
}

private struct AlternateExercisePicker: ViewModifier {
    @Binding var isPresented: Bool
    let planExercise: PlanExercise
    let date: Date

    /// The exercise just picked, waiting on "this workout or the plan?". Asked once the sheet
    /// is gone, since a dialog can't come up while it's still closing.
    @State private var picked: Exercise?
    @State private var isAskingHowLong = false

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented, onDismiss: {
                if picked != nil { isAskingHowLong = true }
            }) {
                NavigationStack {
                    ExercisePickerView(
                        suggestedGroups: (planExercise.exercise(on: date) ?? planExercise.exercise).map { [$0.muscleGroup] } ?? [],
                        title: "Choose Alternate"
                    ) { exercise in
                        picked = exercise
                    }
                }
            }
            .confirmationDialog(
                picked.map { "Do \($0.name) instead" } ?? "",
                isPresented: $isAskingHowLong,
                titleVisibility: .visible,
                presenting: picked
            ) { exercise in
                Button("Just This Workout") {
                    planExercise.swap(to: exercise, on: date)
                    picked = nil
                }
                Button("Replace in Plan") {
                    planExercise.replace(with: exercise)
                    picked = nil
                }
                Button("Cancel", role: .cancel) { picked = nil }
            } message: { _ in
                Text("Just This Workout keeps \(planExercise.exercise?.name ?? "the planned exercise") in your plan for next time.")
            }
    }
}
