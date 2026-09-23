//
//  RootView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var restTimer = RestTimerModel()

    var body: some View {
        TabView {
            NavigationStack {
                DailySummaryView()
            }
            .tabItem { Label("Nutrition", systemImage: "fork.knife") }

            NavigationStack {
                TrainingView()
            }
            .tabItem { Label("Training", systemImage: "dumbbell") }

            // No Insights tab: each rule's finding shows inline where it's relevant
            // (`InsightCallout`) — protein on Nutrition, weight on the Goals card, stalls on
            // Exercise Progress.

            NavigationStack {
                ProfileView()
            }
            .tabItem { Label("Profile", systemImage: "person.circle") }
        }
        // One rest timer for the whole app, so it survives moving between workout screens.
        .environment(restTimer)
        .task {
            StarterExerciseCatalog.seedIfNeeded(in: modelContext)
        }
    }
}

#Preview {
    RootView()
        .modelContainer(
            for: [UserProfile.self, FoodItem.self, FoodEntry.self, WeightEntry.self, Exercise.self, WorkoutSession.self, WorkoutSetEntry.self, Insight.self],
            inMemory: true
        )
}
