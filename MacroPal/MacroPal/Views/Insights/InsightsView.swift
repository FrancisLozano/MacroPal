//
//  InsightsView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

struct InsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeightEntry.date, order: .reverse) private var weightEntries: [WeightEntry]
    @Query(sort: \FoodEntry.date, order: .reverse) private var foodEntries: [FoodEntry]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var workoutSessions: [WorkoutSession]
    @Query(sort: \Insight.dateGenerated, order: .reverse) private var insights: [Insight]

    private var pendingInsights: [Insight] {
        insights
            .filter { $0.status == .pending }
            .sorted { $0.severity == $1.severity ? $0.dateGenerated > $1.dateGenerated : $0.severity > $1.severity }
    }

    private var historyInsights: [Insight] {
        insights.filter { $0.status != .pending }
    }

    var body: some View {
        Group {
            if insights.isEmpty {
                ContentUnavailableView(
                    "No Insights Yet",
                    systemImage: "sparkles",
                    description: Text("Tap Analyze to review your recent progress.")
                )
            } else {
                List {
                    if !pendingInsights.isEmpty {
                        Section("Needs Attention") {
                            ForEach(pendingInsights) { insight in
                                InsightCardView(insight: insight)
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            insight.status = .applied
                                        } label: {
                                            Label("Apply", systemImage: "checkmark")
                                        }
                                        .tint(.green)
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button {
                                            insight.status = .dismissed
                                        } label: {
                                            Label("Dismiss", systemImage: "xmark")
                                        }
                                        .tint(.gray)
                                    }
                            }
                        }
                    }
                    if !historyInsights.isEmpty {
                        Section("History") {
                            ForEach(historyInsights) { insight in
                                InsightCardView(insight: insight)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Insights")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    analyze()
                } label: {
                    Label("Analyze", systemImage: "sparkles")
                }
            }
        }
        .task {
            _ = UserProfile.current(in: modelContext)
        }
    }

    private func analyze() {
        let profile = UserProfile.current(in: modelContext)
        let snapshot = AnalysisSnapshot(
            profile: profile,
            weightEntries: weightEntries,
            foodEntries: foodEntries,
            workoutSessions: workoutSessions
        )
        let newInsights = InsightAnalyzer.generateInsights(
            snapshot: snapshot,
            existingPendingInsights: pendingInsights
        )
        newInsights.forEach { modelContext.insert($0) }
    }
}

#Preview {
    NavigationStack {
        InsightsView()
    }
    .modelContainer(
        for: [Insight.self, WeightEntry.self, FoodEntry.self, WorkoutSession.self, UserProfile.self],
        inMemory: true
    )
}
