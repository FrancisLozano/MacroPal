//
//  ExerciseMusclesTests.swift
//  MacroPalTests
//

import Testing
@testable import MacroPal

@MainActor
struct ExerciseMusclesTests {
    @Test func mainMoversArePrimaryAndTheRestSecondary() {
        let deadlift = ExerciseMuscleData.profile(forName: "Deadlift", group: .back)
        // Ties (hamstrings and glutes at 1.0) go head to toe.
        #expect(deadlift.primaryMuscles == [.glutes, .hamstrings, .lowerBack])
        #expect(deadlift.secondaryMuscles == [.traps, .quads, .forearms, .lats])
    }

    @Test func primaryIsOrderedByInvolvement() {
        let hammerCurl = ExerciseMuscleData.profile(forName: "Hammer Curl", group: .arms)
        #expect(hammerCurl.primaryMuscles == [.forearms, .biceps])
        #expect(hammerCurl.secondaryMuscles.isEmpty)
    }

    @Test func aFullBodyGuessStillHasAPrimary() {
        let custom = ExerciseMuscleData.profile(forName: "Burpee", group: .fullBody)
        #expect(Set(custom.primaryMuscles) == [.quads, .glutes, .chest, .lats, .shoulders])
        #expect(custom.secondaryMuscles.isEmpty)
    }

    @Test func noMusclesMeansNoPrimary() {
        let other = ExerciseMuscleData.profile(forName: "Stretching", group: .other)
        #expect(other.primaryMuscles.isEmpty)
    }

    @Test func everyStarterExerciseHasAGuide() {
        for name in StarterExerciseCatalog.names {
            let guide = ExerciseGuides.guide(forName: name)
            #expect(guide != nil, "\(name) has no guide")
            #expect(guide?.steps.count ?? 0 >= 3, "\(name) needs at least 3 steps")
            #expect(guide?.mistakes.isEmpty == false, "\(name) has no common mistakes")
        }
    }

    @Test func aCustomExerciseHasNoGuide() {
        #expect(ExerciseGuides.guide(forName: "Burpee") == nil)
    }
}
