//
//  ProfileView.swift
//  MacroPal
//

import SwiftUI
import SwiftData
import WidgetKit

/// Fetches the singleton `UserProfile` (creating it on first launch) and shows it as a short
/// overview: a summary row per group that opens its own page, so the top level stays light.
struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    var body: some View {
        Group {
            if let profile = profiles.first {
                ProfileOverview(profile: profile)
            } else {
                ProgressView()
                    .onAppear {
                        _ = UserProfile.current(in: modelContext)
                    }
            }
        }
        .navigationTitle("Profile")
    }
}

private struct ProfileOverview: View {
    @Bindable var profile: UserProfile

    @AppStorage(WeightUnit.storageKey) private var weightUnit: WeightUnit = .lb
    @AppStorage(HeightUnit.storageKey) private var heightUnit: HeightUnit = .cm
    @AppStorage(WorkoutPreferences.weightFirstKey) private var weightFirst = WorkoutPreferences.weightFirstDefault
    @AppStorage(WorkoutPreferences.defaultSetsKey) private var defaultSets = WorkoutPreferences.defaultSetsDefault
    @AppStorage(WorkoutPreferences.defaultRepsKey) private var defaultReps = WorkoutPreferences.defaultRepsDefault
    @AppStorage(WorkoutPreferences.defaultRepsMaxKey) private var defaultRepsMax = WorkoutPreferences.defaultRepsMaxDefault
    @AppStorage(WorkoutPreferences.restSecondsKey) private var restSeconds = WorkoutPreferences.restSecondsDefault
    @AppStorage(WorkoutPreferences.autoRestTimerKey) private var autoRestTimer = WorkoutPreferences.autoRestTimerDefault

    private let viewModel = ProfileViewModel()

    var body: some View {
        List {
            Section("Personal") {
                NavigationLink {
                    PersonalInfoView(profile: profile)
                } label: {
                    summaryRow(
                        "Personal Info",
                        systemImage: "person.text.rectangle",
                        detail: viewModel.personalSummary(
                            sex: profile.sex,
                            birthDate: profile.birthDate,
                            heightCm: profile.heightCm,
                            activityLevel: profile.activityLevel,
                            heightUnit: heightUnit
                        )
                    )
                }
            }

            Section("Workout") {
                NavigationLink {
                    WorkoutSettingsView()
                } label: {
                    summaryRow(
                        "Workout Display & Defaults",
                        systemImage: "dumbbell",
                        detail: viewModel.workoutSummary(
                            weightFirst: weightFirst,
                            sets: defaultSets,
                            reps: defaultReps,
                            repsMax: defaultRepsMax,
                            restSeconds: restSeconds,
                            autoRest: autoRestTimer
                        )
                    )
                }
            }

            Section("Goal & Daily Targets") {
                // One picker doesn't need a page of its own.
                Picker(selection: $profile.goal) {
                    ForEach(Goal.allCases) { goal in
                        Text(goal.displayName).tag(goal)
                    }
                } label: {
                    Label("Goal", systemImage: "target")
                }
                NavigationLink {
                    DailyTargetsView(profile: profile)
                } label: {
                    summaryRow(
                        "Calories & Macros",
                        systemImage: "chart.pie",
                        detail: viewModel.targetsSummary(
                            calorieTarget: profile.calorieTarget,
                            proteinTargetG: profile.proteinTargetG,
                            carbTargetG: profile.carbTargetG,
                            fatTargetG: profile.fatTargetG
                        )
                    )
                }
            }

            Section("Units & Measurements") {
                Picker(selection: $weightUnit) {
                    ForEach(WeightUnit.allCases) { unit in
                        Text(unit.symbol).tag(unit)
                    }
                } label: {
                    Label("Weight", systemImage: "scalemass")
                }
                Picker(selection: $heightUnit) {
                    ForEach(HeightUnit.allCases) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                } label: {
                    Label("Height", systemImage: "ruler")
                }
            }

            Section("About") {
                NavigationLink {
                    AcknowledgementsView()
                } label: {
                    Label("Acknowledgements", systemImage: "heart.text.square")
                }
            }
        }
    }

    private func summaryRow(_ title: String, systemImage: String, detail: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: systemImage)
        }
    }
}

/// Height (in cm or ft/in, per Units & Measurements), birth date, sex and activity level.
private struct PersonalInfoView: View {
    @Bindable var profile: UserProfile
    @AppStorage(HeightUnit.storageKey) private var heightUnit: HeightUnit = .cm

    /// Feet and inches edit the stored cm value through these, one part at a time.
    private var feet: Binding<Int> {
        Binding(
            get: { HeightUnit.feetAndInches(fromCm: profile.heightCm).feet },
            set: { profile.heightCm = HeightUnit.cm(feet: $0, inches: HeightUnit.feetAndInches(fromCm: profile.heightCm).inches) }
        )
    }

    private var inches: Binding<Int> {
        Binding(
            get: { HeightUnit.feetAndInches(fromCm: profile.heightCm).inches },
            set: { profile.heightCm = HeightUnit.cm(feet: HeightUnit.feetAndInches(fromCm: profile.heightCm).feet, inches: min(max($0, 0), 11)) }
        )
    }

    var body: some View {
        Form {
            HStack {
                Text("Height")
                Spacer()
                switch heightUnit {
                case .cm:
                    TextField("Height", value: $profile.heightCm, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    Text("cm")
                        .foregroundStyle(.secondary)
                case .feetInches:
                    TextField("ft", value: feet, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 40)
                    Text("ft")
                        .foregroundStyle(.secondary)
                    TextField("in", value: inches, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 40)
                    Text("in")
                        .foregroundStyle(.secondary)
                }
            }
            DatePicker("Birth Date", selection: $profile.birthDate, displayedComponents: .date)
            Picker("Sex", selection: $profile.sex) {
                ForEach(Sex.allCases) { sex in
                    Text(sex.displayName).tag(sex)
                }
            }
            Picker("Activity Level", selection: $profile.activityLevel) {
                ForEach(ActivityLevel.allCases) { level in
                    Text(level.displayName).tag(level)
                }
            }
        }
        .navigationTitle("Personal Info")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Calorie and macro targets, with a soft hint when the macros don't add up to the calories.
private struct DailyTargetsView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var profile: UserProfile

    private let viewModel = ProfileViewModel()

    private var macroHint: String? {
        viewModel.macroConsistencyHint(
            calorieTarget: profile.calorieTarget,
            proteinTargetG: profile.proteinTargetG,
            carbTargetG: profile.carbTargetG,
            fatTargetG: profile.fatTargetG
        )
    }

    var body: some View {
        Form {
            Section {
                targetField("Calories", value: $profile.calorieTarget, unit: "kcal")
                targetField("Protein", value: $profile.proteinTargetG, unit: "g")
                targetField("Carbs", value: $profile.carbTargetG, unit: "g")
                targetField("Fat", value: $profile.fatTargetG, unit: "g")
            } footer: {
                if let macroHint {
                    Text(macroHint)
                }
            }
        }
        .navigationTitle("Daily Targets")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            // The fields are live-bound with no "save" step, so refresh the widget (which
            // shows these targets) when leaving the page rather than on every keystroke.
            // Explicit save first since autosave is opportunistic, not immediate.
            try? modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private func targetField(_ title: String, value: Binding<Int>, unit: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField(title, value: value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
            Text(unit)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .modelContainer(for: UserProfile.self, inMemory: true)
}
