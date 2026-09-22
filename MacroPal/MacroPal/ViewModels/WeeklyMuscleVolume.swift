//
//  WeeklyMuscleVolume.swift
//  MacroPal
//

import Foundation

/// How much each muscle has been trained this calendar week, for the body map's "Weekly" view.
///
/// Volume is counted in sets: a set gives a muscle 1 when it's a main mover (involvement
/// ≥ 0.8) and ½ when it assists (≥ 0.5), the usual way hypertrophy research tallies direct vs.
/// indirect work. The bands roughly follow the common "10–20 hard sets per muscle per week"
/// guidance — a rule of thumb, not a prescription.
enum WeeklyMuscleVolume {
    static let bandNames = ["1–4 sets", "5–9 sets", "10–19 sets", "20+ sets"]
    /// Lowest set count of bands 2…4; anything above zero is at least band 1.
    private static let bandFloors: [Double] = [5, 10, 20]

    /// Set count per muscle for the calendar week containing `now`. Untrained muscles are absent.
    static func sets(from sets: [LoggedSet], now: Date = .now, calendar: Calendar = .current) -> [Muscle: Double] {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else { return [:] }
        var volume: [Muscle: Double] = [:]
        for set in sets where week.contains(set.date) && set.date <= now {
            let profile = ExerciseMuscleData.profile(forName: set.exerciseName, group: set.muscleGroup)
            for (muscle, involvement) in profile.muscles {
                let credit = involvement >= 0.8 ? 1 : involvement >= 0.5 ? 0.5 : 0
                if credit > 0 { volume[muscle, default: 0] += credit }
            }
        }
        return volume
    }

    /// Band 1…4 for a set count (0 = untrained this week).
    static func band(forSets sets: Double) -> Int {
        guard sets > 0 else { return 0 }
        return 1 + bandFloors.filter { sets >= $0 }.count
    }
}
