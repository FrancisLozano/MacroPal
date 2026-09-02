//
//  RootView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                DailySummaryView()
            }
            .tabItem { Label("Nutrition", systemImage: "fork.knife") }

            NavigationStack {
                WeightHistoryView()
            }
            .tabItem { Label("Body", systemImage: "figure.stand") }

            NavigationStack {
                WorkoutHistoryView()
            }
            .tabItem { Label("Workouts", systemImage: "dumbbell") }

            NavigationStack {
                InsightsView()
            }
            .tabItem { Label("Insights", systemImage: "sparkles") }

            NavigationStack {
                ProfileView()
            }
            .tabItem { Label("Profile", systemImage: "person.circle") }
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
