//
//  ProfileView.swift
//  MacroPal
//

import SwiftUI
import SwiftData
import WidgetKit
import UserNotifications

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
    @AppStorage(WorkoutPreferences.weightFirstKey) private var weightFirst = WorkoutPreferences.weightFirstDefault
    @AppStorage(WorkoutPreferences.defaultSetsKey) private var defaultSets = WorkoutPreferences.defaultSetsDefault
    @AppStorage(WorkoutPreferences.defaultRepsKey) private var defaultReps = WorkoutPreferences.defaultRepsDefault
    @AppStorage(WorkoutPreferences.defaultRepsMaxKey) private var defaultRepsMax = WorkoutPreferences.defaultRepsMaxDefault
    @AppStorage(WorkoutPreferences.restSecondsKey) private var restSeconds = WorkoutPreferences.restSecondsDefault
    @AppStorage(WorkoutPreferences.autoRestTimerKey) private var autoRestTimer = WorkoutPreferences.autoRestTimerDefault
    /// Read each time the list appears (including on coming back from Reminders) rather than
    /// one `@AppStorage` per reminder, along with whether iOS lets them through.
    @State private var enabledReminders: [Reminder] = []
    @State private var notificationsDenied = false

    private let viewModel = ProfileViewModel()

    var body: some View {
        List {
            // Same order as the tabs: Nutrition, then Training.
            Section {
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
                        "Daily Targets",
                        systemImage: "chart.pie",
                        detail: viewModel.targetsSummary(
                            calorieTarget: profile.calorieTarget,
                            proteinTargetG: profile.proteinTargetG,
                            carbTargetG: profile.carbTargetG,
                            fatTargetG: profile.fatTargetG
                        )
                    )
                }
            } header: {
                Text("Nutrition")
            } footer: {
                Text("Goal tells the coach which way your weight should move. It doesn't change your targets. Set your goal weight on the Training tab.")
            }

            Section {
                NavigationLink {
                    WorkoutSettingsView()
                } label: {
                    summaryRow(
                        "Workout",
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
                NavigationLink {
                    PastTrainingView(profile: profile)
                } label: {
                    summaryRow(
                        "Past Training",
                        systemImage: "clock.arrow.circlepath",
                        detail: viewModel.pastTrainingSummary(months: profile.priorTrainingMonths)
                    )
                }
                Picker(selection: $profile.sex) {
                    ForEach(Sex.allCases) { sex in
                        Text(sex.displayName).tag(sex)
                    }
                } label: {
                    Label("Sex", systemImage: "figure.stand")
                }
            } header: {
                Text("Training")
            } footer: {
                Text("Past training and sex set the muscle levels on the body map.")
            }

            Section {
                NavigationLink {
                    RemindersSettingsView()
                } label: {
                    summaryRow(
                        "Reminders",
                        systemImage: "bell",
                        detail: viewModel.remindersSummary(enabled: enabledReminders, notificationsDenied: notificationsDenied)
                    )
                }
            }

            Section("Units") {
                Picker(selection: $weightUnit) {
                    ForEach(WeightUnit.allCases) { unit in
                        Text(unit.symbol).tag(unit)
                    }
                } label: {
                    Label("Weight", systemImage: "scalemass")
                }
            }

            Section {
                NavigationLink {
                    AcknowledgementsView()
                } label: {
                    Label("Acknowledgements", systemImage: "heart.text.square")
                }
            }
        }
        .task {
            enabledReminders = Reminder.allCases.filter { $0.isEnabled(in: .standard) }
            let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
            notificationsDenied = status == .denied
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

/// Calorie and macro targets, with a soft hint when the macros don't add up to the calories.
private struct DailyTargetsView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var profile: UserProfile
    @FocusState private var focusedField: String?

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
        // The number pad has no return key.
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
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
                .focused($focusedField, equals: title)
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
