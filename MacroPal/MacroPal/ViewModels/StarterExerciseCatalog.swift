//
//  StarterExerciseCatalog.swift
//  MacroPal
//

import Foundation
import SwiftData

/// A common-lifts starting point so a new user isn't staring at an empty exercise picker.
enum StarterExerciseCatalog {
    /// Set by the first version of the catalog, which seeded everything at once.
    private static let seededKey = "starterExercisesSeeded"
    private static let seededNamesKey = "starterExercisesSeededNames"

    private static let entries: [(name: String, group: MuscleGroup, equipment: String)] = [
        // Chest
        ("Barbell Bench Press", .chest, "Barbell"),
        ("Incline Barbell Bench Press", .chest, "Barbell"),
        ("Dumbbell Bench Press", .chest, "Dumbbell"),
        ("Incline Dumbbell Press", .chest, "Dumbbell"),
        ("Machine Chest Press", .chest, "Machine"),
        ("Cable Chest Fly", .chest, "Cable"),
        ("Push-Up", .chest, "Bodyweight"),
        ("Chest Dip", .chest, "Bodyweight"),
        // Back
        ("Deadlift", .back, "Barbell"),
        ("Pull-Up", .back, "Bodyweight"),
        ("Lat Pulldown", .back, "Cable"),
        ("Barbell Row", .back, "Barbell"),
        ("Seated Cable Row", .back, "Cable"),
        ("One-Arm Dumbbell Row", .back, "Dumbbell"),
        ("Face Pull", .back, "Cable"),
        // Rear delts sit under Back so they're suggested on Pull days, next to Face Pull.
        ("Rear Delt Fly", .back, "Dumbbell"),
        ("Single-Arm Cable Rear Delt Fly", .back, "Cable"),
        ("Chest-Supported Dumbbell Row", .back, "Dumbbell"),
        ("Close-Grip Row", .back, "Cable"),
        ("Floor Back Extension", .back, "Bodyweight"),
        // Shoulders
        ("Overhead Press", .shoulders, "Barbell"),
        ("Dumbbell Shoulder Press", .shoulders, "Dumbbell"),
        ("Lateral Raise", .shoulders, "Dumbbell"),
        ("Cable Lateral Raise", .shoulders, "Cable"),
        ("Machine Shoulder Press", .shoulders, "Machine"),
        // Arms: Biceps, then Triceps
        ("Barbell Curl", .biceps, "Barbell"),
        ("Dumbbell Curl", .biceps, "Dumbbell"),
        ("Hammer Curl", .biceps, "Dumbbell"),
        ("Preacher Curl", .biceps, "EZ bar"),
        ("Triceps Pushdown", .triceps, "Cable"),
        ("Skull Crusher", .triceps, "Barbell"),
        ("Overhead Triceps Extension", .triceps, "Dumbbell"),
        ("Single-Arm Triceps Extension", .triceps, "Dumbbell"),
        ("Single-Arm Cable Triceps Extension", .triceps, "Cable"),
        // Legs
        ("Back Squat", .legs, "Barbell"),
        ("Front Squat", .legs, "Barbell"),
        ("Romanian Deadlift", .legs, "Barbell"),
        ("Leg Press", .legs, "Machine"),
        ("Walking Lunge", .legs, "Dumbbell"),
        ("Bulgarian Split Squat", .legs, "Dumbbell"),
        ("Leg Extension", .legs, "Machine"),
        ("Leg Curl", .legs, "Machine"),
        ("Seated Leg Curl", .legs, "Machine"),
        ("Adductor Machine", .legs, "Machine"),
        ("Hip Thrust", .legs, "Barbell"),
        ("Standing Calf Raise", .legs, "Machine"),
        // Core
        ("Plank", .core, "Bodyweight"),
        ("Hanging Leg Raise", .core, "Bodyweight"),
        ("Cable Crunch", .core, "Cable"),
        ("Ab Wheel Rollout", .core, "Ab wheel"),
        ("Machine Ab Crunch", .core, "Machine"),
    ]

    /// Every starter exercise's name, for checks that each one has its data.
    static var names: [String] { entries.map(\.name) }

