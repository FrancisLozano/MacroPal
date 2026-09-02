//
//  ProfileView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// Fetches the singleton `UserProfile` (creating it on first launch) and hands it to
/// `ProfileFormView` for live editing.
struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    var body: some View {
        Group {
            if let profile = profiles.first {
                ProfileFormView(profile: profile)
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

private struct ProfileFormView: View {
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
            Section("Personal Info") {
                HStack {
                    TextField("Height", value: $profile.heightCm, format: .number)
                        .keyboardType(.decimalPad)
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

            Section("Goal") {
                Picker("Goal", selection: $profile.goal) {
                    ForEach(Goal.allCases) { goal in
                        Text(goal.displayName).tag(goal)
                    }
                }
            }

            Section {
                HStack {
                    Text("Calories")
                    Spacer()
                    TextField("Calories", value: $profile.calorieTarget, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                    Text("kcal")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Protein")
                    Spacer()
                    TextField("Protein", value: $profile.proteinTargetG, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                    Text("g")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Carbs")
                    Spacer()
                    TextField("Carbs", value: $profile.carbTargetG, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                    Text("g")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Fat")
                    Spacer()
                    TextField("Fat", value: $profile.fatTargetG, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                    Text("g")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Macro Targets")
            } footer: {
                if let macroHint {
                    Text(macroHint)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .modelContainer(for: UserProfile.self, inMemory: true)
}
