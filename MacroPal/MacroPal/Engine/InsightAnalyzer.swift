//
//  InsightAnalyzer.swift
//  MacroPal
//

import Foundation

/// Orchestrates the rule engine. Deliberately `ModelContext`-free — it takes a snapshot
/// in and hands insights back, consistent with the app's "logic takes arrays in, View
/// stays declarative with @Query" convention.
@MainActor
enum InsightAnalyzer {
    private static let rules: [(AnalysisSnapshot) -> [Insight]] = [
        LoggingStreakRule.evaluate,
        WeightPlateauRule.evaluate,
        StrengthStallRule.evaluate,
        ProteinIntakeRule.evaluate,
        GoalWeightReachedRule.evaluate,
    ]

    /// Runs every rule against `snapshot`, skipping any candidate that would duplicate an
    /// already-pending insight for the same rule (and, where applicable, the same
    /// exercise) so re-running "Analyze" doesn't spam duplicates while one's still open.
    static func generateInsights(snapshot: AnalysisSnapshot, existingPendingInsights: [Insight]) -> [Insight] {
        let pendingKeys = Set(existingPendingInsights.map { dedupKey(ruleIdentifier: $0.ruleIdentifier, relatedExerciseName: $0.relatedExerciseName) })

        return rules
            .flatMap { $0(snapshot) }
            .filter { !pendingKeys.contains(dedupKey(ruleIdentifier: $0.ruleIdentifier, relatedExerciseName: $0.relatedExerciseName)) }
    }

    private static func dedupKey(ruleIdentifier: InsightRuleID, relatedExerciseName: String?) -> String {
        "\(ruleIdentifier.rawValue)|\(relatedExerciseName ?? "")"
    }
}
