//
//  ExerciseProgressView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

struct ExerciseProgressView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    @State private var selectedExercise: Exercise?

    private let viewModel = WorkoutProgressViewModel()

    private var loggedExercises: [Exercise] {
        viewModel.loggedExercises(from: sessions)
    }

    var body: some View {
        Group {
            if loggedExercises.isEmpty {
                ContentUnavailableView(
                    "No Workout Data",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Log a session to start tracking progress.")
                )
            } else {
                List {
                    Section {
                        Picker("Exercise", selection: $selectedExercise) {
                            ForEach(loggedExercises) { exercise in
                                Text(exercise.name).tag(Optional(exercise))
                            }
                        }
                    }
                    if let selectedExercise {
                        let points = viewModel.progression(for: selectedExercise, in: sessions)
                        if points.isEmpty {
                            Text("No logged sets for this exercise.")
                                .foregroundStyle(.secondary)
                        } else {
                            Section {
                                WorkoutProgressChart(points: points)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Exercise Progress")
        .onAppear {
            if selectedExercise == nil {
                selectedExercise = viewModel.mostRecentlyLoggedExercise(from: sessions) ?? loggedExercises.first
            }
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseProgressView()
    }
    .modelContainer(for: [WorkoutSession.self, WorkoutSetEntry.self, Exercise.self], inMemory: true)
}
