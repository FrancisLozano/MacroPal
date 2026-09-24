//
//  AcknowledgementsView.swift
//  MacroPal
//

import SwiftUI

/// Credits for the outside material the app ships or shows, as their licenses ask.
struct AcknowledgementsView: View {
    var body: some View {
        Form {
            Section {
                Text("The start and end drawings on the exercise screen are from Everkinetic (everkinetic.com, created by Greg Priday), licensed under CC BY-SA 4.0. They were resized and converted to transparent line art for the app; the changed drawings are shared under the same license.")
                Link("Everkinetic data on GitHub", destination: URL(string: "https://github.com/everkinetic/data")!)
                Link("CC BY-SA 4.0 license", destination: URL(string: "https://creativecommons.org/licenses/by-sa/4.0/")!)
            } header: {
                Text("Exercise Drawings")
            }

            Section {
                Text("Food search and barcode results come from Open Food Facts, available under the Open Database License.")
                Link("Open Food Facts", destination: URL(string: "https://world.openfoodfacts.org")!)
            } header: {
                Text("Food Data")
            }
        }
        .navigationTitle("Acknowledgements")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AcknowledgementsView()
    }
}
