//
//  BodyMapSummaryTests.swift
//  MacroPalTests
//

import Testing
@testable import MacroPal

struct BodyMapSummaryTests {
    @Test func namesTheHighestLevelAndItsMuscles() {
        let levels: [Muscle: Int] = [.quads: 2, .chest: 2, .abs: 1]
        #expect(BodyMapCard.summary(levels) == "Novice: Chest, Quads")
    }

    @Test func shortensALongList() {
        let levels: [Muscle: Int] = [.chest: 2, .shoulders: 2, .triceps: 2, .lats: 2, .quads: 2, .abs: 1]
        #expect(BodyMapCard.summary(levels) == "Novice: Chest, Shoulders, Triceps, +2 more")
        #expect(BodyMapCard.summary(levels, names: 1) == "Novice: Chest, +4 more")
    }

    @Test func saysSoWhenEveryMuscleIsLevel() {
        #expect(BodyMapCard.summary([.chest: 1, .abs: 1]) == "All 2 trained muscles are Beginner")
        #expect(BodyMapCard.summary([.chest: 1]) == "Chest is Beginner")
        #expect(BodyMapCard.summary([:]) == nil)
    }

    @Test func speaksEveryLevelThenTheUntrained() {
        let levels = Dictionary(uniqueKeysWithValues: Muscle.allCases.map { ($0, 1) })
            .merging([.chest: 2]) { $1 }
            .filter { $0.key != .calves }
        let spoken = BodyMapCard.spokenLevels(levels)
        #expect(spoken.hasPrefix("Novice: Chest. Beginner: Shoulders, "))
        #expect(spoken.hasSuffix(". Not trained: Calves"))
        #expect(BodyMapCard.spokenLevels([:]) == "No muscles trained yet")
    }
}
