//
//  PastTrainingView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// Profile → Workout → Past Training: start the muscle levels over (only sets logged in
/// MacroPal count), or count how long you trained before — as time trained and as the volume
/// that much training builds, for the muscles your current plan works (see `PriorTraining`).
struct PastTrainingView: View {
    @Bindable var profile: UserProfile

    @Query private var plans: [WorkoutPlan]
    @Query(sort: \WeightEntry.date, order: .reverse) private var weightEntries: [WeightEntry]

    /// Kept while Start Over is picked, so switching back restores the time.
    @State private var months: Int
    @State private var countsPastTraining: Bool

    private let viewModel = ProfileViewModel()

    init(profile: UserProfile) {
        self.profile = profile
        _months = State(initialValue: max(profile.priorTrainingMonths, 12))
        _countsPastTraining = State(initialValue: profile.priorTrainingMonths > 0)
    }

    private var years: Binding<Int> {
        Binding(get: { months / 12 }, set: { months = max($0 * 12 + months % 12, 1) })
    }

    private var extraMonths: Binding<Int> {
        Binding(get: { months % 12 }, set: { months = max(months / 12 * 12 + $0, 1) })
    }

    private var planWorksMuscles: Bool {
        !PriorTraining.involvement(of: plans.first).isEmpty
    }

    var body: some View {
        Form {
            Section {
                Picker("Levels", selection: $countsPastTraining) {
                    Text("Start Over").tag(false)
                    Text("Count Past Training").tag(true)
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } footer: {
                Text(countsPastTraining
                     ? "Muscle levels start where your past training puts them, then grow with what you log."
                     : "Muscle levels come only from the sets you log in MacroPal.")
            }

            if countsPastTraining {
                Section {
                    Stepper("\(years.wrappedValue) \(years.wrappedValue == 1 ? "year" : "years")", value: years, in: 0...20)
                    Stepper("\(extraMonths.wrappedValue) \(extraMonths.wrappedValue == 1 ? "month" : "months")", value: extraMonths, in: 0...11)
                } header: {
                    Text("Trained Before MacroPal")
                } footer: {
                    Text(footer)
                }
            }
        }
        .navigationTitle("Past Training")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: countsPastTraining) { save() }
        .onChange(of: months) { save() }
    }

    /// What the time works out to, and anything that keeps it from showing.
    private var footer: String {
        let level = MuscleLevelEngine.levelNames[MuscleLevelEngine.startingLevel(afterMonths: Double(months)) - 1]
        var lines = [
            "\(viewModel.pastTrainingSummary(months: months)) counts as time trained and as the volume steady training builds in that time, for the muscles your current plan works. The ones it works most start at \(level); ones it only helps with get a share of the volume.",
        ]
        if !planWorksMuscles {
            lines.append("Add exercises to your plan first — past training goes to the muscles it works.")
        } else if weightEntries.isEmpty {
            lines.append("Log your weight to see the levels — until then trained muscles show as Beginner.")
        }
        return lines.joined(separator: "\n\n")
    }

    /// Re-takes the plan's muscles each time, so the credit follows the plan as it is now.
    private func save() {
        profile.setPriorTraining(months: countsPastTraining ? months : 0, plan: plans.first)
    }
}

#Preview {
    let container = try! ModelContainer(for: AppSchema.schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let profile = UserProfile()
    container.mainContext.insert(profile)
    return NavigationStack {
        PastTrainingView(profile: profile)
    }
    .modelContainer(container)
}
