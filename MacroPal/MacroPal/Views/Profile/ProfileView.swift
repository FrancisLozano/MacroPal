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

    private let viewModel = ProfileViewModel()

    var body: some View {
        List {
            Section {
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
                            activityLevel: profile.activityLevel
                        )
                    )
                }
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
            } footer: {
                Text("Goal weight, the step goal and lb/kg are on the Training tab's Goals card.")
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

/// Height, birth date, sex and activity level.
private struct PersonalInfoView: View {
    @Bindable var profile: UserProfile

    var body: some View {
        Form {
            HStack {
                Text("Height")
                Spacer()
                TextField("Height", value: $profile.heightCm, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                Text("cm")
                    .foregroundStyle(.secondary)
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
