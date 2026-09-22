//
//  StepsHistoryView.swift
//  MacroPal
//

import SwiftUI
import SwiftData
import Charts

/// Daily step bars against the goal, over the last week or month, plus the logged days.
struct StepsHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StepEntry.day, order: .reverse) private var entries: [StepEntry]
    @Query private var profiles: [UserProfile]

    @State private var range: Range = .week
    @State private var isPresentingLogSheet = false
    @State private var isPresentingGoalSheet = false

    private let viewModel = StepsViewModel()

    enum Range: Int, CaseIterable, Identifiable {
        case week = 7
        case month = 30

        var id: Int { rawValue }
        var label: String { self == .week ? "7 Days" : "30 Days" }
    }

    private var profile: UserProfile? { profiles.first }
    private var goal: Int { profile?.stepGoal ?? 10_000 }

    private var days: [DailySteps] {
        viewModel.dailyTotals(entries, days: range.rawValue)
    }

    var body: some View {
        Group {
            if entries.isEmpty {
                ContentUnavailableView(
                    "No Steps Logged",
                    systemImage: "figure.walk",
                    description: Text("Log a day's steps to see them against your goal.")
                )
            } else {
                List {
                    Section {
                        Picker("Range", selection: $range) {
                            ForEach(Range.allCases) { range in
                                Text(range.label).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                        chart
                        summary
                    }
                    Section {
                        Button {
                            isPresentingGoalSheet = true
                        } label: {
                            HStack {
                                Text("Daily Goal")
                                    .foregroundStyle(Color.primary)
                                Spacer()
                                Text(goal, format: .number)
                                Text("steps")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    Section("Logged") {
                        ForEach(entries) { entry in
                            HStack {
                                Text(entry.steps, format: .number)
                                    .font(.headline)
                                if entry.steps >= goal {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                        .accessibilityLabel("Goal met")
                                }
                                Spacer()
                                Text(entry.day, format: .dateTime.month().day().year())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onDelete(perform: deleteEntries)
                    }
                }
            }
        }
        .navigationTitle("Steps")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingLogSheet = true
                } label: {
                    Label("Log Steps", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingLogSheet) {
            NavigationStack {
                LogStepsView()
            }
        }
        .sheet(isPresented: $isPresentingGoalSheet) {
            if let profile {
                NavigationStack {
                    StepGoalEditView(profile: profile)
                }
            }
        }
        .task {
            _ = UserProfile.current(in: modelContext)
        }
    }

    private var chart: some View {
        Chart {
            ForEach(days) { day in
                BarMark(x: .value("Day", day.day, unit: .day), y: .value("Steps", day.steps))
                    .foregroundStyle(day.steps >= goal ? Color.green : Color.blue)
                    .cornerRadius(3)
            }
            RuleMark(y: .value("Goal", goal))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .foregroundStyle(Color.gray)
                .annotation(position: .top, alignment: .leading) {
                    Text("Goal")
                        .font(.caption2)
                        .foregroundStyle(Color.gray)
                }
        }
        .chartXAxis {
            if range == .week {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                }
            } else {
                // Weekly marks from the first day, stopping short of the trailing edge so the
                // last label isn't clipped against the y-axis.
                AxisMarks(values: stride(from: 0, to: days.count - 3, by: 7).map { days[$0].day }) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
        }
        .frame(height: 200)
        .padding(.vertical, 4)
    }

    /// Both numbers count only the days something was logged — with manual entry, a blank
    /// day usually means "didn't log", not "didn't walk".
    private var summary: some View {
        let logged = days.filter { $0.steps > 0 }
        let average = logged.isEmpty ? 0 : logged.map(\.steps).reduce(0, +) / logged.count
        let hit = logged.filter { $0.steps >= goal }.count
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Average per logged day")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(average, format: .number)
                    .font(.title3.bold())
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Goal met")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(hit) of \(logged.count) \(logged.count == 1 ? "day" : "days")")
                    .font(.title3.bold())
            }
        }
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(entries[index])
        }
    }
}

#Preview {
    NavigationStack {
        StepsHistoryView()
    }
    .modelContainer(for: [StepEntry.self, UserProfile.self], inMemory: true)
}
