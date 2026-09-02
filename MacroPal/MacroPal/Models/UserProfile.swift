//
//  UserProfile.swift
//  MacroPal
//

import Foundation
import SwiftData

enum Sex: String, Codable, CaseIterable, Identifiable {
    case male, female

    var id: Self { self }

    var displayName: String {
        switch self {
        case .male: "Male"
        case .female: "Female"
        }
    }
}

enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
    case sedentary, lightlyActive, moderatelyActive, veryActive

    var id: Self { self }

    var displayName: String {
        switch self {
        case .sedentary: "Sedentary"
        case .lightlyActive: "Lightly Active"
        case .moderatelyActive: "Moderately Active"
        case .veryActive: "Very Active"
        }
    }
}

enum Goal: String, Codable, CaseIterable, Identifiable {
    case cut, maintain, bulk

    var id: Self { self }

    var displayName: String {
        switch self {
        case .cut: "Cut"
        case .maintain: "Maintain"
        case .bulk: "Bulk"
        }
    }
}

/// Single-row model — this is a personal app, so there is only ever one `UserProfile`.
/// Use `UserProfile.current(in:)` to fetch or lazily create it rather than inserting directly.
@Model
final class UserProfile {
    var heightCm: Double
    var birthDate: Date
    var sex: Sex
    var activityLevel: ActivityLevel
    var goal: Goal
    var goalWeightKg: Double
    var calorieTarget: Int
    var proteinTargetG: Int
    var carbTargetG: Int
    var fatTargetG: Int

    init(
        heightCm: Double = 170,
        birthDate: Date = Calendar.current.date(byAdding: .year, value: -25, to: .now) ?? .now,
        sex: Sex = .male,
        activityLevel: ActivityLevel = .sedentary,
        goal: Goal = .maintain,
        goalWeightKg: Double = 70,
        calorieTarget: Int = 2000,
        proteinTargetG: Int = 150,
        carbTargetG: Int = 200,
        fatTargetG: Int = 65
    ) {
        self.heightCm = heightCm
        self.birthDate = birthDate
        self.sex = sex
        self.activityLevel = activityLevel
        self.goal = goal
        self.goalWeightKg = goalWeightKg
        self.calorieTarget = calorieTarget
        self.proteinTargetG = proteinTargetG
        self.carbTargetG = carbTargetG
        self.fatTargetG = fatTargetG
    }

    /// Fetches the single `UserProfile` row, creating one with placeholder defaults on first launch.
    static func current(in context: ModelContext) -> UserProfile {
        if let existing = try? context.fetch(FetchDescriptor<UserProfile>()).first {
            return existing
        }
        let profile = UserProfile()
        context.insert(profile)
        return profile
    }
}
