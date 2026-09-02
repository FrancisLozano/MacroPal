//
//  LoggingStreakRule.swift
//  MacroPal
//

import Foundation

/// Flags a gentle nudge when there's been no food log or no weigh-in for `thresholdDays`.
enum LoggingStreakRule {
    static let thresholdDays = 5

    struct Result {
        let daysSinceLastFoodLog: Int?
        let daysSinceLastWeighIn: Int?
    }

    /// Core, pure-array logic — the primary unit-test target. `nil` last-log dates mean
    /// "never logged," which always counts as a missed streak once any data exists at all
    /// to establish a baseline (callers should only invoke this once the user has used the
    /// app for at least `thresholdDays`, which `evaluate` doesn't currently guard — a
    /// brand-new install with zero entries would otherwise immediately flag a streak).
    static func evaluate(
        lastFoodLogDate: Date?,
        lastWeighInDate: Date?,
        referenceDate: Date,
        calendar: Calendar
    ) -> Result? {
        func daysSince(_ date: Date?) -> Int? {
            guard let date else { return nil }
            return calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: referenceDate)).day
        }

        let foodGap = daysSince(lastFoodLogDate)
        let weightGap = daysSince(lastWeighInDate)

        // A nil gap means "never logged," which counts as missed just like a stale gap.
        let foodMissed = foodGap.map { $0 >= thresholdDays } ?? true
        let weightMissed = weightGap.map { $0 >= thresholdDays } ?? true

        guard foodMissed || weightMissed else { return nil }
        return Result(daysSinceLastFoodLog: foodGap, daysSinceLastWeighIn: weightGap)
    }

    static func evaluate(_ snapshot: AnalysisSnapshot) -> [Insight] {
        // Only run once there's at least one entry of either kind — a brand-new install
        // with no logs at all isn't a "missed streak," it's just day one.
        guard !snapshot.foodEntries.isEmpty || !snapshot.weightEntries.isEmpty else { return [] }

        guard let result = evaluate(
            lastFoodLogDate: snapshot.foodEntries.map(\.date).max(),
            lastWeighInDate: snapshot.weightEntries.map(\.date).max(),
            referenceDate: snapshot.referenceDate,
            calendar: snapshot.calendar
        ) else { return [] }

        var parts: [String] = []
        if let days = result.daysSinceLastFoodLog {
            if days >= thresholdDays { parts.append("no food logged in \(days) days") }
        } else {
            parts.append("no food ever logged")
        }
        if let days = result.daysSinceLastWeighIn {
            if days >= thresholdDays { parts.append("no weigh-in in \(days) days") }
        } else {
            parts.append("no weigh-in ever logged")
        }

        let insight = Insight(
            dateGenerated: snapshot.referenceDate,
            category: .body,
            severity: .info,
            message: "You've gone quiet — \(parts.joined(separator: ", ")). A quick log helps keep your trends accurate.",
            supportingMetric: parts.joined(separator: "; "),
            ruleIdentifier: .missedLoggingStreak
        )
        return [insight]
    }
}
