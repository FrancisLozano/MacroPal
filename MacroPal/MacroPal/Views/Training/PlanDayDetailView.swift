//
//  PlanDayDetailView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// One planned workout as a list of exercises. Tap an exercise to track its sets; the ellipsis
/// edits its sets × reps, moves it up or down, or removes it. When the last exercise's sets are
/// logged, Workout Complete shows at the bottom with the day's totals.
///
/// Rows live in a `ScrollView` rather than a `List` so their buttons stay live as exercises
/// come and go (see the Daily Log chevron bug).
struct PlanDayDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \WeightEntry.date, order: .reverse) private var weightEntries: [WeightEntry]
    @AppStorage(WorkoutPreferences.defaultSetsKey) private var defaultSets = WorkoutPreferences.defaultSetsDefault
    @AppStorage(WorkoutPreferences.defaultRepsKey) private var defaultReps = WorkoutPreferences.defaultRepsDefault
    @AppStorage(WorkoutPreferences.defaultRepsMaxKey) private var defaultRepsMax = WorkoutPreferences.defaultRepsMaxDefault

    let day: PlanDay

    @State private var isPresentingExercisePicker = false
    @State private var isShowingWorkoutComplete = false

    private var todaysSession: WorkoutSession? {
        sessions.first { Calendar.current.isDateInToday($0.date) }
    }

    private func setsLoggedToday(for planExercise: PlanExercise) -> Int {
        guard let exercise = planExercise.exercise else { return 0 }
        return todaysSession?.setEntries.filter { $0.exercise == exercise }.count ?? 0
    }

    /// Today's sets of the day's exercises.
    private var todaysDaySets: [WorkoutSetEntry] {
        let exercises = day.exercises.compactMap(\.exercise)
        return todaysSession?.setEntries.filter { entry in
            exercises.contains { $0 == entry.exercise }
        } ?? []
    }

    /// Every exercise on the day has its target sets logged today.
    private var isWorkoutComplete: Bool {
        DayProgress(day: day, session: todaysSession).isComplete
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
        .safeAreaInset(edge: .bottom) {
            if isShowingWorkoutComplete {
                let sets = todaysDaySets
                WorkoutCompleteCard(
                    exercises: Set(sets.compactMap { $0.exercise?.persistentModelID }).count,
                    sets: sets.count,
                    volumeKg: volumeKg(of: sets)
                ) {
                    withAnimation { isShowingWorkoutComplete = false }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                RestTimerBar()
            }
        }
        // Only the change to complete counts, so reopening a finished day doesn't show it again.
        // It usually happens with the exercise screen still on top, so the card is waiting here.
        .onChange(of: isWorkoutComplete) { wasComplete, isComplete in
            if !wasComplete && isComplete { isShowingWorkoutComplete = true }
        }
        .sensoryFeedback(.success, trigger: isShowingWorkoutComplete) { _, new in new }
        .sheet(isPresented: $isPresentingExercisePicker) {
            NavigationStack {
                ExercisePickerView(suggestedGroups: RoutineTemplate.muscleGroups(forDayNamed: day.name)) { exercise in
                    // New exercises start on the Profile → Workout default target.
                    let planExercise = PlanExercise(
                        order: day.exercises.count, exercise: exercise, targetSets: defaultSets, targetReps: defaultReps
                    )
                    planExercise.targetRepsMax = defaultRepsMax > defaultReps ? defaultRepsMax : nil
                    planExercise.day = day
                    modelContext.insert(planExercise)
                }
            }
        }
    }

    /// Load × reps over `sets`, counted as the Progress tab and body map count it: both
    /// dumbbells, machines scaled, a share of bodyweight for bodyweight moves.
    private func volumeKg(of sets: [WorkoutSetEntry]) -> Double {
        sets.reduce(0) { total, entry in
            guard let exercise = entry.exercise else { return total }
            let set = LoggedSet(date: entry.session?.date ?? .now, exerciseName: exercise.name,
                                muscleGroup: exercise.muscleGroup, weightKg: entry.weightKg, reps: entry.reps)
            let profile = ExerciseMuscleData.profile(forName: exercise.name, group: exercise.muscleGroup)
            let load = MuscleLevelEngine.load(of: set, profile: profile, bodyweightKg: weightEntries.first?.weightKg)
            return total + load * Double(max(0, entry.reps))
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
