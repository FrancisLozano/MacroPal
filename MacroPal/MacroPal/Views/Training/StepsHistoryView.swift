//
//  StepsHistoryView.swift
//  MacroPal
//

import SwiftUI
import SwiftData
import Charts

/// Steps a day, week or month at a time, like the Health app: swipe back through past
/// periods, each with its total and (for weeks and months) a bar per day against the goal.
/// The logged days are listed below.
struct StepsHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StepEntry.day, order: .reverse) private var entries: [StepEntry]
    @Query private var profiles: [UserProfile]

    @State private var kind: StepsPeriod = .week
    /// The start of the period on screen; `nil` until the pager settles, which shows the
    /// latest one.
    @State private var visiblePeriodStart: Date?
    @State private var isPresentingLogSheet = false
    @State private var isPresentingGoalSheet = false

    /// A day has no chart, just its total and a goal bar, so its pages are shorter.
    private var pageHeight: CGFloat { kind == .day ? 150 : 340 }
    /// Same as the List's own row margin, restored by hand since the pager's row insets are
    /// zeroed (see `pager`).
    private static let rowInset: CGFloat = 16

    private var profile: UserProfile? { profiles.first }
    private var goal: Int { profile?.stepGoal ?? 10_000 }

    private var periods: [DateInterval] {
        guard let earliest = entries.last?.day else { return [] }
        return StepsViewModel.periods(kind, from: earliest, through: .now, calendar: .current)
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
                        Picker("Period", selection: $kind) {
                            ForEach(StepsPeriod.allCases) { kind in
                                Text(kind.shortLabel).tag(kind)
                            }
                        }
                        .pickerStyle(.segmented)
                        pager
                            .listRowInsets(EdgeInsets())
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

    /// One page per period, oldest on the left, opening on the current one. A paged
    /// horizontal `ScrollView` like the Nutrition meal carousel, with its row insets zeroed so
    /// the List's row gestures don't swallow the swipe. Re-created per `kind` so switching
    /// D / W / M lands on the latest period again.
    private var pager: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(periods, id: \.start) { period in
                    page(StepsViewModel.summary(of: period, entries.map { (day: $0.day, steps: $0.steps) }, goal: goal, calendar: .current))
                        .padding(.horizontal, Self.rowInset)
                        .containerRelativeFrame(.horizontal)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $visiblePeriodStart)
        .defaultScrollAnchor(.trailing)
        .scrollIndicators(.hidden)
        .frame(height: pageHeight)
        .id(kind)
    }

    private func page(_ summary: StepsPeriodSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(summary.total, format: .number)
                        .font(.title.bold())
                    Text("steps")
                        .foregroundStyle(.secondary)
                }
                Text(rangeText(summary.period))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if kind == .day {
                dayProgress(steps: summary.total)
            } else {
                chart(summary)
                stats(summary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
    }

    /// "Sun, Sep 27, 2026" / "Sep 21 – 27, 2026" / "September 2026".
    private func rangeText(_ period: DateInterval) -> String {
        switch kind {
        case .day:
            period.start.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().year())
        case .week:
            (period.start..<period.end.addingTimeInterval(-1)).formatted(.interval.month(.abbreviated).day().year())
        case .month:
            period.start.formatted(.dateTime.month(.wide).year())
        }
    }

    private func dayProgress(steps: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ProgressView(value: Double(min(steps, goal)), total: Double(max(goal, 1)))
                .tint(steps >= goal ? .green : .blue)
            Text(steps >= goal ? "Goal met" : "\(Int((Double(steps) / Double(max(goal, 1)) * 100).rounded()))% of your \(goal.formatted()) goal")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    private func chart(_ summary: StepsPeriodSummary) -> some View {
        Chart {
            ForEach(summary.days) { day in
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
        .chartXScale(domain: summary.period.start...summary.period.end)
        .chartXAxis {
            if kind == .week {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                }
            } else {
                AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day())
                }
            }
        }
        .frame(height: 180)
    }

    /// Both numbers count only the days something was logged — with manual entry, a blank
    /// day usually means "didn't log", not "didn't walk".
    @ViewBuilder
    private func stats(_ summary: StepsPeriodSummary) -> some View {
        if summary.loggedDays == 0 {
            Text("Nothing logged this \(kind == .week ? "week" : "month").")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            loggedStats(summary)
        }
    }

    private func loggedStats(_ summary: StepsPeriodSummary) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Average per logged day")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(summary.averagePerLoggedDay, format: .number)
                    .font(.headline)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Goal met")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(summary.daysGoalMet) of \(summary.loggedDays) \(summary.loggedDays == 1 ? "day" : "days")")
                    .font(.headline)
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
