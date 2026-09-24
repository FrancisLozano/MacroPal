//
//  MuscleLevelInfoView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// The body map's ⓘ sheet: what each level color means and what it takes to reach it — the
/// volume a muscle needs (in bodyweights, and in your units once there's a bodyweight) and how
/// long it has to have been trained. Reads the same numbers the levels are computed from
/// (`MuscleLevelEngine.levelMinimumBodyweights` and `levelMinimumMonths`).
struct MuscleLevelInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .lb
    @Query(sort: \WeightEntry.date, order: .reverse) private var weightEntries: [WeightEntry]
    @Query private var profiles: [UserProfile]

    private static let summaries = [
        "Every muscle you train starts here.",
        "A few weeks of regular work: the muscle is getting used to training.",
        "Months of steady training behind it.",
        "About a year of consistent training.",
        "Years of dedicated training.",
        "Five years or more of hard, consistent work.",
    ]

    private var bodyweightKg: Double? { weightEntries.first?.weightKg }

    private var sexFactor: Double {
        profiles.first?.sex == .female ? MuscleLevelEngine.femaleFactor : 1
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Each muscle's color is its level. To move up, a muscle needs both:")
                    Label {
                        Text("**Volume.** Everything it has moved — weight × reps over every set, ever — compared with your bodyweight. 3 sets of 10 at 100 lb is 3,000 lb. Muscles that only assist get part of the credit.")
                    } icon: {
                        Image(systemName: "scalemass")
                    }
                    Label {
                        Text("**Time.** How long you've been training it, so a burst of volume can't skip years of progress.")
                    } icon: {
                        Image(systemName: "calendar")
                    }
                }

                Section {
                    ForEach(MuscleLevelEngine.levelNames.indices, id: \.self) { index in
                        levelRow(index)
                    }
                } header: {
                    Text("Levels")
                } footer: {
                    Text(footer)
                }
            }
            .navigationTitle("How Levels Work")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func levelRow(_ index: Int) -> some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(LevelPalette.color(forLevel: index + 1))
                .frame(width: 8)
            VStack(alignment: .leading, spacing: 4) {
                Text(MuscleLevelEngine.levelNames[index])
                    .font(.headline)
                Text(Self.summaries[index])
                    .font(.subheadline)
                if index > 0 {
                    requirement(volume(index), systemImage: "scalemass")
                    requirement(time(index), systemImage: "calendar")
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func requirement(_ text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    /// "13,900 lb moved (90× your bodyweight)", or just the multiple before any weight is
    /// logged.
    private func volume(_ index: Int) -> String {
        let bodyweights = MuscleLevelEngine.levelMinimumBodyweights[index] * sexFactor
        let multiple = "\(bodyweights.formatted(.number.precision(.fractionLength(0))))× your bodyweight"
        guard let bodyweightKg else { return "\(multiple) moved" }
        // Rounded to 100 lb / 50 kg: these are milestones, not targets to hit exactly.
        let step = unit == .lb ? 100.0 : 50.0
        let amount = (unit.fromKg(bodyweights * bodyweightKg) / step).rounded() * step
        return "\(amount.formatted(.number.precision(.fractionLength(0)))) \(unit.symbol) moved (\(multiple))"
    }

    private func time(_ index: Int) -> String {
        let months = MuscleLevelEngine.levelMinimumMonths[index]
        switch months {
        case ..<1: return "Trained for \(Int((months * 30.44 / 7).rounded())) weeks or more"
        case 1: return "Trained for 1 month or more"
        case ..<12: return "Trained for \(Int(months)) months or more"
        case 12: return "Trained for a year or more"
        default: return "Trained for \(Int(months / 12)) years or more"
        }
    }

    private var footer: String {
        var text = "Dumbbell lifts count both dumbbells; bodyweight moves like pull-ups count part of your bodyweight. A muscle keeps its level through a break."
        if bodyweightKg == nil {
            text = "Log your weight to see these in \(unit.symbol). " + text
        }
        return text
    }
}

#Preview {
    MuscleLevelInfoView()
        .modelContainer(for: [WeightEntry.self, UserProfile.self], inMemory: true)
}
