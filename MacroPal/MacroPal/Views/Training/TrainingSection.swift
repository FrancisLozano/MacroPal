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
