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

    private func set(_ name: String, _ group: MuscleGroup, daysAgo days: Double, weightKg: Double, reps: Int = 10) -> LoggedSet {
        LoggedSet(date: daysAgo(days), exerciseName: name, muscleGroup: group, weightKg: weightKg, reps: reps)
    }

    private func squat(daysAgo days: Double, weightKg: Double, reps: Int = 10) -> LoggedSet {
        set("Back Squat", .legs, daysAgo: days, weightKg: weightKg, reps: reps)
    }

    @Test func levelCountsBodyweightsMoved() {
        #expect(MuscleLevelEngine.level(forBodyweights: 0) == 1)
        #expect(MuscleLevelEngine.level(forBodyweights: 89) == 1)
        #expect(MuscleLevelEngine.level(forBodyweights: 90) == 2)
        #expect(MuscleLevelEngine.level(forBodyweights: 2_500) == 4)
        #expect(MuscleLevelEngine.level(forBodyweights: 15_000) == 6)
    }

    @Test func tenureCapGrowsWithTime() {
        #expect(MuscleLevelEngine.tenureCap(months: 0.2) == 1)
        #expect(MuscleLevelEngine.tenureCap(months: 0.5) == 2)
        #expect(MuscleLevelEngine.tenureCap(months: 6) == 3)
        #expect(MuscleLevelEngine.tenureCap(months: 12) == 4)
        #expect(MuscleLevelEngine.tenureCap(months: 59) == 5)
        #expect(MuscleLevelEngine.tenureCap(months: 60) == 6)
    }

    @Test func volumeIsCreditedByInvolvement() {
        let volume = MuscleLevelEngine.volumeKg(sets: [squat(daysAgo: 1, weightKg: 100)], bodyweightKg: 80)
        #expect(volume[.quads] == 1_000)
        #expect(volume[.glutes] == 800)
        #expect(volume[.biceps] == nil)
    }

    @Test func dumbbellLiftsCountBothDumbbells() {
        let volume = MuscleLevelEngine.volumeKg(sets: [set("Dumbbell Curl", .biceps, daysAgo: 1, weightKg: 10)], bodyweightKg: 80)
        #expect(volume[.biceps] == 200)
    }

    @Test func bodyweightMovesCountBodyweightPlusAddedWeight() {
        let pullUps = set("Pull-Up", .back, daysAgo: 1, weightKg: 0)
        let weighted = set("Pull-Up", .back, daysAgo: 1, weightKg: 10)
        #expect(MuscleLevelEngine.volumeKg(sets: [pullUps], bodyweightKg: 80)[.lats] == 800)
        #expect(MuscleLevelEngine.volumeKg(sets: [weighted], bodyweightKg: 80)[.lats] == 900)
        // Without a bodyweight only the added weight counts.
        #expect(MuscleLevelEngine.volumeKg(sets: [pullUps], bodyweightKg: nil)[.lats] == nil)
    }

    @Test func untrainedAndBarelyAssistingMusclesAreAbsent() {
        let levels = MuscleLevelEngine.levels(sets: [squat(daysAgo: 1, weightKg: 100)], bodyweightKg: 80, sex: .male, now: now)
        #expect(levels[.quads] != nil)
        #expect(levels[.biceps] == nil)
        // Abs assist the squat at 0.3 — credited volume, but not "trained".
        #expect(levels[.abs] == nil)
    }

    @Test func threeWeeksOfSquatsReachNovice() {
        // 3 × 10 at half of an 80 kg bodyweight, twice a week for 3 weeks = 90 bodyweights.
        let days: [Double] = [21, 18, 14, 11, 7, 4]
        let sets = days.flatMap { day in (0..<3).map { _ in squat(daysAgo: day, weightKg: 40) } }
        let levels = MuscleLevelEngine.levels(sets: sets, bodyweightKg: 80, sex: .male, now: now)
        #expect(levels[.quads] == 2)
    }

    @Test func aBigFirstDayIsStillBeginner() {
        // Far past Novice's volume, but trained for one day.
        let sets = (0..<50).map { _ in squat(daysAgo: 0, weightKg: 100) }
        let levels = MuscleLevelEngine.levels(sets: sets, bodyweightKg: 80, sex: .male, now: now)
        #expect(levels[.quads] == 1)
    }

    @Test func aYearOfVolumeReachesAdvancedButNotMore() {
        // 2,500+ bodyweights of quad volume over a year; the tenure cap stops it at Advanced.
        let sets = [squat(daysAgo: 370, weightKg: 40)] + (0..<250).map { _ in squat(daysAgo: 2, weightKg: 100) }
        let levels = MuscleLevelEngine.levels(sets: sets, bodyweightKg: 80, sex: .male, now: now)
        #expect(levels[.quads] == 4)
    }

    @Test func worldClassTakesFiveYears() {
        // Enough volume for World Class either way (1.5M kg ÷ 80 kg = 18,750 bodyweights).
        let volume = (0..<1_500).map { _ in squat(daysAgo: 2, weightKg: 100) }
        let fourYears = MuscleLevelEngine.levels(sets: [squat(daysAgo: 4 * 365, weightKg: 40)] + volume, bodyweightKg: 80, sex: .male, now: now)
        let fiveYears = MuscleLevelEngine.levels(sets: [squat(daysAgo: 5 * 366, weightKg: 40)] + volume, bodyweightKg: 80, sex: .male, now: now)
        #expect(fourYears[.quads] == 5)
        #expect(fiveYears[.quads] == 6)
    }

    @Test func aMuscleKeepsItsLevelThroughABreak() {
        let days: [Double] = [221, 218, 214, 211, 207, 204]
        let sets = days.flatMap { day in (0..<3).map { _ in squat(daysAgo: day, weightKg: 40) } }
        let levels = MuscleLevelEngine.levels(sets: sets, bodyweightKg: 80, sex: .male, now: now)
        #expect(levels[.quads] == 2)
    }

    @Test func womenNeedLessVolumeForTheSameLevel() {
        let sets = [squat(daysAgo: 30, weightKg: 30)] + (0..<16).map { _ in squat(daysAgo: 2, weightKg: 30) }
        let male = MuscleLevelEngine.levels(sets: sets, bodyweightKg: 70, sex: .male, now: now)
        let female = MuscleLevelEngine.levels(sets: sets, bodyweightKg: 70, sex: .female, now: now)
        #expect(male[.quads] == 1)
        #expect(female[.quads] == 2)
    }

    @Test func noBodyweightMeansOnlyTheBeginnerFloor() {
        let sets = [squat(daysAgo: 400, weightKg: 150)] + (0..<300).map { _ in squat(daysAgo: 2, weightKg: 150) }
        let levels = MuscleLevelEngine.levels(sets: sets, bodyweightKg: nil, sex: .male, now: now)
        #expect(levels[.quads] == 1)
    }
}
