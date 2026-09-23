//
//  WorkoutSettingsTests.swift
//  MacroPalTests
//

import Testing
import Foundation
@testable import MacroPal

struct WorkoutSettingsTests {
    // MARK: Height

    @Test func heightConvertsBetweenCmAndFeetInches() {
        #expect(HeightUnit.feetAndInches(fromCm: 170) == (5, 7))
        #expect(HeightUnit.feetAndInches(fromCm: 182.88) == (6, 0))
        #expect(abs(HeightUnit.cm(feet: 5, inches: 10) - 177.8) < 0.001)
        #expect(HeightUnit.feetInches.formatted(cm: 170) == "5′7″")
        #expect(HeightUnit.cm.formatted(cm: 170) == "170 cm")
    }

    // MARK: Rest timer

    @Test func restTimerCountsDownAndFinishes() {
        let start = Date(timeIntervalSince1970: 0)
        let timer = RestTimer(seconds: 90, now: start)
        #expect(timer.remaining(at: start.addingTimeInterval(30)) == 60)
        #expect(!timer.isFinished(at: start.addingTimeInterval(89)))
        #expect(timer.isFinished(at: start.addingTimeInterval(90)))
        #expect(timer.remaining(at: start.addingTimeInterval(200)) == 0)
    }

    @Test func adjustingNeverEndsBeforeNow() {
        let start = Date(timeIntervalSince1970: 0)
        var timer = RestTimer(seconds: 30, now: start)
        timer.adjust(by: 15, now: start)
        #expect(timer.remaining(at: start) == 45)
        timer.adjust(by: -60, now: start.addingTimeInterval(10))
        #expect(timer.isFinished(at: start.addingTimeInterval(10)))
    }

    // MARK: Labels

    @Test func restAndRepsLabels() {
        #expect(WorkoutPreferences.restLabel(seconds: 45) == "45 s")
        #expect(WorkoutPreferences.restLabel(seconds: 120) == "2 min")
        #expect(WorkoutPreferences.restLabel(seconds: 150) == "2 min 30 s")
        #expect(WorkoutPreferences.repsLabel(reps: 8, repsMax: 10) == "8–10")
        #expect(WorkoutPreferences.repsLabel(reps: 10, repsMax: 0) == "10")
    }

    @Test func workoutSummaryReadsAsOneLine() {
        let summary = ProfileViewModel().workoutSummary(weightFirst: true, sets: 3, reps: 8, repsMax: 10, restSeconds: 120, autoRest: true)
        #expect(summary == "Weight first · 3 × 8–10 · Rest 2 min, auto")
    }
}
