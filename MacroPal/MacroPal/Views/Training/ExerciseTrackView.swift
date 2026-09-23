//
//  ExerciseTrackView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// Track one exercise's sets for a day (today, unless an unplanned workout is back-dated). Each
/// row is a set: reps × weight, how heavy that is against your best estimated 1RM, and a check
/// to log it. Rows start prefilled from your last set so a repeat set is a single tap. Used
/// from a plan day (with its sets × reps target) and from an unplanned workout (no target).
/// Row order, the % bar, unplanned defaults and the rest timer follow Profile → Workout.
struct ExerciseTrackView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(RestTimerModel.self) private var restTimer
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .lb
    @AppStorage(WorkoutPreferences.weightFirstKey) private var weightFirst = WorkoutPreferences.weightFirstDefault
    @AppStorage(WorkoutPreferences.showPRsKey) private var showPRs = WorkoutPreferences.showPRsDefault
    @AppStorage(WorkoutPreferences.defaultSetsKey) private var defaultSets = WorkoutPreferences.defaultSetsDefault
    @AppStorage(WorkoutPreferences.defaultRepsKey) private var defaultReps = WorkoutPreferences.defaultRepsDefault
    @AppStorage(WorkoutPreferences.restSecondsKey) private var restSeconds = WorkoutPreferences.restSecondsDefault
    @AppStorage(WorkoutPreferences.autoRestTimerKey) private var autoRestTimer = WorkoutPreferences.autoRestTimerDefault
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    let exercise: Exercise?
    /// The plan's sets × reps (`reps` prefills rows — the bottom of a range; `repsLabel` is
    /// "10" or "8–10"), or nil for an unplanned workout.
    let target: (sets: Int, reps: Int, repsLabel: String)?
    let date: Date

    init(planExercise: PlanExercise) {
        exercise = planExercise.exercise
        target = (planExercise.targetSets, planExercise.targetReps, planExercise.repsLabel)
        date = .now
    }

    init(exercise: Exercise, date: Date) {
        self.exercise = exercise
        target = nil
        self.date = date
    }

    @State private var rows: [SetRow] = []
    @FocusState private var isEditing: Bool

    private let viewModel = WorkoutViewModel()

    struct SetRow: Identifiable {
        let id = UUID()
        var weightText: String
        var repsText: String
        /// Non-nil once the set is logged; unchecking deletes it.
        var entry: WorkoutSetEntry?
    }

    private var referenceKg: Double? {
        guard let exercise else { return nil }
        return WorkoutViewModel.bestEstimated1RMKg(
            for: exercise, in: sessions, before: Calendar.current.startOfDay(for: date)
        )
    }

    private var loggedCount: Int {
        rows.filter { $0.entry != nil }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                header
                ForEach($rows) { $row in
                    setRow($row, number: (rows.firstIndex { $0.id == row.id } ?? 0) + 1)
                }
                Button {
                    rows.append(blankRow())
                } label: {
                    Label("Add Set", systemImage: "plus")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(exercise?.name ?? "Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    restTimer.start(seconds: restSeconds)
                } label: {
                    Label("Start Rest", systemImage: "timer")
                }
                .disabled(restTimer.timer != nil)
            }
        }
        .safeAreaInset(edge: .bottom) {
            RestTimerBar()
        }
        .onAppear(perform: buildRows)
    }

    /// The target and progress. The exercise's name is already the navigation title, so the
    /// card shows what it works instead of repeating it.
    private var header: some View {
        HStack(spacing: 12) {
            ExerciseThumbnail(exercise: exercise)
            VStack(alignment: .leading, spacing: 4) {
                if let target {
                    Text("\(target.sets) sets × \(target.repsLabel) reps")
                        .font(.headline)
                    Text("\(loggedCount) of \(target.sets) done")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text(loggedCount == 1 ? "1 set done" : "\(loggedCount) sets done")
                        .font(.headline)
                }
            }
            Spacer(minLength: 0)
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14))
    }

    private func setRow(_ row: Binding<SetRow>, number: Int) -> some View {
        let isLogged = row.wrappedValue.entry != nil
        return HStack(spacing: 10) {
            if isRemovable(row.wrappedValue, number: number) {
                Button {
                    remove(row.wrappedValue)
                } label: {
                    setNumber(number)
                        .overlay(alignment: .topLeading) {
                            Image(systemName: "minus.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .red)
                                .font(.body)
                                .offset(x: -8, y: -8)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove set \(number)")
            } else {
                setNumber(number)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    if weightFirst {
                        weightField(row)
                        Text("×")
                            .foregroundStyle(.secondary)
                        repsField(row)
                    } else {
                        repsField(row)
                        Text("×")
                            .foregroundStyle(.secondary)
                        weightField(row)
                    }
                }
                .focused($isEditing)
                .multilineTextAlignment(.trailing)
                .disabled(isLogged)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 8))

                intensityBar(for: row.wrappedValue)
            }

            Spacer(minLength: 0)

            Button {
                toggle(row)
            } label: {
                Image(systemName: isLogged ? "checkmark.circle.fill" : "checkmark.circle")
                    .font(.title)
                    .foregroundStyle(isLogged ? Color.green : Color.secondary)
            }
            .buttonStyle(.plain)
            .disabled(!isLogged && !isValid(row.wrappedValue))
            .accessibilityLabel(isLogged ? "Unlog set \(number)" : "Log set \(number)")
        }
        .padding(12)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14))
    }

    private func setNumber(_ number: Int) -> some View {
        Text("\(number)")
            .font(.title3.bold())
            .frame(width: 32, height: 40)
            .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 8))
    }

    private func repsField(_ row: Binding<SetRow>) -> some View {
        HStack(spacing: 4) {
            TextField("0", text: row.repsText)
                .keyboardType(.numberPad)
                .frame(width: 34)
            Text("reps")
                .foregroundStyle(.secondary)
        }
    }

    private func weightField(_ row: Binding<SetRow>) -> some View {
        HStack(spacing: 4) {
            TextField("0", text: row.weightText)
                .keyboardType(.decimalPad)
                .frame(width: 56)
            Text(unit.symbol)
                .foregroundStyle(.secondary)
        }
    }

    /// "30% of 130 lb" with a colored bar; hidden until there's history from an earlier day to
    /// compare to, or when Show PRs is off in Profile → Workout.
    @ViewBuilder
    private func intensityBar(for row: SetRow) -> some View {
        if showPRs, let referenceKg, let weight = Double(row.weightText), weight > 0 {
            let fraction = unit.toKg(weight) / referenceKg
            VStack(alignment: .leading, spacing: 3) {
                Text("\(Int((fraction * 100).rounded()))% of \(unit.formattedLift(fromKg: referenceKg)) \(unit.symbol)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ProgressView(value: min(fraction, 1))
                    .tint(intensityColor(fraction))
            }
        }
    }

    private func intensityColor(_ fraction: Double) -> Color {
        switch fraction {
        case ..<0.4: .green
        case ..<0.6: .yellow
        case ..<0.8: .orange
        default: .red
        }
    }

    private func isValid(_ row: SetRow) -> Bool {
        guard let weight = Double(row.weightText), let reps = Int(row.repsText) else { return false }
        return weight >= 0 && reps > 0
    }

    private func toggle(_ row: Binding<SetRow>) {
        if let entry = row.wrappedValue.entry {
            row.wrappedValue.entry = nil
            modelContext.delete(entry)
        } else if let exercise, isValid(row.wrappedValue),
                  let weight = Double(row.wrappedValue.weightText), let reps = Int(row.wrappedValue.repsText) {
            row.wrappedValue.entry = viewModel.logSet(
                exercise: exercise, weightKg: unit.toKg(weight), reps: reps, on: date, context: modelContext
            )
            isEditing = false
            fillForward(from: row.wrappedValue)
            if autoRestTimer {
                restTimer.start(seconds: restSeconds)
            }
        }
    }

    /// The rows `buildRows` pads up to every time the screen opens.
    private var baselineRowCount: Int {
        target?.sets ?? defaultSets
    }

    /// Only an unlogged row past the baseline can go — a baseline row would just come back the
    /// next time the screen opens, and a logged one is removed by unchecking it.
    private func isRemovable(_ row: SetRow, number: Int) -> Bool {
        row.entry == nil && number > baselineRowCount
    }

    private func remove(_ row: SetRow) {
        isEditing = false
        rows.removeAll { $0.id == row.id }
    }

    /// Copies a just-logged set into the later rows that don't have a weight yet, so on a
    /// first-ever session the weight only has to be typed once. Rows with a weight are left
    /// alone — that's either a prefill from history or something the user typed.
    private func fillForward(from logged: SetRow) {
        guard let index = rows.firstIndex(where: { $0.id == logged.id }) else { return }
        for later in rows.indices where later > index && rows[later].entry == nil && rows[later].weightText.isEmpty {
            rows[later].weightText = logged.weightText
            rows[later].repsText = logged.repsText
        }
    }

    /// The day's already-logged sets first (checked), then blank rows up to the target, all
    /// prefilled from the last set of this exercise.
    private func buildRows() {
        guard rows.isEmpty, let exercise else { return }
        let logged = (sessions.first { Calendar.current.isDate($0.date, inSameDayAs: date) }?.setEntries ?? [])
            .filter { $0.exercise == exercise }
            .sorted { $0.setNumber < $1.setNumber }
        rows = logged.map { entry in
            SetRow(
                weightText: unit.formattedLift(fromKg: entry.weightKg),
                repsText: String(entry.reps),
                entry: entry
            )
        }
        while rows.count < baselineRowCount {
            rows.append(blankRow())
        }
    }

    private func blankRow() -> SetRow {
        if let last = rows.last(where: { !$0.weightText.isEmpty }) ?? rows.last {
            return SetRow(weightText: last.weightText, repsText: last.repsText)
        }
        if let exercise, let last = WorkoutViewModel.lastSet(for: exercise, in: sessions) {
            return SetRow(weightText: unit.formattedLift(fromKg: last.weightKg), repsText: String(last.reps))
        }
        return SetRow(weightText: "", repsText: String(target?.reps ?? defaultReps))
    }
}
