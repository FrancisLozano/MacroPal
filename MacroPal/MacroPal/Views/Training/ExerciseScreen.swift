//
//  ExerciseScreen.swift
//  MacroPal
//

import SwiftUI

/// One exercise, opened from a plan day or an unplanned workout: a segmented control over the
/// Workout tab (log today's sets), the Overview tab (muscles worked) and the Progress tab (1RM,
/// level and history).
struct ExerciseScreen: View {
    private enum Tab: String, CaseIterable {
        case workout = "Workout"
        case overview = "Overview"
        case progress = "Progress"
    }

    private let exercise: Exercise?
    private let workout: ExerciseTrackView

    @State private var tab: Tab = .workout

    init(planExercise: PlanExercise) {
        exercise = planExercise.exercise
        workout = ExerciseTrackView(planExercise: planExercise)
    }

    init(exercise: Exercise, date: Date) {
        self.exercise = exercise
        workout = ExerciseTrackView(exercise: exercise, date: date)
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Section", selection: $tab) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            switch tab {
            case .workout:
                workout
            case .overview:
                if let exercise {
                    ExerciseOverviewTab(exercise: exercise)
                }
            case .progress:
                if let exercise {
                    ExerciseProgressTab(exercise: exercise)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(exercise?.name ?? "Exercise")
        .navigationBarTitleDisplayMode(.inline)
    }
}
