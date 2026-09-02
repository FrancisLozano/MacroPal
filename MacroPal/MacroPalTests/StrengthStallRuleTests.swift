//
//  StrengthStallRuleTests.swift
//  MacroPalTests
//

import Testing
import Foundation
@testable import MacroPal

struct StrengthStallRuleTests {
    let calendar = Calendar(identifier: .gregorian)
    let baseDate = Date(timeIntervalSince1970: 1_735_689_600) // 2025-01-01 00:00:00 UTC

    private func day(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: baseDate)!
    }

    private func point(_ dayOffset: Int, weightKg: Double, reps: Int) -> ExerciseProgressPoint {
        ExerciseProgressPoint(date: day(dayOffset), topSetWeightKg: weightKg, topSetReps: reps, estimated1RM: OneRepMaxEstimator.epley(weightKg: weightKg, reps: reps))
    }

    @Test func flagsFourFlatSessions() {
        let points = [
            point(0, weightKg: 60, reps: 8),
            point(2, weightKg: 60, reps: 8),
            point(4, weightKg: 60, reps: 8),
            point(6, weightKg: 60, reps: 8),
        ]
        let result = StrengthStallRule.evaluate(points: points)
        #expect(result != nil)
        #expect(result?.currentWeightKg == 60)
        #expect(result?.sessionsChecked == 4)
    }

    @Test func doesNotFlagWhenImprovementOnThirdOfFour() {
        let points = [
            point(0, weightKg: 60, reps: 8),
            point(2, weightKg: 60, reps: 8),
            point(4, weightKg: 62.5, reps: 8),
            point(6, weightKg: 62.5, reps: 8),
        ]
        let result = StrengthStallRule.evaluate(points: points)
        #expect(result == nil)
    }

    @Test func doesNotFlagWithFewerThanFourSessions() {
        let points = [
            point(0, weightKg: 60, reps: 8),
            point(2, weightKg: 60, reps: 8),
            point(4, weightKg: 60, reps: 8),
        ]
        let result = StrengthStallRule.evaluate(points: points)
        #expect(result == nil)
    }

    @Test func ignoresSessionsAtADifferentRepRange() {
        // Only the last 4 at reps==8 should count; the reps==5 session in between breaks
        // continuity but shouldn't itself prevent detection once the same-rep window fills.
        let points = [
            point(0, weightKg: 60, reps: 8),
            point(2, weightKg: 65, reps: 5),
            point(4, weightKg: 60, reps: 8),
            point(6, weightKg: 60, reps: 8),
            point(8, weightKg: 60, reps: 8),
        ]
        let result = StrengthStallRule.evaluate(points: points)
        #expect(result != nil)
        #expect(result?.reps == 8)
    }

    @Test func evaluateSnapshotFlagsStalledExercise() {
        let profile = UserProfile()
        let exercise = Exercise(name: "Bench Press", muscleGroup: .chest, equipment: "Barbell")
        var sessions: [WorkoutSession] = []
        for offset in stride(from: 0, to: 8, by: 2) {
            let session = WorkoutSession(date: day(offset))
            let set = WorkoutSetEntry(setNumber: 1, weightKg: 60, reps: 8, exercise: exercise)
            set.session = session
            session.setEntries = [set]
            sessions.append(session)
        }
        let snapshot = AnalysisSnapshot(
            profile: profile,
            weightEntries: [],
            foodEntries: [],
            workoutSessions: sessions,
            referenceDate: day(7),
            calendar: calendar
        )
        let results = StrengthStallRule.evaluate(snapshot)
        #expect(results.count == 1)
        #expect(results.first?.relatedExerciseName == "Bench Press")
    }
}
