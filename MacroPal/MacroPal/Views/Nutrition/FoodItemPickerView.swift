//
//  FoodItemPickerView.swift
//  MacroPal
//

import SwiftUI
import SwiftData
import VisionKit

private enum ScanFlowState: Equatable {
    case idle
    case scannerUnavailable
    case loading(barcode: String)
    case found(FoodItem)
    case notFound(barcode: String)
    case failed(barcode: String, message: String)

    static func == (lhs: ScanFlowState, rhs: ScanFlowState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.scannerUnavailable, .scannerUnavailable): true
        case let (.loading(a), .loading(b)): a == b
        case let (.notFound(a), .notFound(b)): a == b
        case let (.failed(a, _), .failed(b, _)): a == b
        default: false
        }
    }
}

/// Search an existing `FoodItem` catalog, scan a barcode, or create a new one inline.
/// Calls `onSelect` with the chosen/created item and dismisses itself.
struct FoodItemPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let onSelect: (FoodItem) -> Void

    @State private var searchText = ""
    @State private var isPresentingNewFoodForm = false
    @State private var isPresentingScanner = false
    @State private var scanState: ScanFlowState = .idle

    private let viewModel = NutritionViewModel()

    private var results: [FoodItem] {
        viewModel.searchFoodItems(matching: searchText, in: modelContext)
    }

    var body: some View {
        List {
            ForEach(results) { item in
                Button {
                    onSelect(item)
                    dismiss()
                } label: {
                    VStack(alignment: .leading) {
                        Text(item.name)
                            .foregroundStyle(Color.primary)
                        Text("\(Int(item.caloriesPer100g)) kcal / 100g")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search foods")
        .navigationTitle("Choose Food")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    startScan()
                } label: {
                    Label("Scan Barcode", systemImage: "barcode.viewfinder")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingNewFoodForm = true
                } label: {
                    Label("New Food", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingNewFoodForm) {
            NavigationStack {
                NewFoodItemView { newItem in
                    onSelect(newItem)
                    dismiss()
                }
            }
        }
        .fullScreenCover(isPresented: $isPresentingScanner) {
            NavigationStack {
                BarcodeScannerView { barcode in
                    isPresentingScanner = false
                    scanState = .loading(barcode: barcode)
                }
                .ignoresSafeArea()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { isPresentingScanner = false }
                    }
                }
            }
        }
        .alert("Scanner Unavailable", isPresented: .constant(scanState == .scannerUnavailable)) {
            Button("OK") { scanState = .idle }
        } message: {
            Text("Barcode scanning isn't available on this device.")
        }
        .task(id: taskID(for: scanState)) {
            guard case .loading(let barcode) = scanState else { return }
            await lookup(barcode: barcode)
        }
        .sheet(item: foundItemBinding) { item in
            NavigationStack {
                NewFoodItemView(prefill: item) { newItem in
                    onSelect(newItem)
                    dismiss()
                }
            }
        }
        .alert("Product Not Found", isPresented: notFoundBinding) {
            Button("Enter Manually") {
                if case .notFound(let barcode) = scanState {
                    scanState = .found(FoodItem(name: "", caloriesPer100g: 0, proteinG: 0, carbG: 0, fatG: 0, defaultServingSizeG: 100, barcode: barcode))
                }
            }
            Button("Cancel", role: .cancel) { scanState = .idle }
        } message: {
            Text("That barcode isn't in the Open Food Facts database.")
        }
        .alert("Connection Failed", isPresented: failedBinding) {
            Button("Retry") {
                if case .failed(let barcode, _) = scanState {
                    scanState = .loading(barcode: barcode)
                }
            }
            Button("Cancel", role: .cancel) { scanState = .idle }
        } message: {
            Text("Couldn't reach Open Food Facts — check your connection and try again.")
        }
        .overlay {
            if case .loading = scanState {
                ProgressView("Looking up product…")
                    .padding()
                    .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func startScan() {
        guard DataScannerViewController.isSupported && DataScannerViewController.isAvailable else {
            scanState = .scannerUnavailable
            return
        }
        isPresentingScanner = true
    }

    private func lookup(barcode: String) async {
        if let existing = viewModel.findFoodItem(byBarcode: barcode, in: modelContext) {
            onSelect(existing)
            dismiss()
            return
        }
        do {
            if let product = try await viewModel.fetchFoodItemFromNetwork(barcode: barcode, client: OpenFoodFactsClient()) {
                scanState = .found(product)
            } else {
                scanState = .notFound(barcode: barcode)
            }
        } catch {
            scanState = .failed(barcode: barcode, message: String(describing: error))
        }
    }

    private func taskID(for state: ScanFlowState) -> String {
        if case .loading(let barcode) = state { return barcode }
        return ""
    }

    private var foundItemBinding: Binding<FoodItem?> {
        Binding(
            get: { if case .found(let item) = scanState { item } else { nil } },
            set: { if $0 == nil { scanState = .idle } }
        )
    }

    private var notFoundBinding: Binding<Bool> {
        Binding(
            get: { if case .notFound = scanState { true } else { false } },
            set: { if !$0 { scanState = .idle } }
        )
    }

    private var failedBinding: Binding<Bool> {
        Binding(
            get: { if case .failed = scanState { true } else { false } },
            set: { if !$0 { scanState = .idle } }
        )
    }
}

/// Inline "create new food" form, used both when the desired food isn't in the catalog
/// yet and to review/edit a barcode-scanned result before saving (Open Food Facts data
/// quality varies, so this is always editable, never auto-saved).
private struct NewFoodItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let onCreate: (FoodItem) -> Void

    private let barcode: String?

    @State private var name: String
    @State private var caloriesText: String
    @State private var proteinText: String
    @State private var carbText: String
    @State private var fatText: String
    @State private var servingSizeText: String

    init(prefill: FoodItem? = nil, onCreate: @escaping (FoodItem) -> Void) {
        self.onCreate = onCreate
        self.barcode = prefill?.barcode
        _name = State(initialValue: prefill?.name ?? "")
        _caloriesText = State(initialValue: prefill.map { $0.caloriesPer100g == 0 ? "" : String($0.caloriesPer100g) } ?? "")
        _proteinText = State(initialValue: prefill.map { $0.proteinG == 0 ? "" : String($0.proteinG) } ?? "")
        _carbText = State(initialValue: prefill.map { $0.carbG == 0 ? "" : String($0.carbG) } ?? "")
        _fatText = State(initialValue: prefill.map { $0.fatG == 0 ? "" : String($0.fatG) } ?? "")
        _servingSizeText = State(initialValue: prefill.map { String($0.defaultServingSizeG) } ?? "100")
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && Double(caloriesText) != nil
            && Double(proteinText) != nil
            && Double(carbText) != nil
            && Double(fatText) != nil
            && Double(servingSizeText) != nil
    }

    var body: some View {
        Form {
            Section("Name") {
                TextField("Food name", text: $name)
            }
            Section("Macros per 100g") {
                HStack {
                    Text("Calories")
                    Spacer()
                    TextField("kcal", text: $caloriesText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Protein")
                    Spacer()
                    TextField("g", text: $proteinText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Carbs")
                    Spacer()
                    TextField("g", text: $carbText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Fat")
                    Spacer()
                    TextField("g", text: $fatText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            Section("Default Serving Size") {
                HStack {
                    TextField("Serving size", text: $servingSizeText)
                        .keyboardType(.decimalPad)
                    Text("g")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("New Food")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!isValid)
            }
        }
    }

    private func save() {
        guard let calories = Double(caloriesText),
              let protein = Double(proteinText),
              let carb = Double(carbText),
              let fat = Double(fatText),
              let servingSize = Double(servingSizeText) else { return }

        let item = FoodItem(
            name: name.trimmingCharacters(in: .whitespaces),
            caloriesPer100g: calories,
            proteinG: protein,
            carbG: carb,
            fatG: fat,
            defaultServingSizeG: servingSize,
            barcode: barcode
        )
        modelContext.insert(item)
        onCreate(item)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        FoodItemPickerView { _ in }
    }
    .modelContainer(for: FoodItem.self, inMemory: true)
}
