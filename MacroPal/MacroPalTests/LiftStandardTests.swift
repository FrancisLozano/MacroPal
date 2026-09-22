//
//  LiftStandardTests.swift
//  MacroPalTests
//

import Foundation
import Testing
@testable import MacroPal

struct LiftStandardTests {
    private func squat(_ oneRepMaxKg: Double, bodyweightKg: Double? = 80, sex: Sex = .male) -> LiftStandard? {
        LiftStandard.evaluate(exerciseName: "Back Squat", group: .legs, oneRepMaxKg: oneRepMaxKg, bodyweightKg: bodyweightKg, sex: sex)
    }

    @Test func findsTheLevelAndTheNextTarget() {
        // Lower-compound standards at 80 kg bodyweight: 40, 80, 120, 160, 200, 240 kg.
        let standard = squat(100)
        #expect(standard == LiftStandard(level: 2, levelStartKg: 80, nextLevelKg: 120))
        #expect(standard?.progress(oneRepMaxKg: 100) == 0.5)
    }

    @Test func belowBeginnerStartsFromZero() {
        let standard = squat(20)
        #expect(standard?.level == 0)
        #expect(standard?.nextLevelKg == 40)
        #expect(standard?.progress(oneRepMaxKg: 20) == 0.5)
    }

    @Test func worldClassHasNoNextLevel() {
        let standard = squat(300)
        #expect(standard?.level == 6)
        #expect(standard?.nextLevelKg == nil)
        #expect(standard?.progress(oneRepMaxKg: 300) == 1)
    }

    @Test func dumbbellTargetsArePerDumbbell() {
        // Press standards × 80 kg ÷ 2 dumbbells: Intermediate (1.0×) starts at 40 kg a hand.
        let standard = LiftStandard.evaluate(
            exerciseName: "Dumbbell Bench Press", group: .chest, oneRepMaxKg: 30, bodyweightKg: 80, sex: .male
        )
        #expect(standard?.level == 2)
        #expect(abs((standard?.levelStartKg ?? 0) - 24) < 0.001)
        #expect(abs((standard?.nextLevelKg ?? 0) - 40) < 0.001)
    }

    @Test func womenHaveLowerTargets() {
        let male = squat(60, sex: .male)
        let female = squat(60, sex: .female)
        #expect((female?.level ?? 0) > (male?.level ?? 0))
    }

    @Test func noStandardWithoutBodyweightOrForBodyweightMovements() {
        #expect(squat(100, bodyweightKg: nil) == nil)
        #expect(LiftStandard.evaluate(exerciseName: "Pull-Up", group: .back, oneRepMaxKg: 20, bodyweightKg: 80, sex: .male) == nil)
    }
}
