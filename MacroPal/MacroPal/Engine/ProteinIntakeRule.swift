//
//  ProteinIntakeRule.swift
//  MacroPal
//

import Foundation

/// Flags under-eating protein: if the trailing 7-day average protein intake falls below
/// 90% of target, suggests closing the gap with specific servings.
enum ProteinIntakeRule {
    static let thresholdPercent = 0.9
    static let windowDays = 7
    /// Require protein logged on at least this many of the trailing days before judging
    /// adequacy — a mostly-unlogged week isn't "under-eating," it's under-*logging*
    /// (which `LoggingStreakRule` already covers), and would otherwise produce a
    /// misleadingly low average.
    static let minimumLoggedDays = 4

    struct Result {
        let averageProteinG: Double
        let targetProteinG: Int
        let percentOfTarget: Double
    }

    /// Core, pure logic — the primary unit-test target.
    static func evaluate(averageProteinG: Double, targetProteinG: Int) -> Result? {
        guard targetProteinG > 0 else { return nil }
        let percent = averageProteinG / Double(targetProteinG)
        guard percent < thresholdPercent else { return nil }
        return Result(averageProteinG: averageProteinG, targetProteinG: targetProteinG, percentOfTarget: percent)
    }

    static func evaluate(_ snapshot: AnalysisSnapshot) -> [Insight] {
        let endDay = snapshot.calendar.startOfDay(for: snapshot.referenceDate)
        guard let startDay = snapshot.calendar.date(byAdding: .day, value: -(windowDays - 1), to: endDay) else { return [] }

        let windowEntries = snapshot.foodEntries.filter { entry in
            let day = snapshot.calendar.startOfDay(for: entry.date)
            return day >= startDay && day <= endDay
        }

        let loggedDays = Set(windowEntries.map { snapshot.calendar.startOfDay(for: $0.date) })
        guard loggedDays.count >= minimumLoggedDays else { return [] }

        let averageProteinG = windowEntries.map(\.proteinG).reduce(0, +) / Double(windowDays)
        guard let result = evaluate(averageProteinG: averageProteinG, targetProteinG: snapshot.profile.proteinTargetG) else { return [] }

        let gapG = max(0, Double(result.targetProteinG) - result.averageProteinG)
        let insight = Insight(
            dateGenerated: snapshot.referenceDate,
            category: .nutrition,
            severity: .suggestion,
            message: "You've been under-eating protein — averaging \(Int(result.averageProteinG))g/day against a \(result.targetProteinG)g target. Try adding about \(Int(gapG))g more per day, e.g. an extra serving of chicken, Greek yogurt, or a protein shake.",
            supportingMetric: String(format: "7-day avg protein: %.0fg (%.0f%% of %dg target)", result.averageProteinG, result.percentOfTarget * 100, result.targetProteinG),
            ruleIdentifier: .underEatingProtein
        )
        return [insight]
    }
}
