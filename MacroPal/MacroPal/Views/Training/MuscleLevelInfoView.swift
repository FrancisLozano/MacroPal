//
//  MuscleLevelInfoView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// The body map's ⓘ sheet: what each level color means and what it takes to reach it — the
/// strength needed (Back Squat and Bench Press as examples, in your units once there's a
/// bodyweight) and how long the muscle has to have been trained. Reads the same numbers the
/// levels are computed from (`StrengthClass`, `MuscleLevelEngine.levelMinimumMonths`).
struct MuscleLevelInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .lb
    @Query(sort: \WeightEntry.date, order: .reverse) private var weightEntries: [WeightEntry]
    @Query private var profiles: [UserProfile]

    private static let summaries = [
        "Every muscle you train starts here.",
        "Past the first weeks: you know the movements and your lifts are climbing fast.",
        "Months of steady training. Progress now comes week to week, not every session.",
        "About a year of consistent training and clearly strong for your size.",
        "Years of dedicated training, at the level of competitive lifters.",
        "Among the strongest lifters for their bodyweight.",
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
                        Text("**Strength.** Your best estimated one-rep max from the last 90 days, on a lift that works the muscle, compared with your bodyweight.")
                    } icon: {
                        Image(systemName: "scalemass")
                    }
                    Label {
                        Text("**Time.** How long you've been training it, so one heavy day can't skip years of progress.")
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
                    requirement(strength(index), systemImage: "scalemass")
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

    /// "Squat 340 lb (1.5× bodyweight)" over "Bench 225 lb (1.0× bodyweight)", or just the
    /// multiples before any weight is logged.
    private func strength(_ index: Int) -> String {
        let lifts = [
            ("Squat", StrengthClass.lowerCompound.maleThresholds[index] * sexFactor),
            ("Bench", StrengthClass.press.maleThresholds[index] * sexFactor),
        ]
        return lifts.map { name, ratio in
            guard let bodyweightKg else { return "\(name) \(multiple(ratio)) bodyweight" }
            return "\(name) \(load(ratio, bodyweightKg)) (\(multiple(ratio)) bodyweight)"
        }
        .joined(separator: "\n")
    }

    private func time(_ index: Int) -> String {
        let months = MuscleLevelEngine.levelMinimumMonths[index]
        switch months {
        case 1: return "Trained for 1 month or more"
        case ..<12: return "Trained for \(Int(months)) months or more"
        case 12: return "Trained for a year or more"
        default: return "Trained for \(Int(months / 12)) years or more"
        }
    }

    private func multiple(_ ratio: Double) -> String {
        ratio.formatted(.number.precision(.fractionLength(1...2))) + "×"
    }

    /// Rounded to 5 lb / 2.5 kg, like a loadable bar.
    private func load(_ ratio: Double, _ bodyweightKg: Double) -> String {
        let step = unit == .lb ? 5.0 : 2.5
        let value = (unit.fromKg(ratio * bodyweightKg) / step).rounded() * step
        return "\(value.formatted(.number.precision(.fractionLength(0...1)))) \(unit.symbol)"
    }

    private var footer: String {
        var text = "Squat and bench are examples; every lift has its own standard, and Exercise Progress shows yours. Bodyweight moves like pull-ups count as training but can't raise a level."
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
