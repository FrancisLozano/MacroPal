//
//  GoalWordingTests.swift
//  MacroPalTests
//

import Testing
import Foundation
@testable import MacroPal

/// The "no guilt" wording from the interviews: past a goal reads "above goal", never "over",
/// and nudges describe instead of scold.
struct GoalWordingTests {
    @Test func underTheGoalSaysWhatIsLeft() {
        #expect(GoalWording.remaining(1150) == "1,150 left")
        #expect(GoalWording.remaining(0) == "0 left")
        #expect(GoalWording.remaining(118.4, unit: "g", underGoal: "remaining") == "118g remaining")
    }

    @Test func pastTheGoalSaysAboveGoal() {
        #expect(GoalWording.remaining(-250) == "250 above goal")
        #expect(GoalWording.remaining(-1234) == "1,234 above goal")
        #expect(GoalWording.remaining(-12.6, unit: "g", underGoal: "remaining") == "13g above goal")
    }

    @Test func theProteinCalloutDescribesRatherThanScolds() {
        let calendar = Calendar(identifier: .gregorian)
        let start = Date(timeIntervalSince1970: 1_735_689_600)
        let profile = UserProfile()
        profile.proteinTargetG = 150
        let entries = (0...6).map { offset in
            FoodEntry(date: calendar.date(byAdding: .day, value: offset, to: start)!, mealType: .lunch,
                      servingSizeG: 100, nameSnapshot: "Test", caloriesKcal: 100, proteinG: 100, carbG: 0, fatG: 0)
        }
        let snapshot = AnalysisSnapshot(profile: profile, weightEntries: [], foodEntries: entries, workoutSessions: [],
                                        referenceDate: calendar.date(byAdding: .day, value: 6, to: start)!, calendar: calendar)

        let message = try? #require(ProteinIntakeRule.evaluate(snapshot).first).message
        #expect(message?.hasPrefix("Protein has averaged 100g a day this week, against a 150g target.") == true)
        #expect(message?.contains("under-eating") == false)
    }

    @Test func mealRemindersDoNotPointAtWhatWasMissed() {
        for reminder in [Reminder.breakfast, .lunch, .dinner] {
            #expect(!reminder.notificationBody.contains("Nothing"))
        }
        #expect(Reminder.lunch.notificationBody == "Add lunch when you get a moment.")
    }
}
