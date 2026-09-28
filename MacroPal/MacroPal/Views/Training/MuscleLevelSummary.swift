//
//  MuscleLevelSummary.swift
//  MacroPal
//

import SwiftUI

/// Where one muscle stands: "● Novice → Intermediate", the volume it has moved against what the
/// next level needs, a bar toward it, and what else it's waiting on. Tops the body map's muscle
/// detail, and shows for each primary muscle on an exercise's Progress tab.
struct MuscleLevelSummary: View {
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .lb

    let progress: MuscleProgress
    /// Without a weigh-in there's nothing to measure the next level against.
    let hasBodyweight: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            levelLine

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(amount(progress.volumeKg))
                    .font(.title.bold())
                    .lineLimit(1)
                if let next = progress.nextLevelVolumeKg {
                    Text("of \(amount(next)) \(unit.symbol)")
                        .foregroundStyle(.secondary)
                    Spacer()
                    if next > progress.volumeKg {
                        Text("\(amount(next - progress.volumeKg)) \(unit.symbol) to go")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("\(unit.symbol) moved")
                        .foregroundStyle(.secondary)
                }
            }

            if let fraction = progress.fractionToNextLevel {
                ProgressView(value: fraction)
                    .tint(LevelPalette.color(forLevel: progress.level + 1))
            }

            if let note {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// "● Novice → Intermediate", or where the muscle stands when there's no next step.
    @ViewBuilder
    private var levelLine: some View {
        if progress.level == 0 {
            Text("Not trained yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            HStack(spacing: 6) {
                Circle()
                    .fill(LevelPalette.color(forLevel: progress.level))
                    .frame(width: 10, height: 10)
                Text(levelName(progress.level))
                if progress.nextLevelVolumeKg != nil {
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(levelName(progress.level + 1))
                        .foregroundStyle(.secondary)
                }
            }
            .font(.subheadline.weight(.semibold))
            .accessibilityElement(children: .combine)
        }
    }

    /// What else the next level needs, or why there's no bar.
    private var note: String? {
        let date = progress.nextLevelUnlocks.map { unlocks in
            Calendar.current.isDate(unlocks, equalTo: .now, toGranularity: .year)
                ? unlocks.formatted(.dateTime.month(.abbreviated).day())
                : unlocks.formatted(.dateTime.month(.abbreviated).day().year())
        }
        if progress.fractionToNextLevel != nil {
            let next = levelName(progress.level + 1)
            switch (progress.fractionToNextLevel == 1, date) {
            case (true, let date?): return "Volume reached. \(next) also takes time: it unlocks \(date)."
            case (false, let date?): return "\(next) also needs training until \(date)."
            default: return nil
            }
        }
        if progress.level == MuscleLevelEngine.levelNames.count { return "World Class, the top level." }
        if progress.level > 0 && !hasBodyweight { return "Log your weight to see how far the next level is." }
        if progress.level == 0 { return "Log a set that works it and it starts at Beginner." }
        return nil
    }

    private func levelName(_ level: Int) -> String {
        MuscleLevelEngine.levelNames[level - 1]
    }

    /// Whole pounds or kilograms, "12,480"; "567.5K" from 100,000 up (past training reaches
    /// millions), so the line stays on one row.
    private func amount(_ kg: Double) -> String {
        let value = unit.fromKg(kg)
        if value >= 100_000 {
            return value.formatted(.number.notation(.compactName).precision(.significantDigits(1...4)))
        }
        return value.formatted(.number.precision(.fractionLength(0)))
    }
}
