//
//  ProfileSummaryTests.swift
//  MacroPalTests
//

import Testing
import Foundation
@testable import MacroPal

struct ProfileSummaryTests {
    private let viewModel = ProfileViewModel()

    @Test func targetsSummaryListsCaloriesThenMacros() {
        let summary = viewModel.targetsSummary(calorieTarget: 2000, proteinTargetG: 150, carbTargetG: 200, fatTargetG: 65)
        #expect(summary == "2,000\u{00A0}kcal · 150P · 200C · 65F")
    }
}
