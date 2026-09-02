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
