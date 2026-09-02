//
//  GoalWeightReachedRule.swift
//  MacroPal
//

import Foundation

/// Flags when the trailing 7-day average weight has reached the goal, direction depending
/// on the current `Goal`: crossing at or below goal on a cut, at or above on a bulk, or
/// landing within a small tolerance band while maintaining.
enum GoalWeightReachedRule {
    /// For `.maintain`, "at goal" is judged within this band rather than an exact match,
    /// since day-to-day water weight makes hitting the exact number unlikely.
    static let maintainToleranceKg = 0.5

    struct Result {
        let currentAverageKg: Double
        let goalWeightKg: Double
    }

    /// Core, pure logic — the primary unit-test target.
    static func evaluate(latestAverageKg: Double, goalWeightKg: Double, goal: Goal) -> Result? {
        switch goal {
        case .cut:
            guard latestAverageKg <= goalWeightKg else { return nil }
        case .bulk:
            guard latestAverageKg >= goalWeightKg else { return nil }
        case .maintain:
            guard abs(latestAverageKg - goalWeightKg) <= maintainToleranceKg else { return nil }
        }
        return Result(currentAverageKg: latestAverageKg, goalWeightKg: goalWeightKg)
    }

    static func evaluate(_ snapshot: AnalysisSnapshot) -> [Insight] {
        let points = WeightViewModel().trendPoints(for: snapshot.weightEntries, windowDays: 7, calendar: snapshot.calendar)
        guard let latest = points.last else { return [] }
        guard let result = evaluate(latestAverageKg: latest.rollingAverageKg, goalWeightKg: snapshot.profile.goalWeightKg, goal: snapshot.profile.goal) else { return [] }

        let insight = Insight(
            dateGenerated: snapshot.referenceDate,
            category: .body,
            severity: .actionNeeded,
            message: String(format: "You've reached your goal weight of %.1f kg. Set a new goal, switch to maintenance, or hold here for a recomposition phase.", result.goalWeightKg),
            supportingMetric: String(format: "7-day avg weight: %.1f kg (goal: %.1f kg)", result.currentAverageKg, result.goalWeightKg),
            ruleIdentifier: .goalWeightReached
        )
        return [insight]
    }
}
