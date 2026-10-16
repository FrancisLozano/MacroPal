//
//  ExerciseScreen.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// One exercise, opened from a plan day or an unplanned workout: a segmented control over the
/// Workout tab (log today's sets), the Overview tab (muscles worked) and the Progress tab (1RM,
/// level and history). From a plan day, ⟳ chooses an alternate when the exercise can't be done.
struct ExerciseScreen: View {
    private enum Tab: String, CaseIterable {
        case workout = "Workout"
        case overview = "Overview"
        case progress = "Progress"
    }

    private let planExercise: PlanExercise?
    private let unplannedExercise: Exercise?
    private let date: Date

    @State private var tab: Tab = .workout
    @State private var isChoosingAlternate = false

    init(planExercise: PlanExercise, date: Date = .now) {
        self.planExercise = planExercise
        unplannedExercise = nil
        self.date = date
    }

    init(exercise: Exercise, date: Date) {
        planExercise = nil
        unplannedExercise = exercise
        self.date = date
    }

    /// The plan slot's exercise for the date (an alternate if one was chosen), or the
    /// unplanned one.
    private var exercise: Exercise? {
        planExercise?.exercise(on: date) ?? unplannedExercise
    }

    /// Rebuilt when an alternate is chosen, so its rows start fresh.
    @ViewBuilder private var workout: some View {
        if let planExercise {
            ExerciseTrackView(planExercise: planExercise, date: date)
                .id(exercise?.persistentModelID)
        } else if let unplannedExercise {
            ExerciseTrackView(exercise: unplannedExercise, date: date)
        }
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
        .navigationSubtitle(swappedSubtitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if planExercise != nil {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isChoosingAlternate = true
                    } label: {
                        Label("Choose Alternate", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
            }
        }
        .modifier(AlternatePickerIfPlanned(isPresented: $isChoosingAlternate, planExercise: planExercise, date: date))
    }

    /// "Instead of Machine Chest Press" while an alternate stands in.
    private var swappedSubtitle: String {
        guard let planExercise, planExercise.isSwapped(on: date), let planned = planExercise.exercise else { return "" }
        return "Instead of \(planned.name)"
    }
}

/// The alternate picker, only for a plan slot.
private struct AlternatePickerIfPlanned: ViewModifier {
    @Binding var isPresented: Bool
    let planExercise: PlanExercise?
    let date: Date

    func body(content: Content) -> some View {
        if let planExercise {
            content.alternateExercisePicker(isPresented: $isPresented, planExercise: planExercise, date: date)
        } else {
            content
        }
    }
}
