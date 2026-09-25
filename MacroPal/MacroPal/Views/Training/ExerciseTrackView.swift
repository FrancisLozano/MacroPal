//
//  ExerciseTrackView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// Track one exercise's sets for a day (today, unless an unplanned workout is back-dated): the
/// Workout tab of `ExerciseScreen`. Each row is a set with a weight box and a reps box, and
/// "Last:" under each from the previous session (a bodyweight move has just the reps box). A
/// set saves on its own a moment after you stop typing, and when you leave its row, so
/// backing out midway loses nothing; when the last set logs, the exercise completes itself
/// after a moment. Complete Exercise logs the untouched rows at their suggested values and
/// goes back. Clearing both boxes unlogs a set. Used from a plan day (with
/// its sets × reps target) and from an unplanned workout (Profile → Workout's default sets).
/// Column order, units and the rest timer follow Profile → Workout.
struct ExerciseTrackView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(RestTimerModel.self) private var restTimer
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .lb
    @AppStorage(WorkoutPreferences.weightFirstKey) private var weightFirst = WorkoutPreferences.weightFirstDefault
    @AppStorage(WorkoutPreferences.defaultSetsKey) private var defaultSets = WorkoutPreferences.defaultSetsDefault
    @AppStorage(WorkoutPreferences.defaultRepsKey) private var defaultReps = WorkoutPreferences.defaultRepsDefault
    @AppStorage(WorkoutPreferences.restSecondsKey) private var restSeconds = WorkoutPreferences.restSecondsDefault
    @AppStorage(WorkoutPreferences.autoRestTimerKey) private var autoRestTimer = WorkoutPreferences.autoRestTimerDefault
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    let exercise: Exercise?
    /// The plan's sets × reps (`reps` is the suggestion with no history — the bottom of a
    /// range; `repsLabel` is "10" or "8–10"), or nil for an unplanned workout.
    let target: (sets: Int, reps: Int, repsLabel: String)?
    let date: Date
    /// Recorded on each logged set so Workout History can say "Pull".
    let planDayName: String?

    init(planExercise: PlanExercise) {
        exercise = planExercise.exercise
        target = (planExercise.targetSets, planExercise.targetReps, planExercise.repsLabel)
        date = .now
        planDayName = planExercise.day?.name
    }

    init(exercise: Exercise, date: Date) {
        self.exercise = exercise
        target = nil
        self.date = date
        planDayName = nil
    }

    @State private var rows: [SetRow] = []
    /// The store's entry behind each logged row.
    @State private var entries: [SetRow.ID: WorkoutSetEntry] = [:]
    @State private var isShowingSetsInfo = false
    /// The last set just logged: "Exercise Complete" shows, then the screen goes back unless
    /// a box is tapped first.
    @State private var isFinishing = false
    @FocusState private var focus: Field?
    /// The focused box's selection — all of it on focus, so typing replaces the number.
    @State private var selection: TextSelection?

    private let viewModel = WorkoutViewModel()

    private enum Field: Hashable {
        case weight(SetRow.ID)
        case reps(SetRow.ID)

        var rowID: SetRow.ID {
            switch self {
            case .weight(let id), .reps(let id): id
            }
        }
    }

    /// How long typing has to pause before a filled-in set logs itself — long enough not to
    /// log the "1" of "12".
    private static let autoLogDelay: Duration = .seconds(1)
    /// How long "Exercise Complete" shows after the last set logs before going back — time to
    /// tap a box and fix a typo instead.
    private static let autoFinishDelay: Duration = .seconds(1.5)

    /// The focused row and what's typed in it; a change restarts the auto-log wait.
    private struct Typing: Equatable {
        let rowID: SetRow.ID
        let weight: String
        let reps: String
    }

    private var typing: Typing? {
        guard let id = focus?.rowID, let row = rows.first(where: { $0.id == id }) else { return nil }
        return Typing(rowID: id, weight: row.weightText, reps: row.repsText)
    }

    private var loggedCount: Int {
        rows.filter(\.isLogged).count
    }

    private var allLogged: Bool {
        !rows.isEmpty && rows.allSatisfy(\.isLogged)
    }

    private var canComplete: Bool {
        rows.contains { $0.isLogged || $0.wouldLogOnComplete }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if let exercise, let illustration = ExerciseIllustration(exerciseName: exercise.name) {
                    illustration
                }
                header
                VStack(spacing: 0) {
                    ForEach(Array(rows.indices), id: \.self) { index in
                        if index > 0 {
                            Rectangle()
                                .fill(Color(.separator))
                                .frame(height: 1)
                                .padding(.leading, 12)
                        }
                        setRow($rows[index], number: index + 1)
                    }
                }
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))

                Button {
                    complete()
                } label: {
                    HStack(spacing: 6) {
                        Text(isFinishing ? "Exercise Complete" : "Complete Exercise")
                        if isFinishing {
                            Image(systemName: "checkmark")
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentTransition(.opacity)
                }
                .buttonStyle(.borderedProminent)
                .tint(isFinishing ? .green : .accentColor)
                .disabled(!canComplete)
                .animation(.default, value: isFinishing)
            }
            .padding([.horizontal, .bottom])
            .padding(.top, 4)
        }
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    restTimer.start(seconds: restSeconds)
                } label: {
                    Label("Start Rest", systemImage: "timer")
                }
                .disabled(restTimer.timer != nil)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focus = nil }
            }
        }
        .safeAreaInset(edge: .bottom) {
            RestTimerBar()
        }
        .onAppear(perform: buildRows)
        // Logs a filled-in set without leaving its row or pressing Done. Further typing updates
        // it; an incomplete row waits for the usual commit on leaving it.
        .task(id: typing) {
            guard let typing, (try? await Task.sleep(for: Self.autoLogDelay)) != nil,
                  rows.first(where: { $0.id == typing.rowID })?.typedValues != nil else { return }
            commitAndMaybeFinish(typing.rowID)
        }
        .onChange(of: focus) { old, new in
            if let old, old.rowID != new?.rowID {
                commitAndMaybeFinish(old.rowID)
            }
            // Tapping a box while "Exercise Complete" shows keeps you here to fix it.
            if new != nil { isFinishing = false }
            selectAll(in: new)
        }
        .task(id: isFinishing) {
            guard isFinishing, (try? await Task.sleep(for: Self.autoFinishDelay)) != nil,
                  isFinishing else { return }
            // The last set's own log already started the rest timer.
            dismiss()
        }
        // Backing out with a box still focused: save what's there.
        .onDisappear {
            for row in rows { commit(row.id) }
        }
    }

    /// The target, progress and where to change the number of sets.
    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                if let target {
                    Text("\(target.sets) sets × \(target.repsLabel) reps")
                        .font(.headline)
                    Text("\(loggedCount) of \(rows.count) done")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text(loggedCount == 1 ? "1 set done" : "\(loggedCount) sets done")
                        .font(.headline)
                }
            }
            Spacer(minLength: 0)
            Button {
                isShowingSetsInfo = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.title3)
            }
            .accessibilityLabel("Changing the number of sets")
            .popover(isPresented: $isShowingSetsInfo) {
                Text(setsInfo)
                    .font(.subheadline)
                    .padding()
                    .frame(width: 280)
                    .fixedSize(horizontal: false, vertical: true)
                    .presentationCompactAdaptation(.popover)
            }
        }
        .padding(.horizontal, 4)
    }

    private var setsInfo: String {
        if target != nil {
            "The number of sets comes from your plan. To change it, go back to the day's list and use ⋯ → Edit Sets & Reps on this exercise."
        } else {
            "An unplanned exercise gets Profile → Workout → Default Sets. Change it there."
        }
    }

    private func setRow(_ row: Binding<SetRow>, number: Int) -> some View {
        let id = row.wrappedValue.id
        return HStack(alignment: .top, spacing: 12) {
            HStack(spacing: 4) {
                Text("Set \(number)")
                    .font(.subheadline.weight(.semibold))
                if row.wrappedValue.isLogged {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .accessibilityLabel("Logged")
                }
            }
            .frame(width: 72, height: 36, alignment: .leading)

            if row.wrappedValue.isBodyweight {
                repsBox(row, id: id)
                bodyweightLabel
            } else if weightFirst {
                weightBox(row, id: id)
                repsBox(row, id: id)
            } else {
                repsBox(row, id: id)
                weightBox(row, id: id)
            }
        }
        .padding(12)
    }

    private func weightBox(_ row: Binding<SetRow>, id: SetRow.ID) -> some View {
        box(
            text: row.weightText, placeholder: row.wrappedValue.weightPlaceholder,
            suffix: unit.symbol, last: row.wrappedValue.last.map { SetRow.format($0.weight) },
            keyboard: .decimalPad, field: .weight(id)
        )
    }

    /// Stands in for the weight box on a bodyweight move, so the reps box keeps its width.
    private var bodyweightLabel: some View {
        Text("Bodyweight")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 36)
    }

    private func repsBox(_ row: Binding<SetRow>, id: SetRow.ID) -> some View {
        box(
            text: row.repsText, placeholder: row.wrappedValue.repsPlaceholder,
            suffix: "reps", last: row.wrappedValue.last.map { String($0.reps) },
            keyboard: .numberPad, field: .reps(id)
        )
    }

    /// A number box with its unit, and "Last: …" under it.
    private func box(
        text: Binding<String>, placeholder: String, suffix: String, last: String?,
        keyboard: UIKeyboardType, field: Field
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                TextField(placeholder, text: text, selection: selectionBinding(for: field))
                    .keyboardType(keyboard)
                    .multilineTextAlignment(.trailing)
                    .focused($focus, equals: field)
                Text(suffix)
                    .foregroundStyle(.secondary)
            }
            .font(.body.weight(.semibold))
            .padding(.horizontal, 10)
            .frame(height: 36)
            .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
            .onTapGesture { focus = field }

            Text("Last: \(last ?? "–")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func selectionBinding(for field: Field) -> Binding<TextSelection?> {
        Binding(
            get: { focus == field ? selection : nil },
            set: { if focus == field { selection = $0 } }
        )
    }

    private func selectAll(in field: Field?) {
        guard let field, let row = rows.first(where: { $0.id == field.rowID }) else {
            selection = nil
            return
        }
        let text = if case .weight = field { row.weightText } else { row.repsText }
        selection = TextSelection(range: text.startIndex..<text.endIndex)
    }

    /// Saves, updates or unlogs a row to match its boxes.
    private func commit(_ id: SetRow.ID, startsRest: Bool = true) {
        guard let index = rows.firstIndex(where: { $0.id == id }) else { return }
        rows[index].completeFromPlaceholders()
        switch rows[index].change {
        case .none:
            return
        case .insert(let values):
            guard let exercise else { return }
            entries[id] = viewModel.logSet(
                exercise: exercise, weightKg: unit.toKg(values.weight), reps: values.reps,
                on: date, planDayName: planDayName, context: modelContext
            )
            rows[index].saved = values
            SetRow.suggest(values, below: index, in: &rows)
            if startsRest && autoRestTimer {
                restTimer.start(seconds: restSeconds)
            }
        case .update(let values):
            entries[id]?.weightKg = unit.toKg(values.weight)
            entries[id]?.reps = values.reps
            rows[index].saved = values
            SetRow.suggest(values, below: index, in: &rows)
        case .delete:
            if let entry = entries.removeValue(forKey: id) {
                modelContext.delete(entry)
            }
            rows[index].saved = nil
        }
    }

    /// Commits a row; if that logged the last unlogged set, starts "Exercise Complete". Only
    /// the change to all-logged counts, so reopening or editing a finished exercise stays put.
    private func commitAndMaybeFinish(_ id: SetRow.ID) {
        let wasAllLogged = allLogged
        commit(id)
        if !wasAllLogged && allLogged {
            focus = nil
            isFinishing = true
        }
    }

    /// Logs every row that isn't yet, at its suggested values where untouched, then goes back
    /// to the list.
    private func complete() {
        focus = nil
        for index in rows.indices where !rows[index].isLogged {
            rows[index].fillEmptyFromPlaceholders()
            commit(rows[index].id, startsRest: false)
        }
        if autoRestTimer {
            restTimer.start(seconds: restSeconds)
        }
        dismiss()
    }

    /// The day's logged sets first, then empty rows up to the plan's (or the default) number of
    /// sets, each suggesting last session's set with the same number.
    private func buildRows() {
        guard rows.isEmpty, let exercise else { return }
        let dayStart = Calendar.current.startOfDay(for: date)
        let logged = (sessions.first { Calendar.current.isDate($0.date, inSameDayAs: date) }?.setEntries ?? [])
            .filter { $0.exercise == exercise }
            .sorted { $0.setNumber < $1.setNumber }
        let lastSets = WorkoutViewModel.lastSessionSets(for: exercise, in: sessions, before: dayStart)
        let count = max(target?.sets ?? defaultSets, logged.count)

        rows = (0..<count).map { index in
            var row = SetRow()
            row.isBodyweight = exercise.isBodyweight
            if let last = WorkoutViewModel.lastValue(forSet: index, in: lastSets) {
                row.last = values(of: last)
                row.weightPlaceholder = SetRow.format(row.last!.weight)
                row.repsPlaceholder = String(last.reps)
            } else {
                row.repsPlaceholder = String(target?.reps ?? defaultReps)
            }
            if index < logged.count {
                let saved = values(of: logged[index])
                row.saved = saved
                row.weightText = SetRow.format(saved.weight)
                row.repsText = String(saved.reps)
            }
            return row
        }
        for (index, entry) in logged.enumerated() {
            entries[rows[index].id] = entry
            if let saved = rows[index].saved {
                SetRow.suggest(saved, below: index, in: &rows)
            }
        }
    }

    /// A stored set in the user's unit, rounded the way the boxes show it.
    private func values(of entry: WorkoutSetEntry) -> SetValues {
        SetValues(weight: (unit.fromKg(entry.weightKg) * 10).rounded() / 10, reps: entry.reps)
    }
}
