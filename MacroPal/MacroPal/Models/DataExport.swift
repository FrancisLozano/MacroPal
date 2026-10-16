//
//  DataExport.swift
//  MacroPal
//

import Foundation
import SwiftData

/// Everything the user has logged, as one JSON file they can keep outside the app. The store
/// lives on this iPhone only (iCloud sync is skipped), so this is the backup.
///
/// Values keep the units they're stored in (kg, g, kcal; dates to the second) and the key
/// names say so. Records point at each other by name ("exercise": "Face Pull"), not by store
/// IDs, so the file reads on its own. Bump `currentVersion` when a field's meaning changes, so
/// a later import can tell old files apart.
struct DataExport: Codable, Equatable {
    static let currentVersion = 1

    var app = "MacroPal"
    var version = DataExport.currentVersion
    var exportedAt: Date
    var profile: Profile?
    var foods: [Food]
    var foodLog: [LoggedFood]
    var weights: [Weight]
    var steps: [Steps]
    var exercises: [ExerciseRecord]
    var plan: [PlanDayRecord]
    var workouts: [Workout]

    struct Profile: Codable, Equatable {
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
        var stepGoal: Int
        var priorTrainingMonths: Int
        var priorTrainingEnteredOn: Date?
    }

    /// A saved food or meal, macros per 100 g.
    struct Food: Codable, Equatable {
        var name: String
        var brand: String?
        var caloriesPer100g: Double
        var proteinPer100g: Double
        var carbPer100g: Double
        var fatPer100g: Double
        var defaultServingSizeG: Double
        var servingUnitLabel: String?
        var barcode: String?
        var isMeal: Bool
        /// The original meal's name when this meal is a variation of it.
        var variationOf: String? = nil
        var ingredients: [Ingredient]
    }

    struct Ingredient: Codable, Equatable {
        var name: String
        var brand: String?
        var quantityG: Double
        var caloriesPer100g: Double
        var proteinPer100g: Double
        var carbPer100g: Double
        var fatPer100g: Double
    }

    /// One food logged to a meal, with the macros of the amount eaten.
    struct LoggedFood: Codable, Equatable {
        var date: Date
        var meal: MealType
        var name: String
        var brand: String?
        var servingSizeG: Double
        var caloriesKcal: Double
        var proteinG: Double
        var carbG: Double
        var fatG: Double
        var ingredients: [Ingredient]
    }

    struct Weight: Codable, Equatable {
        var date: Date
        var weightKg: Double
        var notes: String?
    }

    struct Steps: Codable, Equatable {
        var day: Date
        var steps: Int
    }

    struct ExerciseRecord: Codable, Equatable {
        var name: String
        var muscleGroup: MuscleGroup
        var equipment: String
    }

    struct PlanDayRecord: Codable, Equatable {
        var name: String
        var focus: String
        /// Calendar weekday, 1 = Sunday.
        var weekday: Int
        var exercises: [PlanExerciseRecord]
    }

    struct PlanExerciseRecord: Codable, Equatable {
        var exercise: String?
        var targetSets: Int
        var targetReps: Int
        var targetRepsMax: Int?
    }

    struct Workout: Codable, Equatable {
        var date: Date
        var notes: String?
        var sets: [WorkoutSet]
    }

    struct WorkoutSet: Codable, Equatable {
        var exercise: String?
        var setNumber: Int
        var weightKg: Double
        var reps: Int
        var rpe: Double?
        var planDay: String?
    }
}

// MARK: - Building

