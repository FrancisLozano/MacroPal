//
//  ExportDataView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// Profile → Export Data: builds the `DataExport` file when the page opens, says what's in it,
/// and hands it to the share sheet (Save to Files, AirDrop, Mail…).
struct ExportDataView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var export: DataExport?
    @State private var fileURL: URL?
    @State private var failure: String?

    var body: some View {
        Form {
            if let export {
                Section {
                    countRow("Foods logged", export.foodLog.count)
                    countRow("Saved foods and meals", export.foods.count)
                    countRow("Weigh-ins", export.weights.count)
                    countRow("Days of steps", export.steps.count)
                    countRow("Workouts", export.workouts.count)
                    countRow("Sets", export.workouts.reduce(0) { $0 + $1.sets.count })
                    countRow("Plan days", export.plan.count)
                } header: {
                    Text("In the file")
                } footer: {
                    Text("Also your targets, profile and exercises.")
                }
            }

            Section {
                if let fileURL {
                    ShareLink(item: fileURL, preview: SharePreview(fileURL.lastPathComponent)) {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                } else if let failure {
                    Text(failure)
                        .foregroundStyle(.secondary)
                } else {
                    ProgressView()
                }
            } footer: {
                Text("Saves everything as one JSON file. MacroPal keeps your data only on this iPhone, so save the file to Files or send it to yourself to keep a copy.")
            }
        }
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            do {
                let built = try DataExport(from: modelContext)
                fileURL = try built.writeTemporaryFile()
                export = built
            } catch {
                failure = "Couldn't build the export: \(error.localizedDescription)"
            }
        }
    }

    private func countRow(_ title: String, _ count: Int) -> some View {
        LabeledContent(title, value: count.formatted())
    }
}

#Preview {
    NavigationStack {
        ExportDataView()
    }
    .modelContainer(for: AppSchema.models, inMemory: true)
}
