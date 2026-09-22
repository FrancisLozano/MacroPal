//
//  WeeklyMuscleVolumeTests.swift
//  MacroPalTests
//

import Foundation
import Testing
@testable import MacroPal

struct WeeklyMuscleVolumeTests {
    /// Weeks start on Sunday, fixed so the test doesn't depend on the machine's locale.
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = 1
        return calendar
    }()

    private func date(_ day: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: 12))!
    }

    private func set(_ name: String, _ group: MuscleGroup, on day: Int) -> LoggedSet {
        LoggedSet(date: date(day), exerciseName: name, muscleGroup: group, weightKg: 60, reps: 8)
    }

    @Test func mainMoversCountOneAndAssistersHalf() {
        // Barbell Row: lats 1, traps 0.7, biceps 0.5, lower back 0.4.
        let sets = Array(repeating: set("Barbell Row", .back, on: 22), count: 3)
        let volume = WeeklyMuscleVolume.sets(from: sets, now: date(23), calendar: calendar)
        #expect(volume[.lats] == 3)
        #expect(volume[.traps] == 1.5)
        #expect(volume[.biceps] == 1.5)
        #expect(volume[.lowerBack] == nil)
    }

    @Test func onlyTheCurrentWeekCounts() {
        // 2026-09-20 is a Sunday: the 19th is last week, the 20th and 22nd are this week.
        let sets = [set("Barbell Curl", .arms, on: 19), set("Barbell Curl", .arms, on: 20), set("Barbell Curl", .arms, on: 22)]
        let volume = WeeklyMuscleVolume.sets(from: sets, now: date(22), calendar: calendar)
        #expect(volume[.biceps] == 2)
    }

    @Test func bandsFollowSetCounts() {
        #expect(WeeklyMuscleVolume.band(forSets: 0) == 0)
        #expect(WeeklyMuscleVolume.band(forSets: 0.5) == 1)
        #expect(WeeklyMuscleVolume.band(forSets: 4.5) == 1)
        #expect(WeeklyMuscleVolume.band(forSets: 5) == 2)
        #expect(WeeklyMuscleVolume.band(forSets: 12) == 3)
        #expect(WeeklyMuscleVolume.band(forSets: 20) == 4)
    }
}
