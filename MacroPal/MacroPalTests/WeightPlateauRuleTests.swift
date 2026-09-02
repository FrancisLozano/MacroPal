//
//  WeightPlateauRuleTests.swift
//  MacroPalTests
//

import Testing
import Foundation
@testable import MacroPal

struct WeightPlateauRuleTests {
    let calendar = Calendar(identifier: .gregorian)
    let baseDate = Date(timeIntervalSince1970: 1_735_689_600) // 2025-01-01 00:00:00 UTC

    private func day(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: baseDate)!
    }

    /// One point per day from day 0 to day (count-1), with the given rolling averages.
    private func points(_ averages: [Double]) -> [WeightTrendPoint] {
        averages.enumerated().map { index, average in
            WeightTrendPoint(date: day(index), weightKg: average, rollingAverageKg: average)
        }
    }

    @Test func flagsPlateauOnCut() {
        // 14 days, essentially flat in the trailing week (82.0 -> 82.05, well under 0.1%).
        var averages = (0..<7).map { _ in 82.0 }
        averages.append(contentsOf: (0..<7).map { _ in 82.05 })
        let result = WeightPlateauRule.evaluate(trendPoints: points(averages), goal: .cut, calendar: calendar)
        #expect(result != nil)
    }

    @Test func doesNotFlagWhenGoalIsNotCut() {
        var averages = (0..<7).map { _ in 82.0 }
        averages.append(contentsOf: (0..<7).map { _ in 82.05 })
        let result = WeightPlateauRule.evaluate(trendPoints: points(averages), goal: .maintain, calendar: calendar)
        #expect(result == nil)
    }

    @Test func doesNotFlagWithClearWeightLoss() {
        // Losing ~0.7kg over the trailing week — well outside the plateau band.
        var averages = (0..<7).map { _ in 83.0 }
        averages.append(contentsOf: (0..<7).map { i in 83.0 - Double(i + 1) * 0.1 })
        let result = WeightPlateauRule.evaluate(trendPoints: points(averages), goal: .cut, calendar: calendar)
        #expect(result == nil)
    }

    @Test func doesNotFlagWithInsufficientHistory() {
        // Only 5 days of data — below the minimum span, even though it's flat.
        let result = WeightPlateauRule.evaluate(trendPoints: points([82.0, 82.0, 82.0, 82.0, 82.0]), goal: .cut, calendar: calendar)
        #expect(result == nil)
    }

    @Test func evaluateSnapshotProducesInsightForFlatCut() {
        let profile = UserProfile()
        profile.goal = .cut
        let entries = (0..<14).map { WeightEntry(date: day($0), weightKg: 82.0) }
        let snapshot = AnalysisSnapshot(
            profile: profile,
            weightEntries: entries,
            foodEntries: [],
            workoutSessions: [],
            referenceDate: day(13),
            calendar: calendar
        )
        let results = WeightPlateauRule.evaluate(snapshot)
        #expect(results.count == 1)
        #expect(results.first?.ruleIdentifier == .weightPlateauCut)
    }
}
