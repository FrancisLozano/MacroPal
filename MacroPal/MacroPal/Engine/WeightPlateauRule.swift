//
//  WeightPlateauRule.swift
//  MacroPal
//

import Foundation

/// Flags a weight plateau while cutting: if the trailing 14-day rolling average has moved
/// less than ±0.1% of bodyweight over the last 7 days, suggests a calorie cut or diet break.
enum WeightPlateauRule {
    static let plateauThresholdPercent = 0.1
    /// Require at least this many days of span before judging a plateau, so 2-3 sparse
    /// points that happen to be close together don't produce a false positive.
    static let minimumSpanDays = 13

    struct Result {
        let percentChangePerWeek: Double
        let latestAverageKg: Double
    }

    /// Core, pure-array logic — the primary unit-test target. Takes an already-computed
    /// rolling-average series (see `WeightViewModel.trendPoints`) rather than raw entries.
    static func evaluate(trendPoints: [WeightTrendPoint], goal: Goal, calendar: Calendar) -> Result? {
        guard goal == .cut else { return nil }
        guard let latest = trendPoints.last, let earliest = trendPoints.first else { return nil }

        let span = calendar.dateComponents([.day], from: earliest.date, to: latest.date).day ?? 0
        guard span >= minimumSpanDays else { return nil }

        guard let targetDate = calendar.date(byAdding: .day, value: -7, to: latest.date) else { return nil }
        guard let reference = trendPoints.last(where: { $0.date <= targetDate }), reference.rollingAverageKg > 0 else { return nil }

        let percentChange = (latest.rollingAverageKg - reference.rollingAverageKg) / reference.rollingAverageKg * 100
        guard abs(percentChange) <= plateauThresholdPercent else { return nil }

        return Result(percentChangePerWeek: percentChange, latestAverageKg: latest.rollingAverageKg)
    }

    static func evaluate(_ snapshot: AnalysisSnapshot) -> [Insight] {
        let points = WeightViewModel().trendPoints(for: snapshot.weightEntries, windowDays: 14, calendar: snapshot.calendar)
        guard let result = evaluate(trendPoints: points, goal: snapshot.profile.goal, calendar: snapshot.calendar) else { return [] }

        let insight = Insight(
            dateGenerated: snapshot.referenceDate,
            category: .body,
            severity: .suggestion,
            message: "Your weight has plateaued while cutting. Consider a calorie reduction of 100-200 kcal/day, or a diet break.",
            supportingMetric: String(format: "avg weight change: %.2f%% over the last 7 days (%.1f kg avg)", result.percentChangePerWeek, result.latestAverageKg),
            ruleIdentifier: .weightPlateauCut
        )
        return [insight]
    }
}
