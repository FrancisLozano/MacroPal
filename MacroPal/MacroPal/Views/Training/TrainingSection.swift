//
//  TrainingSection.swift
//  MacroPal
//

import SwiftUI

/// A titled section of the Training page, styled after the Nutrition page's list sections: a
/// gray heading, with an optional button on its right (an ⓘ, the week plan), above a rounded
/// card. Built from stacks rather than a `List`, which the page avoids for its buttons' sake.
struct TrainingSection<Accessory: View, Content: View>: View {
    let title: String?
    @ViewBuilder var accessory: Accessory
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                HStack {
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    accessory
                }
                .padding(.horizontal)
            }
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Self.cardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .padding(.horizontal)
    }

    static var cardBackground: Color { Color(.secondarySystemGroupedBackground) }
}

/// The Training page's + for logging something: an accent plus on a small gray circle, growing
/// with the text size. The Goals rows and "Log an Unplanned Workout" share it, so every + on
/// the page looks the same.
struct PlusCircle: View {
    @ScaledMetric private var diameter: CGFloat = 30

    var body: some View {
        Image(systemName: "plus")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.accentColor)
            .frame(width: diameter, height: diameter)
            .background(Color(.tertiarySystemFill), in: Circle())
    }
}

extension View {
    /// A heading button's icon (the ⓘ, the ⋯) with a 44-pt hit area around it, kept right-aligned
    /// and without making the heading taller. Goes on the button's label: a frame outside a
    /// button doesn't widen what it responds to.
    func headingButtonTarget() -> some View {
        frame(minWidth: 44, minHeight: 44, alignment: .trailing)
            .contentShape(Rectangle())
            .padding(.vertical, -12)
    }
}

extension TrainingSection where Accessory == EmptyView {
    init(_ title: String?, @ViewBuilder content: () -> Content) {
        self.title = title
        accessory = EmptyView()
        self.content = content()
    }
}

extension TrainingSection {
    init(_ title: String, @ViewBuilder accessory: () -> Accessory, @ViewBuilder content: () -> Content) {
        self.title = title
        self.accessory = accessory()
        self.content = content()
    }
}
