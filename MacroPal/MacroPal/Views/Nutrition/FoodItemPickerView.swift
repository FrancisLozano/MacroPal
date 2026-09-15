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

private enum PickerTab: Hashable {
    case recents
    case myMeals
}

/// Search an existing `FoodItem` catalog, search Open Food Facts by name, scan a barcode,
/// or create a new one inline. Calls `onSelect` with the chosen/created item and dismisses
/// itself.
struct FoodItemPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// True (the default) when this picker is itself the whole "screen" — selecting an item
    /// means the caller is done and this view should close. False when a caller instead
    /// swaps this picker out for its own next screen on selection (the "search food first"
    /// entry flow, `LogFoodFlowView`), where calling `dismiss()` here would close the whole
    /// flow instead of handing off to what comes next.
    var dismissesAfterSelection: Bool = true
    /// Declared after `dismissesAfterSelection` so it's the memberwise init's last parameter
    /// — callers pass it as a trailing closure (e.g. `FoodItemPickerView(dismissesAfterSelection: false) { item in ... }`),
    /// which only forward-matches (no deprecated backward-matching) when the closure param is last.
    let onSelect: (FoodItem) -> Void

    @State private var searchText = ""
    @State private var selectedTab: PickerTab = .recents
    @State private var onlineResults: [FoodItem] = []
    @State private var isSearchingOnline = false
    @State private var isShowingAllOnlineResults = false
    @State private var isPresentingNewFoodForm = false
    @State private var isPresentingScanner = false
    @State private var scanState: ScanFlowState = .idle

    private static let collapsedOnlineResultCount = 10

    private let viewModel = NutritionViewModel()

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespaces)
    }

    private var isSearching: Bool {
        !trimmedQuery.isEmpty
    }

    /// Catalog matches actually created under My Meals — excludes anything with a brand, even
    /// though a brand item lands in the same local catalog once it's been searched or logged.
    private var localMatches: [FoodItem] {
        viewModel.searchFoodItems(matching: searchText, in: modelContext).filter(Self.isMyMeal)
    }

    private var recentItems: [FoodItem] {
        viewModel.recentFoodItems(in: modelContext)
    }

    private var myMealItems: [FoodItem] {
        viewModel.searchFoodItems(matching: "", in: modelContext).filter(Self.isMyMeal)
    }

    private static nonisolated func isMyMeal(_ item: FoodItem) -> Bool {
        (item.brand ?? "").isEmpty
    }

    private var visibleOnlineResults: [FoodItem] {
        isShowingAllOnlineResults ? onlineResults : Array(onlineResults.prefix(Self.collapsedOnlineResultCount))
    }

    var body: some View {
        VStack(spacing: 0) {
            searchRow
                .padding(.horizontal)
                .padding(.top, 8)

            if !isSearching {
                Picker("", selection: $selectedTab) {
                    Text("Recents").tag(PickerTab.recents)
                    Text("My Meals").tag(PickerTab.myMeals)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
            }
            List {
                if isSearching {
                    searchingContent
                } else {
                    switch selectedTab {
                    case .recents:
                        if recentItems.isEmpty {
                            ContentUnavailableView("No Recent Foods", systemImage: "clock", description: Text("Foods you search for or log will show up here."))
                        } else {
                            ForEach(recentItems) { item in foodRow(item) }
                                .onDelete { offsets in deleteItems(recentItems, at: offsets) }
                        }
                    case .myMeals:
                        ForEach(myMealItems) { item in foodRow(item) }
                            .onDelete { offsets in deleteItems(myMealItems, at: offsets) }
                    }
                }
            }
        }
        .navigationTitle("Choose Food")
        .task(id: searchText) {
            await performOnlineSearch()
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
                    select(newItem)
                }
            }
        }
        .sheet(isPresented: $isPresentingNewFoodForm) {
            NavigationStack {
                NewFoodItemView(prefillName: trimmedQuery) { newItem in
                    select(newItem)
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

    private var searchRow: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search foods", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))

            Button {
                startScan()
            } label: {
                Image(systemName: "barcode.viewfinder")
                    .font(.title3)
            }
            .accessibilityLabel("Scan Barcode")
        }
    }

    @ViewBuilder
    private func foodRow(_ item: FoodItem, highlighting query: String = "") -> some View {
        Button {
            select(item)
        } label: {
            VStack(alignment: .leading) {
                highlightedText(item.name, matching: query)
                    .foregroundStyle(Color.primary)
                Text(subtitle(for: item))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// `item.name` with the first case-insensitive occurrence of `query` bolded — e.g.
    /// searching "orange" bolds just "Orange" within "Orange Juice". Falls back to plain
    /// text when there's no query (the Recents/My Meals tabs, where nothing was searched) or
    /// no match.
    private func highlightedText(_ name: String, matching query: String) -> Text {
        guard !query.isEmpty,
              let range = name.range(of: query, options: .caseInsensitive) else {
            return Text(name)
        }
        var attributed = AttributedString(name)
        if let attributedRange = Range(range, in: attributed) {
            attributed[attributedRange].inlinePresentationIntent = .stronglyEmphasized
        }
        return Text(attributed)
    }

    /// Distinguishes, e.g., a Fairtrade banana from one created locally under the same name
    /// — a brand name when the item came from Open Food Facts/a barcode scan, or "My Meals"
    /// for anything created by hand.
    private func subtitle(for item: FoodItem) -> String {
        let base = "\(Int(item.caloriesPer100g)) kcal / 100g"
        let source = (item.brand?.isEmpty == false) ? item.brand! : "My Meals"
        return "\(base) / \(source)"
    }

    @ViewBuilder
    private var searchingContent: some View {
        if !onlineResults.isEmpty || isSearchingOnline {
            Section("Search Results") {
                if isSearchingOnline && onlineResults.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
                ForEach(visibleOnlineResults) { item in foodRow(item, highlighting: trimmedQuery) }
                if !isShowingAllOnlineResults && onlineResults.count > Self.collapsedOnlineResultCount {
                    Button("See More") {
                        isShowingAllOnlineResults = true
                    }
                }
            }
        }
        // Always shown while searching — not just when there's a local match — so a food
        // that isn't in the catalog yet still has somewhere to be added from. The "Add"
        // button stays even when there are matches too — someone might genuinely want a
        // second, differently-tracked item with the same name (e.g. their own recipe vs. a
        // store-bought version).
        Section("My Meals") {
            ForEach(localMatches) { item in foodRow(item, highlighting: trimmedQuery) }
            Button {
                isPresentingNewFoodForm = true
            } label: {
                Label("Add \"\(trimmedQuery)\"", systemImage: "plus")
            }
        }
    }

    /// Marks `item` as just-used (feeds the Recents tab) and returns it to the caller.
    /// Inserts it into the store first if it isn't already tracked — true for a freshly
    /// mapped Open Food Facts search result, false for anything already in the catalog. A
    /// transient search result whose barcode already exists locally reuses that catalog
    /// entry instead of inserting a duplicate.
    private func select(_ item: FoodItem) {
        var item = item
        if item.modelContext == nil {
            if let barcode = item.barcode, let existing = viewModel.findFoodItem(byBarcode: barcode, in: modelContext) {
                item = existing
            } else {
                modelContext.insert(item)
            }
        }
        item.lastUsedAt = .now
        onSelect(item)
        if dismissesAfterSelection {
            dismiss()
        }
    }

    /// Removes a food from the local catalog for good — safe even for a food with logged
    /// history, since `FoodEntry` snapshots its own macros/name at log time and only
    /// nullifies its (already convenience-only) back-link to `FoodItem` on delete.
    private func deleteItems(_ items: [FoodItem], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(items[index])
        }
        try? modelContext.save()
    }

    private func performOnlineSearch() async {
        isShowingAllOnlineResults = false
        guard isSearching else {
            onlineResults = []
            isSearchingOnline = false
            return
        }
        let query = trimmedQuery
        try? await Task.sleep(nanoseconds: 400_000_000)
        guard !Task.isCancelled else { return }
        isSearchingOnline = true
        do {
            let matches = try await viewModel.searchOpenFoodFacts(matching: query, client: OpenFoodFactsClient())
            guard !Task.isCancelled else { return }
            onlineResults = matches
        } catch {
            guard !Task.isCancelled else { return }
            onlineResults = []
        }
        isSearchingOnline = false
    }

    private func lookup(barcode: String) async {
        if let existing = viewModel.findFoodItem(byBarcode: barcode, in: modelContext) {
            select(existing)
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

/// Unit for the "Default Serving Size" field — `defaultServingSizeG` is always stored in
/// grams, so `.ounces` and `.serving` are both purely data-entry conveniences, converted on
/// save. `.serving` is for foods naturally counted rather than weighed (e.g. "1 apple") —
/// picking it is what reveals the "Unit Name" field, so a food that's just measured in
/// grams/ounces never shows an unrelated, confusing "Unit Name" box.
private enum WeightUnit: Hashable {
    case grams
    case ounces
    case serving

    /// International avoirdupois ounce, matching US nutrition labels. `.serving`'s amount
    /// is entered directly in grams, same as `.grams`.
    var gramsPerUnit: Double {
        self == .ounces ? 28.349523125 : 1
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
    private let brand: String?

    @State private var name: String
    @State private var caloriesText: String
    @State private var proteinText: String
    @State private var carbText: String
    @State private var fatText: String
    @State private var servingSizeText: String
    @State private var servingSizeUnit: WeightUnit = .grams
    @State private var servingUnitLabel: String

    /// `prefillName` seeds the name field for the "add a food that wasn't in search"
    /// affordance — ignored when `prefill` is given (the barcode-review flow), which has
    /// its own name.
    init(prefill: FoodItem? = nil, prefillName: String = "", onCreate: @escaping (FoodItem) -> Void) {
        self.onCreate = onCreate
        self.barcode = prefill?.barcode
        self.brand = prefill?.brand
        _name = State(initialValue: prefill?.name ?? prefillName)
        // Always show the real number, including 0 — Open Food Facts genuinely reports 0
        // for some macros, and hiding it as a blank field both misleads (looks like
        // nothing was fetched) and fails validation (an empty field can't Save).
        _caloriesText = State(initialValue: prefill.map { Self.formatMacro($0.caloriesPer100g) } ?? "")
        _proteinText = State(initialValue: prefill.map { Self.formatMacro($0.proteinG) } ?? "")
        _carbText = State(initialValue: prefill.map { Self.formatMacro($0.carbG) } ?? "")
        _fatText = State(initialValue: prefill.map { Self.formatMacro($0.fatG) } ?? "")
        _servingSizeText = State(initialValue: prefill.map { Self.formatMacro($0.defaultServingSizeG) } ?? "100")
        _servingUnitLabel = State(initialValue: prefill?.servingUnitLabel ?? "")
        // A barcode-scanned prefill may already carry a named unit (from OFF's serving_size
        // field, e.g. "medium apple") — default the picker to Serving so it's visible
        // instead of silently hiding a value that's already there.
        _servingSizeUnit = State(initialValue: (prefill?.servingUnitLabel?.isEmpty == false) ? .serving : .grams)
    }

    private static func formatMacro(_ value: Double) -> String {
        String(format: "%g", value)
    }

    /// `servingSizeText` converted to grams regardless of `servingSizeUnit` — what actually
    /// gets stored in `defaultServingSizeG`.
    private var servingSizeGrams: Double? {
        Double(servingSizeText).map { $0 * servingSizeUnit.gramsPerUnit }
    }

    private var servingSizeAmountLabel: String {
        switch servingSizeUnit {
        case .grams: return "Amount (g)"
        case .ounces: return "Amount (oz)"
        case .serving: return "Grams per Serving"
        }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && Double(caloriesText) != nil
            && Double(proteinText) != nil
            && Double(carbText) != nil
            && Double(fatText) != nil
            && servingSizeGrams != nil
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
                    Text(servingSizeAmountLabel)
                    Spacer()
                    // The "≈Xg" hint lives inside this same row rather than its own
                    // conditionally-appearing one — see LogFoodEntryView's identical
                    // pattern for why a row that appears/disappears is worth avoiding.
                    VStack(alignment: .trailing, spacing: 2) {
                        TextField("Serving size", text: $servingSizeText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        if servingSizeUnit == .ounces, let servingSizeGrams {
                            Text("≈ \(Int(servingSizeGrams))g")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                HStack {
                    Text("Unit")
                    Spacer()
                    // "Unit Name" lives inside this same row (as a second line, only when
                    // .serving is picked) rather than its own row that appears/disappears —
                    // same row-structure-stability reasoning as the "≈Xg" hint above.
                    VStack(alignment: .trailing, spacing: 4) {
                        Picker("", selection: $servingSizeUnit) {
                            Text("Grams").tag(WeightUnit.grams)
                            Text("Ounces").tag(WeightUnit.ounces)
                            Text("Serving").tag(WeightUnit.serving)
                        }
                        .labelsHidden()
                        .onChange(of: servingSizeUnit) { oldUnit, newUnit in
                            guard oldUnit != newUnit, let amount = Double(servingSizeText) else { return }
                            let grams = amount * oldUnit.gramsPerUnit
                            servingSizeText = Self.formatMacro(grams / newUnit.gramsPerUnit)
                        }
                        if servingSizeUnit == .serving {
                            TextField("e.g. apple, cup, slice", text: $servingUnitLabel)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(.secondary)
                        }
                    }
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
              let servingSizeGrams else { return }

        // Only persist a unit label when "Serving" is actually selected — otherwise a name
        // typed before switching away would linger unused on the saved food.
        let trimmedUnitLabel = servingSizeUnit == .serving
            ? servingUnitLabel.trimmingCharacters(in: .whitespaces)
            : ""
        let item = FoodItem(
            name: name.trimmingCharacters(in: .whitespaces),
            caloriesPer100g: calories,
            proteinG: protein,
            carbG: carb,
            fatG: fat,
            defaultServingSizeG: servingSizeGrams,
            barcode: barcode,
            brand: brand,
            servingUnitLabel: trimmedUnitLabel.isEmpty ? nil : trimmedUnitLabel
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