extension DataExport {
    /// Reads the whole store. Nothing is written, so it's safe on the main context.
    init(from context: ModelContext, exportedAt: Date = .now) throws {
        self.exportedAt = exportedAt

        profile = try context.fetch(FetchDescriptor<UserProfile>()).first.map {
            Profile(
                heightCm: $0.heightCm, birthDate: $0.birthDate, sex: $0.sex,
                activityLevel: $0.activityLevel, goal: $0.goal, goalWeightKg: $0.goalWeightKg,
                calorieTarget: $0.calorieTarget, proteinTargetG: $0.proteinTargetG,
                carbTargetG: $0.carbTargetG, fatTargetG: $0.fatTargetG, stepGoal: $0.stepGoal,
                priorTrainingMonths: $0.priorTrainingMonths,
                priorTrainingEnteredOn: $0.priorTrainingEnteredOn
            )
        }

        foods = try context.fetch(FetchDescriptor<FoodItem>(sortBy: [SortDescriptor(\.name)])).map {
            Food(
                name: $0.name, brand: $0.brand, caloriesPer100g: $0.caloriesPer100g,
                proteinPer100g: $0.proteinG, carbPer100g: $0.carbG, fatPer100g: $0.fatG,
                defaultServingSizeG: $0.defaultServingSizeG, servingUnitLabel: $0.servingUnitLabel,
                barcode: $0.barcode, isMeal: $0.isMeal, variationOf: $0.variantOf?.name,
                ingredients: Self.ingredients($0.ingredients)
            )
        }

        foodLog = try context.fetch(FetchDescriptor<FoodEntry>(sortBy: [SortDescriptor(\.date)])).map {
            LoggedFood(
                date: $0.date, meal: $0.mealType, name: $0.nameSnapshot, brand: $0.brandSnapshot,
                servingSizeG: $0.servingSizeG, caloriesKcal: $0.caloriesKcal,
                proteinG: $0.proteinG, carbG: $0.carbG, fatG: $0.fatG,
                ingredients: Self.ingredients($0.ingredientSnapshots)
            )
        }

        weights = try context.fetch(FetchDescriptor<WeightEntry>(sortBy: [SortDescriptor(\.date)])).map {
            Weight(date: $0.date, weightKg: $0.weightKg, notes: $0.notes)
        }

        steps = try context.fetch(FetchDescriptor<StepEntry>(sortBy: [SortDescriptor(\.day)])).map {
            Steps(day: $0.day, steps: $0.steps)
        }

        exercises = try context.fetch(FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.name)])).map {
            ExerciseRecord(name: $0.name, muscleGroup: $0.muscleGroup, equipment: $0.equipment)
        }

        // The app uses the first plan, same as the Current Plan card.
        plan = try context.fetch(FetchDescriptor<WorkoutPlan>()).first?.sortedDays.map { day in
            PlanDayRecord(
                name: day.name, focus: day.focus, weekday: day.weekday,
                exercises: day.sortedExercises.map {
                    PlanExerciseRecord(
                        exercise: $0.exercise?.name, targetSets: $0.targetSets,
                        targetReps: $0.targetReps, targetRepsMax: $0.targetRepsMax
                    )
                }
            )
        } ?? []

        workouts = try context.fetch(FetchDescriptor<WorkoutSession>(sortBy: [SortDescriptor(\.date)])).map { session in
            Workout(
                date: session.date, notes: session.notes,
                sets: session.setEntries
                    .sorted { ($0.exercise?.name ?? "", $0.setNumber) < ($1.exercise?.name ?? "", $1.setNumber) }
                    .map {
                        WorkoutSet(
                            exercise: $0.exercise?.name, setNumber: $0.setNumber,
                            weightKg: $0.weightKg, reps: $0.reps, rpe: $0.rpe, planDay: $0.planDayName
                        )
                    }
            )
        }
    }

    private static func ingredients(_ list: [MealIngredient]) -> [Ingredient] {
        list.map {
            Ingredient(
                name: $0.nameSnapshot, brand: $0.brandSnapshot, quantityG: $0.quantityG,
                caloriesPer100g: $0.caloriesPer100gSnapshot, proteinPer100g: $0.proteinPer100gSnapshot,
                carbPer100g: $0.carbPer100gSnapshot, fatPer100g: $0.fatPer100gSnapshot
            )
        }
    }
}

// MARK: - JSON

extension DataExport {
    static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    func jsonData() throws -> Data {
        try Self.encoder().encode(self)
    }

    /// "MacroPal Export 2026-10-13.json"
    static func fileName(for date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "MacroPal Export %04d-%02d-%02d.json", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    /// Writes the JSON to a temporary file for the share sheet and returns its URL.
    func writeTemporaryFile(calendar: Calendar = .current) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(Self.fileName(for: exportedAt, calendar: calendar))
        try jsonData().write(to: url, options: .atomic)
        return url
    }
}
