//
//  Insight.swift
//  MacroPal
//

import Foundation
import SwiftData

enum InsightCategory: String, Codable, CaseIterable, Identifiable {
    case nutrition, body, training

    var id: Self { self }

    var displayName: String {
        switch self {
        case .nutrition: "Nutrition"
        case .body: "Body"
        case .training: "Training"
        }
    }

    var systemImage: String {
        switch self {
        case .nutrition: "fork.knife"
        case .body: "figure.stand"
        case .training: "dumbbell"
        }
    }
}

enum InsightSeverity: String, Codable, CaseIterable, Identifiable, Comparable {
    case info, suggestion, actionNeeded

    var id: Self { self }

    var displayName: String {
        switch self {
        case .info: "Info"
        case .suggestion: "Suggestion"
        case .actionNeeded: "Action Needed"
        }
    }

    private var rank: Int {
        switch self {
        case .info: 0
        case .suggestion: 1
        case .actionNeeded: 2
        }
    }

    static func < (lhs: InsightSeverity, rhs: InsightSeverity) -> Bool {
        lhs.rank < rhs.rank
    }
}

/// Replaces SPEC.md §4.5's single `acknowledged: Bool` — a Bool can't distinguish
/// "applied" from "dismissed," both of which the interaction model requires.
enum InsightStatus: String, Codable, CaseIterable, Identifiable {
    case pending, applied, dismissed

    var id: Self { self }
}

/// Identifies which rule produced an insight, used to dedup re-runs of the analysis
/// engine against already-pending insights rather than spamming duplicates.
enum InsightRuleID: String, Codable, CaseIterable {
    case weightPlateauCut
    case underEatingProtein
    case strengthStall
    case missedLoggingStreak
    case goalWeightReached
}

extension InsightRuleID {
    /// A short headline for the inline callout.
    func title(exerciseName: String?) -> String {
        switch self {
        case .weightPlateauCut: "Weight has plateaued"
        case .underEatingProtein: "Protein has been low this week"
        case .strengthStall: "\(exerciseName ?? "This lift") has stalled"
        case .missedLoggingStreak: "Nothing logged lately"
        case .goalWeightReached: "Goal weight reached"
        }
    }

    /// How the rule decides — shown behind the callout's info button, so a recommendation
    /// always says where it comes from.
    var explanation: String {
        switch self {
        case .weightPlateauCut:
            "Shown while your goal is Cut, when your 14-day average weight has moved less than 0.1% over the last 7 days (needs about two weeks of weigh-ins)."
        case .underEatingProtein:
            "Shown when your average protein over the last 7 days is under 90% of your target. Needs food logged on at least 4 of those days, so a week you barely logged doesn't count."
        case .strengthStall:
            "Shown when your top set hasn't gone up in 4 sessions in a row at the same reps."
        case .missedLoggingStreak:
            "Shown when there's been no food log or weigh-in for 5 days."
        case .goalWeightReached:
            "Shown when your 7-day average weight reaches your goal weight — at or below it on a cut, at or above on a bulk, within 0.5 kg (about 1 lb) when maintaining."
        }
    }
}

/// What a rule found, computed live and shown inline where it's relevant (the protein row,
/// the weight goal, the lift). Not stored — it's recomputed from the data every time, so it
/// disappears on its own once the condition no longer holds.
struct InsightFinding: Identifiable {
    let category: InsightCategory
    let severity: InsightSeverity
    let message: String
    let supportingMetric: String
    let ruleIdentifier: InsightRuleID
    var relatedExerciseName: String? = nil

    var id: String { "\(ruleIdentifier.rawValue)|\(relatedExerciseName ?? "")" }
    var title: String { ruleIdentifier.title(exerciseName: relatedExerciseName) }
}

/// A stored insight from the retired Insights tab (its "Analyze" button saved these).
/// Nothing writes it any more; it stays in `AppSchema` only so existing stores keep opening
/// without a migration. Rules now return `InsightFinding`.
@Model
final class Insight {
    var dateGenerated: Date
    var category: InsightCategory
    var severity: InsightSeverity
    var message: String
    var supportingMetric: String
    var status: InsightStatus
    var ruleIdentifier: InsightRuleID
    /// Set only for rules that can fire once per exercise (e.g. strength stall), so
    /// dedup can key on (ruleIdentifier, relatedExerciseName) instead of just the rule.
    var relatedExerciseName: String?

    init(
        dateGenerated: Date,
        category: InsightCategory,
        severity: InsightSeverity,
        message: String,
        supportingMetric: String,
        status: InsightStatus = .pending,
        ruleIdentifier: InsightRuleID,
        relatedExerciseName: String? = nil
    ) {
        self.dateGenerated = dateGenerated
        self.category = category
        self.severity = severity
        self.message = message
        self.supportingMetric = supportingMetric
        self.status = status
        self.ruleIdentifier = ruleIdentifier
        self.relatedExerciseName = relatedExerciseName
    }
}
