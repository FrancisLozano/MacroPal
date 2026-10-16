//
//  WorkoutPreferences.swift
//  MacroPal
//

import Foundation

/// `@AppStorage` keys and defaults for Profile → Workout. They're device preferences, like
/// the lb/kg setting, so they live in `UserDefaults` rather than the SwiftData store.
enum WorkoutPreferences {
    /// Set rows read "135 lb × 10 reps" instead of "10 reps × 135 lb".
    static let weightFirstKey = "workoutWeightFirst"
    static let weightFirstDefault = false

    /// Targets for an exercise newly added to a plan day, and rows for an unplanned exercise.
    static let defaultSetsKey = "workoutDefaultSets"
    static let defaultSetsDefault = 3
    static let defaultRepsKey = "workoutDefaultReps"
    static let defaultRepsDefault = 10
    /// Top of a default rep range; 0 means a single number.
    static let defaultRepsMaxKey = "workoutDefaultRepsMax"
    static let defaultRepsMaxDefault = 0

    static let restSecondsKey = "workoutRestSeconds"
    static let restSecondsDefault = 120
    /// Rest choices offered in the picker, in seconds.
    static let restChoices = [30, 45, 60, 90, 120, 150, 180, 240, 300]

    /// Start the rest countdown automatically when a set logs and when an exercise is
    /// completed. On unless turned off (usability.md, 2026-09-25); a stored choice is kept.
    static let autoRestTimerKey = "workoutAutoRestTimer"
    static let autoRestTimerDefault = true

    /// A notification when a set logs and the exercise's next one isn't logged five minutes
    /// later (`UnloggedSetReminder`). On unless turned off (usability.md, 2026-10-16).
    static let unloggedSetReminderKey = "workoutUnloggedSetReminder"
    static let unloggedSetReminderDefault = true

    /// What a set's "Last:" line (and its grey numbers) repeat. Same Set Last Workout by
    /// default, for progressive overload (usability.md, 2026-10-16).
    static let lastSourceKey = "workoutLastSource"
    static let lastSourceDefault = LastSetSource.lastWorkout

    /// "8–10" or "10".
    static func repsLabel(reps: Int, repsMax: Int) -> String {
        repsMax > reps ? "\(reps)–\(repsMax)" : "\(reps)"
    }

    /// "90 s", "2 min", "2 min 30 s".
    static func restLabel(seconds: Int) -> String {
        let minutes = seconds / 60, rest = seconds % 60
        switch (minutes, rest) {
        case (0, _): return "\(rest) s"
        case (_, 0): return "\(minutes) min"
        default: return "\(minutes) min \(rest) s"
        }
    }
}

/// Where a set's "Last:" line comes from (Profile → Workout → "Last:" Shows).
enum LastSetSource: String, CaseIterable, Identifiable {
    /// Set 2 repeats set 2 of the previous session: beat each set where it was.
    case lastWorkout
    /// Set 2 repeats the set just logged above it today: keep the weight steady across sets.
    case previousSet

    var id: Self { self }

    var title: String {
        switch self {
        case .lastWorkout: "Same Set Last Workout"
        case .previousSet: "Set You Just Did"
        }
    }
}
