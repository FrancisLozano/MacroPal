//
//  ExerciseCatalogTests.swift
//  MacroPalTests
//

import Testing
import Foundation
import SwiftData
@testable import MacroPal

@MainActor
struct ExerciseCatalogTests {
    private let container = try! ModelContainer(
        for: AppSchema.schema,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    private func freshDefaults() -> UserDefaults {
        let name = "ExerciseCatalogTests-\(UUID().uuidString)"
        return UserDefaults(suiteName: name)!
    }

    private func names(in context: ModelContext) -> Set<String> {
        Set(((try? context.fetch(FetchDescriptor<Exercise>())) ?? []).map(\.name))
    }

    // MARK: Picker headings

    @Test func pickerHeadingsFollowTheChosenOrderAndSkipEmptyGroups() {
        let exercises = [
            Exercise(name: "Plank", muscleGroup: .core, equipment: ""),
            Exercise(name: "Barbell Curl", muscleGroup: .biceps, equipment: ""),
            Exercise(name: "Skull Crusher", muscleGroup: .triceps, equipment: ""),
            Exercise(name: "Barbell Bench Press", muscleGroup: .chest, equipment: ""),
            Exercise(name: "Machine Chest Press", muscleGroup: .chest, equipment: ""),
        ]
        let sections = ExercisePickerView.sections(exercises)
        #expect(sections.map(\.group) == [.chest, .triceps, .biceps, .core])
        #expect(sections[0].exercises.map(\.name) == ["Barbell Bench Press", "Machine Chest Press"])
        #expect(MuscleGroup.core.displayName == "Abs")
    }

    // MARK: Arms → Biceps / Triceps

    @Test func armExercisesSplitIntoBicepsAndTriceps() {
        #expect(StarterExerciseCatalog.armGroup(forName: "Hammer Curl") == .biceps)
        #expect(StarterExerciseCatalog.armGroup(forName: "Skull Crusher") == .triceps)
        #expect(StarterExerciseCatalog.armGroup(forName: "Overhead Triceps Extension") == .triceps)
        // Custom exercises go by their name, and default to Biceps.
        #expect(StarterExerciseCatalog.armGroup(forName: "Cable Kickback") == .triceps)
        #expect(StarterExerciseCatalog.armGroup(forName: "Spider Curl") == .biceps)
    }

    @Test func storedExercisesMoveToTheirNewHeadingAtLaunch() {
        let context = container.mainContext
        let pushdown = Exercise(name: "Triceps Pushdown", muscleGroup: .arms, equipment: "Cable")
        let curl = Exercise(name: "Barbell Curl", muscleGroup: .arms, equipment: "Barbell")
        let rearDelt = Exercise(name: "Rear Delt Fly", muscleGroup: .shoulders, equipment: "Dumbbell")
        let lateral = Exercise(name: "Lateral Raise", muscleGroup: .shoulders, equipment: "Dumbbell")
        [pushdown, curl, rearDelt, lateral].forEach(context.insert)
        StarterExerciseCatalog.regroup(in: context)
        #expect(pushdown.muscleGroup == .triceps)
        #expect(curl.muscleGroup == .biceps)
        #expect(rearDelt.muscleGroup == .back)
        #expect(lateral.muscleGroup == .shoulders)
    }

    // MARK: Seeding

    @Test func aFreshInstallGetsEveryStarter() {
        let context = container.mainContext
        StarterExerciseCatalog.seedIfNeeded(in: context, defaults: freshDefaults())
        #expect(names(in: context) == Set(StarterExerciseCatalog.names))
    }

    @Test func anInstallSeededBeforeGetsOnlyTheNewStarters() {
        let context = container.mainContext
        let defaults = freshDefaults()
        defaults.set(true, forKey: "starterExercisesSeeded")
        context.insert(Exercise(name: "Barbell Bench Press", muscleGroup: .chest, equipment: "Barbell"))

        StarterExerciseCatalog.seedIfNeeded(in: context, defaults: defaults)
        // Starters deleted since the first seeding stay deleted; the new ones arrive.
        #expect(names(in: context) == StarterExerciseCatalog.addedLater.union(["Barbell Bench Press"]))
        #expect(StarterExerciseCatalog.addedLater.isSubset(of: StarterExerciseCatalog.names))
    }

    @Test func aDeletedStarterStaysDeleted() throws {
        let context = container.mainContext
        let defaults = freshDefaults()
        StarterExerciseCatalog.seedIfNeeded(in: context, defaults: defaults)
        let press = try #require(try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "Machine Chest Press" })
        context.delete(press)

        StarterExerciseCatalog.seedIfNeeded(in: context, defaults: defaults)
        #expect(!names(in: context).contains("Machine Chest Press"))
    }
}
