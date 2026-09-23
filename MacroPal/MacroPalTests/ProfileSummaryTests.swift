//
//  ProfileSummaryTests.swift
//  MacroPalTests
//

import Testing
import Foundation
@testable import MacroPal

struct ProfileSummaryTests {
    private let viewModel = ProfileViewModel()
    private let calendar = Calendar(identifier: .gregorian)

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    @Test func ageCountsOnlyCompletedYears() {
        let birth = date(2001, 9, 15)
        #expect(viewModel.age(birthDate: birth, now: date(2026, 9, 14), calendar: calendar) == 24)
        #expect(viewModel.age(birthDate: birth, now: date(2026, 9, 15), calendar: calendar) == 25)
    }

    @Test func personalSummaryReadsAsOneLine() {
        let summary = viewModel.personalSummary(
            sex: .male, birthDate: date(2001, 9, 15), heightCm: 170, activityLevel: .sedentary, now: date(2026, 9, 22)
        )
        #expect(summary == "Male · 25 · 170 cm · Sedentary")
    }

    @Test func targetsSummaryListsCaloriesThenMacros() {
        let summary = viewModel.targetsSummary(calorieTarget: 2000, proteinTargetG: 150, carbTargetG: 200, fatTargetG: 65)
        #expect(summary == "2,000 kcal · 150P · 200C · 65F")
    }
}
