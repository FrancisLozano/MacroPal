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
/// Boxes start empty; the placeholders are what the set will be if left untouched (last
/// session's set, or the set just saved above it), and `last` is last session's set for the
/// "Last:" line. Kept free of SwiftData so the rules can be unit-tested; the view maps a
/// `SetChange` onto the store.
struct SetRow: Identifiable {
    let id = UUID()
    var weightText = ""
    var repsText = ""
    var weightPlaceholder = ""
    var repsPlaceholder = ""
    /// Last session's values for this set number, nil when there's no earlier session.
    var last: SetValues?
    /// What's in the store for this row, nil while it isn't logged.
    var saved: SetValues?

    /// What to do to the store when the user leaves the row.
    enum SetChange: Equatable {
        case none
        case insert(SetValues)
        case update(SetValues)
        case delete
    }

    var isLogged: Bool { saved != nil }

    private var isBlank: Bool {
        weightText.trimmingCharacters(in: .whitespaces).isEmpty
            && repsText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Both boxes parsed, nil if either is empty or not a valid set (reps must be above 0;
    /// a 0 weight is allowed for bodyweight moves).
    var typedValues: SetValues? {
        guard let weight = Double(weightText), weight >= 0,
              let reps = Int(repsText), reps > 0 else { return nil }
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

    /// Whether Complete Exercise would log this row.
    var wouldLogOnComplete: Bool {
        var filled = self
        filled.fillEmptyFromPlaceholders()
        return filled.typedValues != nil
    }

    /// After a set is saved, the empty rows below it suggest the same weight × reps, so on a
    /// first-ever session the weight only has to be typed once. Rows with a last session keep
    /// suggesting that.
    static func suggest(_ values: SetValues, below index: Int, in rows: inout [SetRow]) {
        for later in rows.indices
        where later > index && rows[later].last == nil && !rows[later].isLogged && rows[later].isBlank {
            rows[later].weightPlaceholder = format(values.weight)
            rows[later].repsPlaceholder = String(values.reps)
        }
    }

    /// "135", "62.5" — no grouping separator, so the text parses back with `Double(_:)`.
    static func format(_ weight: Double) -> String {
        weight.formatted(.number.grouping(.never).precision(.fractionLength(0...1)))
    }
}
