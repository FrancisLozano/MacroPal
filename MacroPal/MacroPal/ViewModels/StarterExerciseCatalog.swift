//
//  StarterExerciseCatalog.swift
//  MacroPal
//

import Foundation
import SwiftData

/// A common-lifts starting point so a new user isn't staring at an empty exercise picker.
enum StarterExerciseCatalog {
    private static let seededKey = "starterExercisesSeeded"

    private static let entries: [(name: String, group: MuscleGroup, equipment: String)] = [
        // Chest
        ("Barbell Bench Press", .chest, "Barbell"),
        ("Incline Barbell Bench Press", .chest, "Barbell"),
        ("Dumbbell Bench Press", .chest, "Dumbbell"),
        ("Incline Dumbbell Press", .chest, "Dumbbell"),
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
        // Shoulders
        ("Overhead Press", .shoulders, "Barbell"),
        ("Dumbbell Shoulder Press", .shoulders, "Dumbbell"),
        ("Lateral Raise", .shoulders, "Dumbbell"),
        ("Rear Delt Fly", .shoulders, "Dumbbell"),
        // Arms
        ("Barbell Curl", .arms, "Barbell"),
        ("Dumbbell Curl", .arms, "Dumbbell"),
        ("Hammer Curl", .arms, "Dumbbell"),
        ("Triceps Pushdown", .arms, "Cable"),
        ("Skull Crusher", .arms, "Barbell"),
        ("Overhead Triceps Extension", .arms, "Dumbbell"),
        // Legs
        ("Back Squat", .legs, "Barbell"),
        ("Front Squat", .legs, "Barbell"),
        ("Romanian Deadlift", .legs, "Barbell"),
        ("Leg Press", .legs, "Machine"),
        ("Walking Lunge", .legs, "Dumbbell"),
        ("Bulgarian Split Squat", .legs, "Dumbbell"),
        ("Leg Extension", .legs, "Machine"),
        ("Leg Curl", .legs, "Machine"),
        ("Hip Thrust", .legs, "Barbell"),
        ("Standing Calf Raise", .legs, "Machine"),
        // Core
        ("Plank", .core, "Bodyweight"),
        ("Hanging Leg Raise", .core, "Bodyweight"),
        ("Cable Crunch", .core, "Cable"),
        ("Ab Wheel Rollout", .core, "Ab wheel"),
    ]

    /// Inserts the catalog once per install, skipping any name the user already has. Not
    /// re-run afterwards, so an exercise the user deletes stays deleted.
    static func seedIfNeeded(in context: ModelContext, defaults: UserDefaults = .standard) {
        guard !defaults.bool(forKey: seededKey) else { return }
        let existing = ((try? context.fetch(FetchDescriptor<Exercise>())) ?? []).map { $0.name.lowercased() }
        let taken = Set(existing)
        for entry in entries where !taken.contains(entry.name.lowercased()) {
            context.insert(Exercise(name: entry.name, muscleGroup: entry.group, equipment: entry.equipment))
        }
        defaults.set(true, forKey: seededKey)
    }
}
