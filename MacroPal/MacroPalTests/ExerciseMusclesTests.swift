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
        #expect(deadlift.secondaryMuscles == [.traps, .quads, .forearms, .lats, .adductors])
    }

    @Test func primaryIsOrderedByInvolvement() {
        let hammerCurl = ExerciseMuscleData.profile(forName: "Hammer Curl", group: .biceps)
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

    // MARK: Drawings

    /// Everkinetic has no fair drawing for these, so they show none.
    static let startersWithoutDrawing: Set<String> = [
        "Face Pull", "Hip Thrust", "Plank", "Hanging Leg Raise", "Dumbbell Shoulder Press",
        "Cable Lateral Raise", "Machine Shoulder Press", "Chest-Supported Dumbbell Row", "Machine Ab Crunch",
    ]

    @Test func everyOtherStarterExerciseHasADrawing() {
        for name in StarterExerciseCatalog.names {
            let hasDrawing = ExerciseIllustration(exerciseName: name) != nil
            #expect(hasDrawing != Self.startersWithoutDrawing.contains(name), "\(name): drawing is \(hasDrawing ? "there" : "missing")")
        }
    }

    @Test func theAdductorMachineWorksTheAdductors() {
        let profile = ExerciseMuscleData.profile(forName: "Adductor Machine", group: .legs)
        #expect(profile.primaryMuscles == [.adductors])
        #expect(BodyFigure.muscles(on: .front).contains(.adductors))
        #expect(BodyFigure.muscles(on: .back).contains(.adductors))
    }

    @Test func drawingNamesComeFromTheExerciseName() {
        #expect(ExerciseIllustration.slug(for: "One-Arm Dumbbell Row") == "one-arm-dumbbell-row")
        #expect(ExerciseIllustration(exerciseName: "Burpee") == nil)
    }
}
