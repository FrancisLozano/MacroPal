//
//  ExerciseHistoryTests.swift
//  MacroPalTests
//

import Testing
import Foundation
import SwiftData
@testable import MacroPal

@MainActor
struct ExerciseHistoryTests {
    private let container = try! ModelContainer(
        for: AppSchema.schema,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    private let viewModel = WorkoutProgressViewModel()

    private func session(daysAgo: Int, _ sets: [(Exercise, Double, Int, String?)]) -> WorkoutSession {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now)!
        let session = WorkoutSession(date: date)
        container.mainContext.insert(session)
        for (number, (exercise, weight, reps, day)) in sets.enumerated() {
            let entry = WorkoutSetEntry(setNumber: number + 1, weightKg: weight, reps: reps, exercise: exercise)
            entry.planDayName = day
            entry.session = session
            container.mainContext.insert(entry)
        }
        return session
    }

    @Test func listsOnlyThisExercisesSetsNewestFirstWithVolume() {
        let squat = Exercise(name: "Back Squat", muscleGroup: .legs, equipment: "")
        let curl = Exercise(name: "Barbell Curl", muscleGroup: .biceps, equipment: "")
        container.mainContext.insert(squat)
        container.mainContext.insert(curl)
        let older = session(daysAgo: 7, [(squat, 100, 5, "Lower"), (curl, 20, 10, "Lower"), (squat, 100, 3, "Lower")])
        let curlsOnly = session(daysAgo: 3, [(curl, 20, 10, nil)])
        let newer = session(daysAgo: 0, [(squat, 110, 5, nil)])

        let history = viewModel.history(for: squat, in: [older, curlsOnly, newer], bodyweightKg: 80)

        #expect(history.map(\.date) == [newer.date, older.date])
        #expect(history[0].planDayName == nil)
        #expect(history[1].planDayName == "Lower")
        #expect(history[1].sets.map(\.reps) == [5, 3])
        #expect(history[1].volumeKg == 800)
    }

    @Test func volumeSummaryTotalsAllTimeAndComparesCalendarWeeks() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // Monday
        calendar.timeZone = TimeZone(identifier: "UTC")!
        func date(_ day: Int) -> Date {
            calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: 12))!
        }
        func day(_ dayOfMonth: Int, volumeKg: Double) -> ExerciseHistoryDay {
            ExerciseHistoryDay(date: date(dayOfMonth), planDayName: nil, sets: [], volumeKg: volumeKg)
        }
        // Wednesday Sep 23; this week is Mon 21 – Sun 27, last week Mon 14 – Sun 20.
        let history = [day(23, volumeKg: 300), day(21, volumeKg: 200), day(20, volumeKg: 400), day(14, volumeKg: 100), day(13, volumeKg: 1000)]

        let summary = viewModel.volumeSummary(history, now: date(23), calendar: calendar)

        #expect(summary == VolumeSummary(totalKg: 2000, thisWeekKg: 500, lastWeekKg: 500))
    }

    @Test func volumeCountsBothDumbbellsAndBodyweightLikeTheBodyMap() {
        let curl = Exercise(name: "Dumbbell Curl", muscleGroup: .biceps, equipment: "")
        let pullUp = Exercise(name: "Pull-Up", muscleGroup: .back, equipment: "")
        container.mainContext.insert(curl)
        container.mainContext.insert(pullUp)
        let today = session(daysAgo: 0, [(curl, 10, 10, nil), (pullUp, 0, 5, nil), (pullUp, 10, 5, nil)])

        #expect(viewModel.history(for: curl, in: [today], bodyweightKg: 80).first?.volumeKg == 200)
        #expect(viewModel.history(for: pullUp, in: [today], bodyweightKg: 80).first?.volumeKg == 850)
    }
}
