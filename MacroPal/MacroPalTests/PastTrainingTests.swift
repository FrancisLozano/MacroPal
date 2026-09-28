//
//  PastTrainingTests.swift
//  MacroPalTests
//

import Foundation
import Testing
import SwiftData
@testable import MacroPal

struct PastTrainingTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func prior(months: Int, _ involvement: [Muscle: Double]) -> PriorTraining {
        PriorTraining(months: months, enteredOn: now, involvement: involvement)
    }

    @Test func creditFollowsTheLevelsOwnPacing() {
        #expect(MuscleLevelEngine.bodyweights(afterMonths: 0) == 0)
        #expect(MuscleLevelEngine.bodyweights(afterMonths: 3) == 600)
        #expect(MuscleLevelEngine.bodyweights(afterMonths: 12) == 2_500)
        // Halfway from Intermediate (3 months, 600) to Advanced (12 months, 2,500).
        #expect(MuscleLevelEngine.bodyweights(afterMonths: 7.5) == 1_550)
        #expect(MuscleLevelEngine.bodyweights(afterMonths: 120) == 15_000)
    }

    @Test func startingLevelForAMainMover() {
        #expect(MuscleLevelEngine.startingLevel(afterMonths: 0.25) == 1)
        #expect(MuscleLevelEngine.startingLevel(afterMonths: 6) == 3)
        #expect(MuscleLevelEngine.startingLevel(afterMonths: 12) == 4)
        #expect(MuscleLevelEngine.startingLevel(afterMonths: 60) == 6)
    }

    @Test func monthsCountAsTimeAndVolumeWithoutAnySets() {
        let levels = MuscleLevelEngine.levels(
            sets: [], bodyweightKg: 80, sex: .male,
            prior: prior(months: 12, [.chest: 1, .triceps: 0.4]), now: now
        )
        #expect(levels[.chest] == 4)   // Advanced: 2,500 bodyweights, 12 months
        #expect(levels[.triceps] == 3) // Intermediate: 40% of the volume, full time
        #expect(levels[.quads] == nil) // not in the plan, not credited
    }

    @Test func withoutABodyweightCreditedMusclesAreBeginners() {
        let levels = MuscleLevelEngine.levels(sets: [], bodyweightKg: nil, sex: .male, prior: prior(months: 24, [.chest: 1]), now: now)
        #expect(levels == [.chest: 1])
    }

    @Test func progressShowsThePastVolumeInKg() {
        let progress = MuscleLevelEngine.progress(for: .chest, sets: [], bodyweightKg: 80, sex: .male, prior: prior(months: 12, [.chest: 1]), now: now)
        #expect(progress.level == 4)
        #expect(progress.priorVolumeKg == 200_000)
        #expect(progress.volumeKg == 200_000)
        #expect(progress.nextLevelVolumeKg == 600_000)
        // Elite needs 36 months; 12 are in, so it unlocks 24 months from now.
        #expect(progress.nextLevelUnlocks == now.addingTimeInterval(24 * MuscleLevelEngine.secondsPerMonth))
    }

    @Test func loggedSetsAddOnTopOfThePast() {
        let set = LoggedSet(date: now, exerciseName: "Barbell Bench Press", muscleGroup: .chest, weightKg: 100, reps: 10)
        let progress = MuscleLevelEngine.progress(for: .chest, sets: [set], bodyweightKg: 80, sex: .male, prior: prior(months: 12, [.chest: 1]), now: now)
        #expect(progress.volumeKg > progress.priorVolumeKg)
        #expect(progress.contributions.map(\.exerciseName) == ["Barbell Bench Press"])
    }

    @Test func summaryReadsInYearsAndMonths() {
        let viewModel = ProfileViewModel()
        #expect(viewModel.pastTrainingSummary(months: 0) == "Start over")
        #expect(viewModel.pastTrainingSummary(months: 8) == "8 months")
        #expect(viewModel.pastTrainingSummary(months: 12) == "1 year")
        #expect(viewModel.pastTrainingSummary(months: 27) == "2 years 3 months")
    }

    @MainActor
    @Test func savingSnapshotsThePlansMusclesAndStartOverClearsIt() throws {
        let container = try ModelContainer(for: AppSchema.schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let bench = Exercise(name: "Barbell Bench Press", muscleGroup: .chest, equipment: "Barbell")
        let plan = WorkoutPlan()
        let day = PlanDay(name: "Push", focus: "", weekday: 2)
        let planExercise = PlanExercise(order: 0, exercise: bench)
        context.insert(bench); context.insert(plan); context.insert(day); context.insert(planExercise)
        day.plan = plan
        planExercise.day = day
        let profile = UserProfile()
        context.insert(profile)

        profile.setPriorTraining(months: 18, plan: plan, now: now)
        let saved = try #require(profile.priorTraining)
        #expect(saved.months == 18)
        #expect(saved.enteredOn == now)
        #expect(saved.involvement[.chest] == 1)
        #expect((saved.involvement[.triceps] ?? 0) > 0)

        profile.setPriorTraining(months: 0, plan: plan)
        #expect(profile.priorTraining == nil)
        #expect(profile.priorTrainingInvolvement.isEmpty)
    }
}
