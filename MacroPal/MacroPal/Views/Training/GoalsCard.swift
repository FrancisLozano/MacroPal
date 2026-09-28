//
//  GoalsCard.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// Goals section of the Training page. Each row shows the current value against its goal;
/// tapping the value opens that goal's history (where the goal itself is edited), and the +
/// logs a new value.
struct GoalsCard: View {
    @Query private var profiles: [UserProfile]
    @Query private var stepEntries: [StepEntry]
    @Query private var weightEntries: [WeightEntry]
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .lb

    @State private var isPresentingLogWeightSheet = false
    @State private var isPresentingLogStepsSheet = false

    private let stepsViewModel = StepsViewModel()

    private var profile: UserProfile? { profiles.first }

    /// A plateau while cutting, or the goal weight reached — shown under the weight row.
    private var weightFindings: [InsightFinding] {
        guard let profile else { return [] }
        let snapshot = AnalysisSnapshot(
            profile: profile, weightEntries: weightEntries, foodEntries: [], workoutSessions: [], weightUnit: unit
        )
        return GoalWeightReachedRule.evaluate(snapshot) + WeightPlateauRule.evaluate(snapshot)
    }

    var body: some View {
        // lb/kg lives in Profile → Units & Measurements.
        TrainingSection("Goals") {
            VStack(alignment: .leading, spacing: 12) {
                weightRow

                ForEach(weightFindings) { finding in
                    InsightCallout(finding: finding)
                }

                Divider()

                stepsRow
            }
            .padding()
        }
        .sheet(isPresented: $isPresentingLogWeightSheet) {
            NavigationStack {
                LogWeightEntryView()
            }
        }
        .sheet(isPresented: $isPresentingLogStepsSheet) {
            NavigationStack {
                LogStepsView()
            }
        }
    }

    /// The latest weigh-in against the goal weight ("227 → 154.3 lb") under when it was taken
    /// ("Weighed 3 days ago"), so an old number doesn't pass for today's; just the goal before
    /// the first weigh-in. The row, caption and all, opens the weight history.
    private var weightRow: some View {
        let latest = weightEntries.max { $0.date < $1.date }
        let current = latest.map { unit.formattedLift(fromKg: $0.weightKg) }
        let age = latest.map { Self.age(of: $0.date) }
        return HStack {
            historyLink(caption: age.map { "Weighed \($0)" } ?? "Goal weight") {
                WeightHistoryView()
            } value: {
                Text(current ?? goalText)
                    .font(.title3.bold())
                // No-break spaces keep the goal and its unit together when the text wraps.
                Text(current == nil ? unit.symbol : "→\u{00A0}\(goalText)\u{00A0}\(unit.symbol)")
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel(current.map { "Weight \($0) \(unit.symbol), weighed \(age ?? ""), goal \(goalText). Weight history" }
                ?? "Goal weight \(goalText) \(unit.symbol). Weight history")
            logButton("Log weight") { isPresentingLogWeightSheet = true }
        }
    }

    /// Today's steps against the goal; the row opens the steps history.
    private var stepsRow: some View {
        let today = stepsViewModel.steps(on: .now, in: stepEntries)
        let goal = profile?.stepGoal ?? 10_000
        return HStack {
            historyLink(caption: "Steps today") {
                StepsHistoryView()
            } value: {
                Text(today, format: .number)
                    .font(.title3.bold())
                Text("/ \(goal.formatted())")
                    .foregroundStyle(.secondary)
                if today >= goal {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            .accessibilityLabel("\(today) of \(goal) steps today. Steps history")
            logButton("Log steps") { isPresentingLogStepsSheet = true }
        }
    }

    /// A caption over a value, the whole block (up to the +) one link, so a thumb doesn't have
    /// to land on the numbers.
    private func historyLink<Destination: View, Value: View>(
        caption: String,
        @ViewBuilder destination: () -> Destination,
        @ViewBuilder value: () -> Value
    ) -> some View {
        NavigationLink(destination: destination()) {
            VStack(alignment: .leading, spacing: 2) {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    value()
                }
            }
            .foregroundStyle(Color.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// A small gray circle with a +, in a 44-pt hit area so it's easy to hit one-handed.
    private func logButton(_ accessibilityLabel: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            PlusCircle()
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(accessibilityLabel)
    }

    private var goalText: String {
        guard let profile else { return "—" }
        return unit.formattedLift(fromKg: profile.goalWeightKg)
    }

    /// How long ago `date` was, in whole calendar days: "today", "yesterday", "3 days ago".
    static func age(of date: Date, now: Date = .now, calendar: Calendar = .current) -> String {
        let days = calendar.dateComponents(
            [.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: now)
        ).day ?? 0
        switch days {
        case ...0: return "today"
        case 1: return "yesterday"
        default: return "\(days) days ago"
        }
    }
}

#Preview {
    NavigationStack {
        GoalsCard()
    }
    .modelContainer(for: [WeightEntry.self, StepEntry.self, UserProfile.self], inMemory: true)
}
