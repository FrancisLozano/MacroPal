//
//  GoalWeightReachedRuleTests.swift
//  MacroPalTests
//

import Testing
import Foundation
@testable import MacroPal

struct GoalWeightReachedRuleTests {
    let calendar = Calendar(identifier: .gregorian)
    let baseDate = Date(timeIntervalSince1970: 1_735_689_600) // 2025-01-01 00:00:00 UTC

    private func day(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: baseDate)!
    }

    @Test func flagsOnCutWhenAtOrBelowGoal() {
        #expect(GoalWeightReachedRule.evaluate(latestAverageKg: 70.0, goalWeightKg: 70.0, goal: .cut) != nil)
        #expect(GoalWeightReachedRule.evaluate(latestAverageKg: 69.5, goalWeightKg: 70.0, goal: .cut) != nil)
    }

    @Test func doesNotFlagOnCutWhenAboveGoal() {
        #expect(GoalWeightReachedRule.evaluate(latestAverageKg: 72.0, goalWeightKg: 70.0, goal: .cut) == nil)
    }

    @Test func flagsOnBulkWhenAtOrAboveGoal() {
        #expect(GoalWeightReachedRule.evaluate(latestAverageKg: 85.0, goalWeightKg: 85.0, goal: .bulk) != nil)
        #expect(GoalWeightReachedRule.evaluate(latestAverageKg: 85.5, goalWeightKg: 85.0, goal: .bulk) != nil)
    }

    @Test func doesNotFlagOnBulkWhenBelowGoal() {
        #expect(GoalWeightReachedRule.evaluate(latestAverageKg: 83.0, goalWeightKg: 85.0, goal: .bulk) == nil)
    }

    @Test func flagsOnMaintainWithinTolerance() {
        #expect(GoalWeightReachedRule.evaluate(latestAverageKg: 80.3, goalWeightKg: 80.0, goal: .maintain) != nil)
    }

    @Test func doesNotFlagOnMaintainOutsideTolerance() {
        #expect(GoalWeightReachedRule.evaluate(latestAverageKg: 81.0, goalWeightKg: 80.0, goal: .maintain) == nil)
    }

    @Test func evaluateSnapshotFlagsGoalReachedOnCut() {
        let profile = UserProfile()
        profile.goal = .cut
        profile.goalWeightKg = 80.0
        let entries = (0..<7).map { WeightEntry(date: day($0), weightKg: 79.5) }
        let snapshot = AnalysisSnapshot(
            profile: profile,
            weightEntries: entries,
            foodEntries: [],
            workoutSessions: [],
            referenceDate: day(6),
            calendar: calendar
        )
        let results = GoalWeightReachedRule.evaluate(snapshot)
        #expect(results.count == 1)
        #expect(results.first?.ruleIdentifier == .goalWeightReached)
    }

    @Test func evaluateSnapshotDoesNotFlagBeforeGoalReachedOnCut() {
        let profile = UserProfile()
        profile.goal = .cut
        profile.goalWeightKg = 70.0
        let entries = (0..<7).map { WeightEntry(date: day($0), weightKg: 82.0) }
        let snapshot = AnalysisSnapshot(
            profile: profile,
            weightEntries: entries,
            foodEntries: [],
            workoutSessions: [],
            referenceDate: day(6),
            calendar: calendar
        )
        #expect(GoalWeightReachedRule.evaluate(snapshot).isEmpty)
    }
}
