//
//  SetRowTests.swift
//  MacroPalTests
//

import Testing
import Foundation
import SwiftData
@testable import MacroPal

@MainActor
struct SetRowTests {
    private func row(weight: String = "", reps: String = "", suggesting: (String, String) = ("135", "10"),
                     saved: SetValues? = nil) -> SetRow {
        var row = SetRow(weightText: weight, repsText: reps)
        row.weightPlaceholder = suggesting.0
        row.repsPlaceholder = suggesting.1
        row.saved = saved
        return row
    }

    @Test func anUntouchedRowIsNotLogged() {
        var untouched = row()
        untouched.completeFromPlaceholders()
        #expect(untouched.change == .none)
    }

    @Test func typingOnlyTheWeightKeepsTheSuggestedReps() {
        var typed = row(weight: "145")
        typed.completeFromPlaceholders()
        #expect(typed.change == .insert(SetValues(weight: 145, reps: 10)))
    }

    @Test func editingALoggedSetUpdatesIt() {
        var edited = row(weight: "140", reps: "10", saved: SetValues(weight: 135, reps: 10))
        edited.completeFromPlaceholders()
        #expect(edited.change == .update(SetValues(weight: 140, reps: 10)))
    }

    @Test func aBodyweightSetNeedsOnlyItsReps() {
        var pushUps = row(reps: "15", suggesting: ("0", "12"))
        pushUps.isBodyweight = true
        pushUps.completeFromPlaceholders()
        #expect(pushUps.change == .insert(SetValues(weight: 0, reps: 15)))

        var untouched = row(suggesting: ("0", "12"))
        untouched.isBodyweight = true
        untouched.completeFromPlaceholders()
        #expect(untouched.change == .none)
        #expect(untouched.wouldLogOnComplete)
    }

    @Test func aBodyweightSetLoggedWithAWeightKeepsIt() {
        // Logged as 25 lb before bodyweight moves lost their weight box: opening the screen
        // and leaving the row must not rewrite it to 0.
        var backExtension = row(weight: "25", reps: "12", saved: SetValues(weight: 25, reps: 12))
        backExtension.isBodyweight = true
        backExtension.completeFromPlaceholders()
        #expect(backExtension.change == .none)

        backExtension.repsText = "14"
        #expect(backExtension.change == .update(SetValues(weight: 25, reps: 14)))

        backExtension.repsText = ""
        #expect(backExtension.change == .delete)
    }

    @Test func onlyExercisesWithBodyweightEquipmentAreBodyweight() {
        #expect(Exercise(name: "Floor Back Extension", muscleGroup: .back, equipment: "Bodyweight").isBodyweight)
        #expect(Exercise(name: "Sissy Squat", muscleGroup: .legs, equipment: " bodyweight ").isBodyweight)
        #expect(!Exercise(name: "Ab Wheel Rollout", muscleGroup: .core, equipment: "Ab wheel").isBodyweight)
    }

    @Test func aLoggedSetThatDidNotChangeIsLeftAlone() {
        let same = row(weight: "135", reps: "10", saved: SetValues(weight: 135, reps: 10))
        #expect(same.change == .none)
    }

    @Test func clearingOneBoxOfALoggedSetPutsItsValueBack() {
        var cleared = row(weight: "135", reps: "", suggesting: ("100", "5"), saved: SetValues(weight: 135, reps: 8))
        cleared.completeFromPlaceholders()
        #expect(cleared.repsText == "8")
        #expect(cleared.change == .none)
    }

    @Test func clearingBothBoxesUnlogsTheSet() {
        let cleared = row(saved: SetValues(weight: 135, reps: 10))
        #expect(cleared.change == .delete)
    }

    @Test func zeroRepsIsNotASet() {
        let invalid = row(weight: "135", reps: "0")
        #expect(invalid.change == .none)
    }

    @Test func bodyweightSetsCanHaveNoWeight() {
        let pullUp = row(weight: "0", reps: "8")
        #expect(pullUp.change == .insert(SetValues(weight: 0, reps: 8)))
    }

    @Test func completeLogsAnUntouchedRowAtItsSuggestion() {
        var untouched = row()
        #expect(untouched.wouldLogOnComplete)
        untouched.fillEmptyFromPlaceholders()
        #expect(untouched.change == .insert(SetValues(weight: 135, reps: 10)))
    }

    @Test func withNoWeightSuggestedCompleteCannotLogTheRow() {
        let firstEver = row(suggesting: ("", "10"))
        #expect(!firstEver.wouldLogOnComplete)
    }

    @Test func aSavedSetIsSuggestedBelowWhenThereIsNoHistory() {
        var rows = [row(suggesting: ("", "10")), row(suggesting: ("", "10")), row(weight: "50", suggesting: ("", "10"))]
        SetRow.suggest(SetValues(weight: 95, reps: 8), below: 0, in: &rows)
        #expect(rows[1].weightPlaceholder == "95")
        #expect(rows[1].repsPlaceholder == "8")
        // Something typed in is left alone.
        #expect(rows[2].weightPlaceholder == "")
    }

    @Test func rowsWithALastSessionKeepSuggestingIt() {
        var withHistory = row()
        withHistory.last = SetValues(weight: 135, reps: 10)
        var rows = [row(), withHistory]
        SetRow.suggest(SetValues(weight: 145, reps: 6), below: 0, in: &rows)
        #expect(rows[1].weightPlaceholder == "135")
    }

    @Test func weightsFormatWithoutGrouping() {
        #expect(SetRow.format(1_135) == "1135")
        #expect(SetRow.format(62.5) == "62.5")
        #expect(SetRow.format(135) == "135")
    }
}

@MainActor
struct LastSessionSetsTests {
    private let container = try! ModelContainer(
        for: AppSchema.schema,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    private func session(daysAgo: Int, _ sets: [(Exercise, Double)]) -> WorkoutSession {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now)!
        let session = WorkoutSession(date: date)
        container.mainContext.insert(session)
        for (number, (exercise, weight)) in sets.enumerated() {
            let entry = WorkoutSetEntry(setNumber: number + 1, weightKg: weight, reps: 10, exercise: exercise)
            entry.session = session
            container.mainContext.insert(entry)
        }
        return session
    }

    @Test func comesFromTheLatestEarlierSessionWithTheExercise() {
        let squat = Exercise(name: "Back Squat", muscleGroup: .legs, equipment: "")
        let curl = Exercise(name: "Barbell Curl", muscleGroup: .biceps, equipment: "")
        container.mainContext.insert(squat)
        container.mainContext.insert(curl)
        let today = session(daysAgo: 0, [(squat, 110)])
        let curlsOnly = session(daysAgo: 2, [(curl, 20)])
        let legDay = session(daysAgo: 4, [(squat, 100), (curl, 15), (squat, 102)])
        let sessions = [today, curlsOnly, legDay]

        let last = WorkoutViewModel.lastSessionSets(
            for: squat, in: sessions, before: Calendar.current.startOfDay(for: .now)
        )
        #expect(last.map(\.weightKg) == [100, 102])
        #expect(WorkoutViewModel.lastValue(forSet: 1, in: last)?.weightKg == 102)
        // Set 3 falls back to the last set of that session.
        #expect(WorkoutViewModel.lastValue(forSet: 2, in: last)?.weightKg == 102)
        #expect(WorkoutViewModel.lastValue(forSet: 0, in: []) == nil)
    }
}
