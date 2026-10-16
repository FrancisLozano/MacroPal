//
//  SetRow.swift
//  MacroPal
//

import Foundation

/// A set's weight (in the user's lb/kg) and reps.
struct SetValues: Equatable {
    var weight: Double
    var reps: Int
}

/// One set on the exercise screen's Workout tab, and the rules for saving it as you type.
/// Boxes start empty; the placeholders are what the set will be if left untouched, and the
/// "Last:" line shows `suggested`, the set those grey numbers came from, so tapping it fills in
/// exactly what it says. Which set that is follows `LastSetSource`: last session's set with the
/// same number, or the set just logged above it today. Kept free of SwiftData so the rules can be unit-tested;
/// the view maps a `SetChange` onto the store.
struct SetRow: Identifiable {
    let id = UUID()
    var weightText = ""
    var repsText = ""
    var weightPlaceholder = ""
    var repsPlaceholder = ""
    /// Last session's values for this set number, nil when there's no earlier session.
    var last: SetValues?
    /// The set the placeholders come from, shown on the "Last:" line: `last`, or today's set
    /// above this one. Nil while only the default reps are suggested.
    var suggested: SetValues?
    /// What's in the store for this row, nil while it isn't logged.
    var saved: SetValues?
    /// A bodyweight move: there's no weight box, so only the reps count.
    var isBodyweight = false

    /// What to do to the store when the user leaves the row.
    enum SetChange: Equatable {
        case none
        case insert(SetValues)
        case update(SetValues)
        case delete
    }

    var isLogged: Bool { saved != nil }

    private var isBlank: Bool {
        (isBodyweight || weightText.trimmingCharacters(in: .whitespaces).isEmpty)
            && repsText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Both boxes parsed, nil if either is empty or not a valid set (reps must be above 0;
    /// a 0 weight is allowed). A bodyweight set only needs its reps, and keeps the weight it
    /// was logged with before it had no weight box, so opening the screen doesn't rewrite it.
    var typedValues: SetValues? {
        guard let reps = Int(repsText), reps > 0 else { return nil }
        if isBodyweight {
            return SetValues(weight: saved?.weight ?? 0, reps: reps)
        }
        guard let weight = Double(weightText), weight >= 0 else { return nil }
        return SetValues(weight: weight, reps: reps)
    }

    /// Fills an empty box when the other one was typed in: from the logged set if there is
    /// one (clearing one box doesn't unlog it), else from the placeholder — typing just the
    /// weight keeps the suggested reps. A row nobody touched stays blank, so it isn't logged
    /// just for being on screen.
    mutating func completeFromPlaceholders() {
        guard !isBlank else { return }
        if let saved {
            if weightText.isEmpty { weightText = Self.format(saved.weight) }
            if repsText.isEmpty { repsText = String(saved.reps) }
        } else {
            fillEmptyFromPlaceholders()
        }
    }

    /// Complete Exercise: every empty box takes its placeholder, touched or not.
    mutating func fillEmptyFromPlaceholders() {
        if weightText.isEmpty { weightText = weightPlaceholder }
        if repsText.isEmpty { repsText = repsPlaceholder }
    }

    /// Clearing both boxes unlogs the set; an incomplete or invalid row leaves the store alone.
    var change: SetChange {
        if isBlank {
            return saved == nil ? .none : .delete
        }
        guard let values = typedValues, values != saved else { return .none }
        return saved == nil ? .insert(values) : .update(values)
    }

    /// One of the row's two boxes, each with its own "Last:" line.
    enum Box {
        case weight, reps
    }

    /// Whether that box's "Last:" line can fill it: the set isn't logged yet, the line shows a
    /// set (not "–", which would fill in a number it doesn't show) and the box has a valid grey
    /// number to take.
    func canUseSuggestion(for box: Box) -> Bool {
        guard !isLogged, suggested != nil else { return false }
        switch box {
        case .weight: return !isBodyweight && Double(weightPlaceholder).map { $0 >= 0 } == true
        case .reps: return Int(repsPlaceholder).map { $0 > 0 } == true
        }
    }

    /// A "Last:" tap: only that box takes its grey number, so reps and weight can be repeated
    /// separately. The set logs once both are filled (`typedValues`), as if typed.
    mutating func useSuggestion(for box: Box) {
        guard canUseSuggestion(for: box) else { return }
        switch box {
        case .weight: weightText = weightPlaceholder
        case .reps: repsText = repsPlaceholder
        }
    }

    /// Whether Complete Exercise would log this row.
    var wouldLogOnComplete: Bool {
        var filled = self
        filled.fillEmptyFromPlaceholders()
        return filled.typedValues != nil
    }

    /// Makes `values` this row's suggestion: its grey numbers and its "Last:" line.
    mutating func suggest(_ values: SetValues) {
        suggested = values
        weightPlaceholder = Self.format(values.weight)
        repsPlaceholder = String(values.reps)
    }

    /// After a set is saved, the empty rows below it may suggest the same weight × reps, so a
    /// repeat set is a tap on each "Last:" line. With `.previousSet` they all do; with
    /// `.lastWorkout` only rows with no set from last session do (a first-ever session, or more
    /// sets than last time), so the weight only has to be typed once.
    static func suggest(_ values: SetValues, below index: Int, in rows: inout [SetRow], source: LastSetSource) {
        for later in rows.indices
        where later > index && !rows[later].isLogged && rows[later].isBlank {
            if source == .lastWorkout && rows[later].last != nil { continue }
            rows[later].suggest(values)
        }
    }

    /// "135", "62.5" — no grouping separator, so the text parses back with `Double(_:)`.
    static func format(_ weight: Double) -> String {
        weight.formatted(.number.grouping(.never).precision(.fractionLength(0...1)))
    }
}
