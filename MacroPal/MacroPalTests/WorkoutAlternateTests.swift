//
//  WorkoutAlternateTests.swift
//  MacroPalTests
//

import Testing
import Foundation
import SwiftData
@testable import MacroPal

/// Choose Alternate on a plan slot, and the unlogged-set reminder's wording
/// (usability.md, 2026-10-16).
@MainActor
struct WorkoutAlternateTests {
    private let container = try! ModelContainer(
        for: AppSchema.schema,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    private let today = Calendar.current.startOfDay(for: .now).addingTimeInterval(10 * 3600)
    private var tomorrow: Date { Calendar.current.date(byAdding: .day, value: 1, to: today)! }

    private func exercise(_ name: String) -> Exercise {
        let exercise = Exercise(name: name, muscleGroup: .triceps, equipment: "")
        container.mainContext.insert(exercise)
        return exercise
    }

    /// A Push day with one slot of `planned`.
    private func slot(_ planned: Exercise) -> (PlanDay, PlanExercise) {
        let day = PlanDay(name: "Push", focus: "", weekday: 2)
        container.mainContext.insert(day)
        let planExercise = PlanExercise(order: 0, exercise: planned, targetSets: 2)
        planExercise.day = day
        container.mainContext.insert(planExercise)
        return (day, planExercise)
    }

    @Test func anAlternateStandsInForThatDayOnly() {
        let planned = exercise("Single-Arm Triceps Extension"), cable = exercise("Cable Pushdown")
        let (_, planExercise) = slot(planned)
        planExercise.swap(to: cable, on: today)
        #expect(planExercise.exercise(on: today) == cable)
        #expect(planExercise.isSwapped(on: today))
        // Next week's Push is the plan again.
        #expect(planExercise.exercise(on: tomorrow) == planned)
        #expect(planExercise.exercise == planned)
    }

    @Test func choosingThePlannedExerciseUndoesTheSwap() {
        let planned = exercise("Single-Arm Triceps Extension"), cable = exercise("Cable Pushdown")
        let (_, planExercise) = slot(planned)
        planExercise.swap(to: cable, on: today)
        planExercise.swap(to: planned, on: today)
        #expect(!planExercise.isSwapped(on: today))
        #expect(planExercise.alternate == nil)
    }

    @Test func replaceInPlanChangesItForGood() {
        let planned = exercise("Single-Arm Triceps Extension"), cable = exercise("Cable Pushdown")
        let (_, planExercise) = slot(planned)
        planExercise.swap(to: cable, on: today)
        planExercise.replace(with: cable)
        #expect(planExercise.exercise == cable)
        #expect(!planExercise.isSwapped(on: today))
        #expect(planExercise.exercise(on: tomorrow) == cable)
    }

    @Test func theDaysProgressCountsTheAlternatesSets() {
        let planned = exercise("Single-Arm Triceps Extension"), cable = exercise("Cable Pushdown")
        let (day, planExercise) = slot(planned)
        planExercise.swap(to: cable, on: today)
        let session = WorkoutSession(date: today)
        container.mainContext.insert(session)
        for number in 1...2 {
            let entry = WorkoutSetEntry(setNumber: number, weightKg: 20, reps: 10, exercise: cable)
            entry.session = session
            container.mainContext.insert(entry)
        }
        let progress = DayProgress(day: day, session: session)
        #expect(progress.setsLogged == 2)
        #expect(progress.isComplete)
    }

    @Test func theReminderNamesTheSetAndExercise() {
        let text = UnloggedSetReminder.content(exerciseName: "Single-Arm Triceps Extension", setNumber: 2)
        #expect(text.title == "Set 2 isn't logged yet")
        #expect(text.body.hasPrefix("Single-Arm Triceps Extension:"))
    }
}

/// My Meals variations: a copy of a meal with one ingredient swapped, kept beside the original.
@MainActor
struct MealVariationTests {
    private let container = try! ModelContainer(
        for: AppSchema.schema,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    private func ingredient(_ name: String, grams: Double, kcalPer100g: Double) -> MealIngredient {
        let ingredient = MealIngredient(
            nameSnapshot: name, quantityG: grams, caloriesPer100gSnapshot: kcalPer100g,
            proteinPer100gSnapshot: 0, carbPer100gSnapshot: 0, fatPer100gSnapshot: 0
        )
        container.mainContext.insert(ingredient)
        return ingredient
    }

    /// Yogurt (200 g, 60 kcal/100g) and nuts (30 g, 600 kcal/100g): 300 kcal.
    private func yogurtBowl() -> FoodItem {
        let meal = FoodItem(name: "Yogurt Bowl", caloriesPer100g: 0, proteinG: 0, carbG: 0, fatG: 0,
                            defaultServingSizeG: 0, isMeal: true)
        container.mainContext.insert(meal)
        meal.ingredients = [ingredient("Yogurt", grams: 200, kcalPer100g: 60), ingredient("Nuts", grams: 30, kcalPer100g: 600)]
        meal.recomputeAggregateFromIngredients()
        return meal
    }

    @Test func aVariationCopiesTheMealWithoutTouchingIt() {
        let original = yogurtBowl()
        let variation = original.makeVariation(in: container.mainContext)
        #expect(variation.name == "Yogurt Bowl (Variation 1)")
        #expect(variation.isMeal)
        #expect(variation.variantOf == original)
        #expect(variation.ingredients.map(\.nameSnapshot).sorted() == ["Nuts", "Yogurt"])
        #expect(abs(variation.mealCalories - 300) < 0.01)

        // Swap nuts for berries on the variation only.
        let nuts = variation.ingredients.first { $0.nameSnapshot == "Nuts" }!
        variation.ingredients.removeAll { $0 === nuts }
        variation.ingredients.append(ingredient("Berries", grams: 100, kcalPer100g: 50))
        variation.recomputeAggregateFromIngredients()
        #expect(abs(variation.mealCalories - 170) < 0.01)
        #expect(abs(original.mealCalories - 300) < 0.01)
        #expect(original.ingredients.map(\.nameSnapshot).sorted() == ["Nuts", "Yogurt"])
    }

    @Test func variationsShareOneFamilyWithTheOriginalFirst() {
        let original = yogurtBowl()
        let first = original.makeVariation(in: container.mainContext)
        // A variation of a variation joins the original's family.
        let second = first.makeVariation(in: container.mainContext)
        #expect(second.variantOf == original)
        #expect(second.name == "Yogurt Bowl (Variation 2)")
        #expect(first.mealFamily == [original, first, second])
        #expect(original.mealFamily == [original, first, second])
    }

    @Test func chipsShowWhatAVariationChanges() {
        let original = yogurtBowl()
        let variation = original.makeVariation(in: container.mainContext)
        #expect(original.variationLabel == "Original")
        #expect(variation.variationLabel == "Variation 1")
        variation.name = "Yogurt Bowl with Berries"
        #expect(variation.variationLabel == "with Berries")
        variation.name = "Berry Bowl"
        #expect(variation.variationLabel == "Berry Bowl")
    }
}
