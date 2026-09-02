//
//  ProteinIntakeRuleTests.swift
//  MacroPalTests
//

import Testing
import Foundation
@testable import MacroPal

struct ProteinIntakeRuleTests {
    let calendar = Calendar(identifier: .gregorian)
    let baseDate = Date(timeIntervalSince1970: 1_735_689_600) // 2025-01-01 00:00:00 UTC

    private func day(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: baseDate)!
    }

    @Test func flagsBelowNinetyPercent() {
        // 89% of 150g target.
        let result = ProteinIntakeRule.evaluate(averageProteinG: 133.5, targetProteinG: 150)
        #expect(result != nil)
    }

    @Test func doesNotFlagAtExactlyNinetyPercent() {
        let result = ProteinIntakeRule.evaluate(averageProteinG: 135, targetProteinG: 150)
        #expect(result == nil)
    }

    @Test func doesNotFlagAboveNinetyPercent() {
        // 91% of 150g target.
        let result = ProteinIntakeRule.evaluate(averageProteinG: 136.5, targetProteinG: 150)
        #expect(result == nil)
    }

    @Test func doesNotFlagWithZeroTarget() {
        let result = ProteinIntakeRule.evaluate(averageProteinG: 10, targetProteinG: 0)
        #expect(result == nil)
    }

    private func foodEntry(_ dayOffset: Int, proteinG: Double) -> FoodEntry {
        FoodEntry(date: day(dayOffset), mealType: .breakfast, servingSizeG: 100, nameSnapshot: "Test", caloriesKcal: 100, proteinG: proteinG, carbG: 0, fatG: 0)
    }

    @Test func evaluateSnapshotFlagsLowProteinWeek() {
        let profile = UserProfile()
        profile.proteinTargetG = 150
        // ~100g/day average across 6 logged days out of the trailing 7.
        let entries = (1...6).map { foodEntry($0, proteinG: 100) }
        let snapshot = AnalysisSnapshot(
            profile: profile,
            weightEntries: [],
            foodEntries: entries,
            workoutSessions: [],
            referenceDate: day(6),
            calendar: calendar
        )
        let results = ProteinIntakeRule.evaluate(snapshot)
        #expect(results.count == 1)
        #expect(results.first?.ruleIdentifier == .underEatingProtein)
    }

    @Test func evaluateSnapshotSkipsSparselyLoggedWeek() {
        let profile = UserProfile()
        profile.proteinTargetG = 150
        // Only 2 days logged in the trailing week — a logging gap, not under-eating.
        let entries = [foodEntry(5, proteinG: 10), foodEntry(6, proteinG: 10)]
        let snapshot = AnalysisSnapshot(
            profile: profile,
            weightEntries: [],
            foodEntries: entries,
            workoutSessions: [],
            referenceDate: day(6),
            calendar: calendar
        )
        #expect(ProteinIntakeRule.evaluate(snapshot).isEmpty)
    }

    @Test func evaluateSnapshotDoesNotFlagWhenTargetIsMet() {
        let profile = UserProfile()
        profile.proteinTargetG = 150
        let entries = (0...6).map { foodEntry($0, proteinG: 150) }
        let snapshot = AnalysisSnapshot(
            profile: profile,
            weightEntries: [],
            foodEntries: entries,
            workoutSessions: [],
            referenceDate: day(6),
            calendar: calendar
        )
        #expect(ProteinIntakeRule.evaluate(snapshot).isEmpty)
    }
}
