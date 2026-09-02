//
//  LoggingStreakRuleTests.swift
//  MacroPalTests
//

import Testing
import Foundation
@testable import MacroPal

struct LoggingStreakRuleTests {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = Date(timeIntervalSince1970: 1_735_689_600) // 2025-01-01 00:00:00 UTC

    private func daysAgo(_ days: Int) -> Date {
        calendar.date(byAdding: .day, value: -days, to: referenceDate)!
    }

    @Test func flagsWhenBothLogsAreStale() {
        let result = LoggingStreakRule.evaluate(
            lastFoodLogDate: daysAgo(6),
            lastWeighInDate: daysAgo(7),
            referenceDate: referenceDate,
            calendar: calendar
        )
        #expect(result != nil)
        #expect(result?.daysSinceLastFoodLog == 6)
        #expect(result?.daysSinceLastWeighIn == 7)
    }

    @Test func flagsWhenOnlyOneLogIsStale() {
        let result = LoggingStreakRule.evaluate(
            lastFoodLogDate: daysAgo(1),
            lastWeighInDate: daysAgo(5),
            referenceDate: referenceDate,
            calendar: calendar
        )
        #expect(result != nil)
    }

    @Test func doesNotFlagJustBelowThreshold() {
        let result = LoggingStreakRule.evaluate(
            lastFoodLogDate: daysAgo(4),
            lastWeighInDate: daysAgo(4),
            referenceDate: referenceDate,
            calendar: calendar
        )
        #expect(result == nil)
    }

    @Test func doesNotFlagWithRecentLogs() {
        let result = LoggingStreakRule.evaluate(
            lastFoodLogDate: daysAgo(0),
            lastWeighInDate: daysAgo(1),
            referenceDate: referenceDate,
            calendar: calendar
        )
        #expect(result == nil)
    }

    @Test func neverLoggedCountsAsMissed() {
        let result = LoggingStreakRule.evaluate(
            lastFoodLogDate: nil,
            lastWeighInDate: daysAgo(0),
            referenceDate: referenceDate,
            calendar: calendar
        )
        #expect(result != nil)
        #expect(result?.daysSinceLastFoodLog == nil)
    }

    @Test func evaluateSnapshotSkipsBrandNewInstallWithNoEntriesAtAll() {
        let profile = UserProfile()
        let snapshot = AnalysisSnapshot(
            profile: profile,
            weightEntries: [],
            foodEntries: [],
            workoutSessions: [],
            referenceDate: referenceDate,
            calendar: calendar
        )
        #expect(LoggingStreakRule.evaluate(snapshot).isEmpty)
    }

    @Test func evaluateSnapshotFlagsStaleRealEntries() {
        let profile = UserProfile()
        let snapshot = AnalysisSnapshot(
            profile: profile,
            weightEntries: [WeightEntry(date: daysAgo(6), weightKg: 80)],
            foodEntries: [FoodEntry(date: daysAgo(6), mealType: .breakfast, servingSizeG: 100, nameSnapshot: "Test", caloriesKcal: 100, proteinG: 10, carbG: 10, fatG: 10)],
            workoutSessions: [],
            referenceDate: referenceDate,
            calendar: calendar
        )
        let results = LoggingStreakRule.evaluate(snapshot)
        #expect(results.count == 1)
        #expect(results.first?.ruleIdentifier == .missedLoggingStreak)
    }
}