    /// Starters added after the first catalog, so installs seeded before them still get them.
    static let addedLater: Set<String> = [
        "Machine Chest Press", "Single-Arm Triceps Extension", "Cable Lateral Raise",
        "Machine Shoulder Press", "Chest-Supported Dumbbell Row", "Close-Grip Row",
        "Single-Arm Cable Rear Delt Fly", "Preacher Curl", "Seated Leg Curl",
        "Floor Back Extension", "Adductor Machine", "Machine Ab Crunch",
        "Single-Arm Cable Triceps Extension",
    ]

    /// Inserts each starter exercise once per install, skipping any name the user already has.
    /// Which starters were seeded is remembered, so one the user deletes stays deleted, and a
    /// starter added in an update still arrives.
    static func seedIfNeeded(in context: ModelContext, defaults: UserDefaults = .standard) {
        var seeded = Set(defaults.stringArray(forKey: seededNamesKey) ?? [])
        if seeded.isEmpty, defaults.bool(forKey: seededKey) {
            // Seeded before the names were remembered: that was the whole first catalog.
            seeded = Set(names).subtracting(addedLater)
        }
        let existing = Set(((try? context.fetch(FetchDescriptor<Exercise>())) ?? []).map { $0.name.lowercased() })
        for entry in entries where !seeded.contains(entry.name) {
            if !existing.contains(entry.name.lowercased()) {
                context.insert(Exercise(name: entry.name, muscleGroup: entry.group, equipment: entry.equipment))
            }
            seeded.insert(entry.name)
        }
        defaults.set(seeded.sorted(), forKey: seededNamesKey)
    }

    /// Starters that changed heading after they were seeded: lowercased name → the group they
    /// left and the one they moved to. Only moved while still in the old group.
    private static let moved: [String: (from: MuscleGroup, to: MuscleGroup)] = [
        "rear delt fly": (.shoulders, .back),
        "single-arm cable rear delt fly": (.shoulders, .back),
    ]

    /// Starters renamed after they were seeded: lowercased old name → new name.
    private static let renamed: [String: String] = [
        // The in-front-of-you extension (user, 2026-09-23); it was briefly called a pushdown.
        "single-arm cable triceps pushdown": "Single-Arm Cable Triceps Extension",
    ]

    /// Starters taken back out of the catalog. Removed from a store only while no logged set
    /// or plan uses them; otherwise they stay as the user's own exercise.
    private static let retired: Set<String> = ["single-arm overhead cable triceps extension"]

    /// Brings stored exercises up to the current catalog: the old Arms group splits into
    /// Biceps and Triceps, `moved` starters change heading, `renamed` ones take their new name
    /// and unused `retired` ones go. Runs at every launch, before seeding; once there's nothing
    /// left to change it only reads.
    static func regroup(in context: ModelContext) {
        var exercises = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        var names = Set(exercises.map { $0.name.lowercased() })
        for exercise in exercises {
            if exercise.muscleGroup == .arms {
                exercise.muscleGroup = armGroup(forName: exercise.name)
            } else if let move = moved[exercise.name.lowercased()], exercise.muscleGroup == move.from {
                exercise.muscleGroup = move.to
            }
            if let newName = renamed[exercise.name.lowercased()], !names.contains(newName.lowercased()) {
                names.insert(newName.lowercased())
                exercise.name = newName
            }
        }

        exercises = exercises.filter { retired.contains($0.name.lowercased()) }
        guard !exercises.isEmpty else { return }
        let sets = (try? context.fetch(FetchDescriptor<WorkoutSetEntry>())) ?? []
        let planned = (try? context.fetch(FetchDescriptor<PlanExercise>())) ?? []
        let used = Set(sets.compactMap(\.exercise?.persistentModelID) + planned.compactMap(\.exercise?.persistentModelID))
        for exercise in exercises where !used.contains(exercise.persistentModelID) {
            context.delete(exercise)
        }
    }

    /// Triceps when the name says so or the triceps are the main mover, otherwise Biceps.
    static func armGroup(forName name: String) -> MuscleGroup {
        let lowered = name.lowercased()
        let tricepsWords = ["tricep", "pushdown", "skull", "kickback", "extension", "dip"]
        if tricepsWords.contains(where: lowered.contains) { return .triceps }
        let primary = ExerciseMuscleData.profile(forName: name, group: .arms).primaryMuscles
        return primary.first == .triceps ? .triceps : .biceps
    }
}
