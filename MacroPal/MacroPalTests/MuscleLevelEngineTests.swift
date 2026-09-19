//
//  MuscleLevelEngineTests.swift
//  MacroPalTests
//

import Foundation
import Testing
@testable import MacroPal

struct MuscleLevelEngineTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func daysAgo(_ days: Double) -> Date {
        now.addingTimeInterval(-days * 86_400)
    }

    private func squat(daysAgo days: Double, weightKg: Double, reps: Int = 5) -> LoggedSet {
        LoggedSet(date: daysAgo(days), exerciseName: "Back Squat", muscleGroup: .legs, weightKg: weightKg, reps: reps)
    }

    @Test func levelCountsThresholdsReached() {
        let thresholds = StrengthClass.lowerCompound.maleThresholds
        #expect(MuscleLevelEngine.level(forRatio: 0.2, thresholds: thresholds) == 0)
        #expect(MuscleLevelEngine.level(forRatio: 1.0, thresholds: thresholds) == 2)
        #expect(MuscleLevelEngine.level(forRatio: 9, thresholds: thresholds) == 6)
    }

    @Test func tenureCapGrowsWithTime() {
        #expect(MuscleLevelEngine.tenureCap(months: 0.5) == 1)
        #expect(MuscleLevelEngine.tenureCap(months: 6) == 3)
        #expect(MuscleLevelEngine.tenureCap(months: 12) == 4)
        #expect(MuscleLevelEngine.tenureCap(months: 100) == 6)
    }

    @Test func untrainedMusclesAreAbsent() {
        let levels = MuscleLevelEngine.levels(sets: [squat(daysAgo: 1, weightKg: 100)], bodyweightKg: 80, sex: .male, now: now)
        #expect(levels[.quads] != nil)
        #expect(levels[.biceps] == nil)
    }

    @Test func brandNewLifterIsCappedAtBeginnerEvenWithAHeavySet() {
        // 200 kg × 5 on an 80 kg lifter is far past Beginner strength, but tenure is one day.
        let levels = MuscleLevelEngine.levels(sets: [squat(daysAgo: 0, weightKg: 200)], bodyweightKg: 80, sex: .male, now: now)
        #expect(levels[.quads] == 1)
    }

    @Test func yearOfTrainingLetsStrengthShowThrough() {
        // Trained ~a year ago and again recently at 150 kg × 5 (≈175 kg e1RM ≈ 2.2× bodyweight).
        let sets = [squat(daysAgo: 400, weightKg: 60), squat(daysAgo: 2, weightKg: 150)]
        let levels = MuscleLevelEngine.levels(sets: sets, bodyweightKg: 80, sex: .male, now: now)
        #expect(levels[.quads] == 4)
    }

    @Test func oldStrengthOutsideTheWindowDoesNotCount() {
        // Heavy lifting 200 days ago and nothing since: still "trained" (Beginner floor) but no strength credit.
        let levels = MuscleLevelEngine.levels(sets: [squat(daysAgo: 200, weightKg: 150)], bodyweightKg: 80, sex: .male, now: now)
        #expect(levels[.quads] == 1)
    }

    @Test func womenAreJudgedAgainstLowerStandards() {
        let sets = [squat(daysAgo: 400, weightKg: 40), squat(daysAgo: 2, weightKg: 70)]
        let male = MuscleLevelEngine.levels(sets: sets, bodyweightKg: 70, sex: .male, now: now)
        let female = MuscleLevelEngine.levels(sets: sets, bodyweightKg: 70, sex: .female, now: now)
        #expect((female[.quads] ?? 0) > (male[.quads] ?? 0))
    }

    @Test func noBodyweightMeansOnlyTheBeginnerFloor() {
        let levels = MuscleLevelEngine.levels(sets: [squat(daysAgo: 400, weightKg: 150)], bodyweightKg: nil, sex: .male, now: now)
        #expect(levels[.quads] == 1)
    }
}
