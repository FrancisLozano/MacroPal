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
    case history
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
    @State private var selectedTab: PickerTab = .history
    @State private var onlineResults: [FoodItem] = []
    @State private var isSearchingOnline = false
    @State private var isShowingAllOnlineResults = false
    @State private var isShowingAllRecents = false
    @State private var isPresentingNewFoodForm = false
    @State private var isPresentingNewMealForm = false
    @State private var mealToEdit: FoodItem?
    @State private var manuallyAddedItemToEdit: FoodItem?
    @State private var isPresentingScanner = false
    @State private var scanState: ScanFlowState = .idle

    private static let collapsedOnlineResultCount = 10
    private static let collapsedRecentCount = 7

    private let viewModel = NutritionViewModel()

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespaces)
    }

    private var isSearching: Bool {
        !trimmedQuery.isEmpty
    }

    /// Search matches among real meals (built via New Meal/Edit Meal) — searching should
    /// still find your own recipes by name, just under their own section.
    private var matchingMeals: [FoodItem] {
        viewModel.searchFoodItems(matching: searchText, in: modelContext).filter { $0.isMeal }
    }

    /// Search matches among manually-added, non-meal foods — e.g. something typed in by
    /// hand because it wasn't in Open Food Facts.
    private var matchingManuallyAdded: [FoodItem] {
        viewModel.searchFoodItems(matching: searchText, in: modelContext).filter(Self.isManuallyAdded)
    }

    /// Recently used items, any source — a meal lives only under its own tab even after
    /// being logged, so recency doesn't pull it back into History too.
    private var recentItems: [FoodItem] {
        viewModel.recentFoodItems(in: modelContext).filter { !$0.isMeal }
    }

    private var visibleRecentItems: [FoodItem] {
        isShowingAllRecents ? recentItems : Array(recentItems.prefix(Self.collapsedRecentCount))
    }

    /// The full manually-added catalog (not just recently-used ones) — its own permanent
    /// list under History, separate from the "used recently" Recents section above it.
    private var manuallyAddedItems: [FoodItem] {
        viewModel.searchFoodItems(matching: "", in: modelContext).filter(Self.isManuallyAdded)
    }

    private var myMealItems: [FoodItem] {
        viewModel.searchFoodItems(matching: "", in: modelContext).filter { $0.isMeal }
    }

    /// A food typed in by hand rather than coming from Open Food Facts/a barcode scan —
    /// distinct from a meal (see `FoodItem.isMeal`), which also has no brand but belongs
    /// under My Meals instead.
    private static nonisolated func isManuallyAdded(_ item: FoodItem) -> Bool {
        !item.isMeal && (item.brand ?? "").isEmpty
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
                    Text("History").tag(PickerTab.history)
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
                    case .history:
                        Section("Recents") {
                            if recentItems.isEmpty {
                                Text("Foods you search for or log will show up here.")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(visibleRecentItems) { item in foodRow(item) }
                                    .onDelete { offsets in deleteItems(visibleRecentItems, at: offsets) }
                                if !isShowingAllRecents && recentItems.count > Self.collapsedRecentCount {
                                    Button("See More") {
                                        isShowingAllRecents = true
                                    }
                                }
                            }
                        }
                        Section("Foods Manually Added") {
                            if manuallyAddedItems.isEmpty {
                                Text("Foods you add by hand will show up here.")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(manuallyAddedItems) { item in
                                    foodRow(item, showSource: false)
                                        .swipeActions(edge: .leading) {
                                            Button {
                                                manuallyAddedItemToEdit = item
                                            } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }
                                            .tint(.blue)
                                        }
                                }
                                .onDelete { offsets in deleteItems(manuallyAddedItems, at: offsets) }
                            }
                        }
                    case .myMeals:
                        Button {
                            isPresentingNewMealForm = true
                        } label: {
                            Label("New Meal", systemImage: "plus")
                        }
                        ForEach(myMealItems) { item in
                            foodRow(item, showSource: false)
                                .swipeActions(edge: .leading) {
                                    Button {
                                        mealToEdit = item
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                        }
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
        .sheet(isPresented: $isPresentingNewMealForm) {
            NavigationStack {
                NewMealView { newItem in
                    select(newItem)
                }
            }
        }
        .sheet(item: $mealToEdit) { item in
            NavigationStack {
                EditMealView(mealItem: item)
            }
        }
        .sheet(item: $manuallyAddedItemToEdit) { item in
            NavigationStack {
                NewFoodItemView(editing: item)
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
    /// `showSource` is false only for rows already inside the My Meals tab, where every row
    /// is a My Meals item by definition — repeating that as a subtitle on each one is just
    /// noise there, even though it's useful context in Recents or search results.
    private func foodRow(_ item: FoodItem, highlighting query: String = "", showSource: Bool = true) -> some View {
        Button {
            select(item)
        } label: {
            VStack(alignment: .leading) {
                highlightedText(item.name, matching: query)
                    .foregroundStyle(Color.primary)
                Text(subtitle(for: item, showSource: showSource))
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
    /// — a brand name when the item came from Open Food Facts/a barcode scan, "My Meals" for
    /// a recipe, or "Manually Added" for a plain food typed in by hand. `showSource: false`
    /// drops this entirely (see `foodRow`).
    private func subtitle(for item: FoodItem, showSource: Bool = true) -> String {
        let base = "\(Int(item.caloriesPer100g.rounded())) kcal / 100g"
        guard showSource else { return base }
        let source: String
        if let brand = item.brand, !brand.isEmpty {
            source = brand
        } else if item.isMeal {
            source = "My Meals"
        } else {
            source = "Manually Added"
        }
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
        if !matchingMeals.isEmpty {
            Section("My Meals") {
                ForEach(matchingMeals) { item in foodRow(item, highlighting: trimmedQuery, showSource: false) }
            }
        }
        // Always shown while searching — not just when there's a local match — so a food
        // that isn't in the catalog yet still has somewhere to be added from. The "Add"
        // button stays even when there are matches too — someone might genuinely want a
        // second, differently-tracked item with the same name (e.g. their own recipe vs. a
        // store-bought version).
        Section("Foods Manually Added") {
            ForEach(matchingManuallyAdded) { item in foodRow(item, highlighting: trimmedQuery, showSource: false) }
            if matchingManuallyAdded.isEmpty {
                Text("Item not found in database")
                    .foregroundStyle(.secondary)
            }
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

/// Inline "create new food" form, used both when the desired food isn't in the catalog
/// yet and to review/edit a barcode-scanned result before saving (Open Food Facts data
/// quality varies, so this is always editable, never auto-saved).
private struct NewFoodItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let onCreate: (FoodItem) -> Void

    /// The existing item being edited in place, or nil when this form is creating a new
    /// one (a fresh manual entry or a barcode-scan review) — `save()` mutates this item
    /// instead of inserting a new `FoodItem` when it's set.
    private let editingItem: FoodItem?
    private let barcode: String?
    private let brand: String?

    @State private var name: String
    @State private var caloriesText: String
    @State private var proteinText: String
    @State private var carbText: String
    @State private var fatText: String
    @State private var servingSizeText: String
    @State private var servingSizeUnit: ServingAmountUnit = .grams
    @State private var servingUnitLabel: String

    /// `prefillName` seeds the name field for the "add a food that wasn't in search"
    /// affordance — ignored when `prefill` or `editing` is given, which have their own name.
    /// `editing` puts the form in edit-in-place mode for an already-saved manually-added
    /// food (swipe-to-edit from "Foods Manually Added"); `prefill` is the barcode-review
    /// flow, which always creates a new item on save.
    init(editing item: FoodItem? = nil, prefill: FoodItem? = nil, prefillName: String = "", onCreate: @escaping (FoodItem) -> Void = { _ in }) {
        self.onCreate = onCreate
        self.editingItem = item
        let source = item ?? prefill
        self.barcode = source?.barcode
        self.brand = source?.brand
        _name = State(initialValue: source?.name ?? prefillName)
        // Always show the real number, including 0 — Open Food Facts genuinely reports 0
        // for some macros, and hiding it as a blank field both misleads (looks like
        // nothing was fetched) and fails validation (an empty field can't Save).
        // Source's macros are stored per-100g; scale them to the item's own default
        // serving size since that's what this form now asks for.
        _caloriesText = State(initialValue: source.map { Self.formatMacro($0.caloriesPer100g * $0.defaultServingSizeG / 100) } ?? "")
        _proteinText = State(initialValue: source.map { Self.formatMacro($0.proteinG * $0.defaultServingSizeG / 100) } ?? "")
        _carbText = State(initialValue: source.map { Self.formatMacro($0.carbG * $0.defaultServingSizeG / 100) } ?? "")
        _fatText = State(initialValue: source.map { Self.formatMacro($0.fatG * $0.defaultServingSizeG / 100) } ?? "")
        _servingSizeText = State(initialValue: source.map { Self.formatMacro($0.defaultServingSizeG) } ?? "100")
        _servingUnitLabel = State(initialValue: source?.servingUnitLabel ?? "")
        // A barcode-scanned prefill (or an already-edited item) may already carry a named
        // unit (from OFF's serving_size field, e.g. "medium apple") — default the picker to
        // Serving so it's visible instead of silently hiding a value that's already there.
        _servingSizeUnit = State(initialValue: (source?.servingUnitLabel?.isEmpty == false) ? .count : .grams)
    }

    private static func formatMacro(_ value: Double) -> String {
        String(format: "%g", value)
    }

    /// Grams in one of `unit`, for defining this food's default serving. `.count`'s amount
    /// is entered directly in grams (defining "1 serving" itself), same as `.grams`.
    private func gramsPerUnit(_ unit: ServingAmountUnit) -> Double {
        unit.fixedGramsPerUnit ?? 1
    }

    /// `servingSizeText` converted to grams regardless of `servingSizeUnit` — what actually
    /// gets stored in `defaultServingSizeG`.
    private var servingSizeGrams: Double? {
        AmountParsing.parseAmount(servingSizeText).map { $0 * gramsPerUnit(servingSizeUnit) }
    }

    private var servingSizeAmountLabel: String {
        servingSizeUnit == .count ? "Grams per Serving" : servingSizeUnit.amountFieldLabel
    }

    /// Macros are entered for the serving size itself (e.g. "36g, as printed on the
    /// label") rather than normalized to 100g, so the section title names the amount
    /// they're actually for.
    private var macrosSectionTitle: String {
        guard let servingSizeGrams else { return "Macros" }
        return "Macros per Serving (\(Int(servingSizeGrams.rounded()))g)"
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && Double(caloriesText) != nil
            && Double(proteinText) != nil
            && Double(carbText) != nil
            && Double(fatText) != nil
            && (servingSizeGrams ?? 0) > 0
    }

    var body: some View {
        Form {
            Section("Name") {
                TextField("Food name", text: $name)
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
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                        if servingSizeUnit != .grams && servingSizeUnit != .count, let servingSizeGrams {
                            Text("≈ \(Int(servingSizeGrams.rounded()))g")
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
                            Text("Grams").tag(ServingAmountUnit.grams)
                            Text("Ounces").tag(ServingAmountUnit.ounces)
                            Text("Cups").tag(ServingAmountUnit.cups)
                            Text("Tbsp").tag(ServingAmountUnit.tablespoons)
                            Text("Tsp").tag(ServingAmountUnit.teaspoons)
                            Text("Serving").tag(ServingAmountUnit.count)
                        }
                        .labelsHidden()
                        .onChange(of: servingSizeUnit) { oldUnit, newUnit in
                            guard oldUnit != newUnit, let amount = AmountParsing.parseAmount(servingSizeText) else { return }
                            let grams = amount * gramsPerUnit(oldUnit)
                            servingSizeText = Self.formatMacro(grams / gramsPerUnit(newUnit))
                        }
                        if servingSizeUnit == .count {
                            TextField("e.g. apple, cup, slice", text: $servingUnitLabel)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Section(macrosSectionTitle) {
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
        }
        .navigationTitle(editingItem == nil ? "New Food" : "Edit Food")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!isValid)
            }
        }
    }

    private func save() {
        guard let enteredCalories = Double(caloriesText),
              let enteredProtein = Double(proteinText),
              let enteredCarb = Double(carbText),
              let enteredFat = Double(fatText),
              let servingSizeGrams, servingSizeGrams > 0 else { return }

        // Only persist a unit label when "Serving" is actually selected — otherwise a name
        // typed before switching away would linger unused on the saved food.
        let trimmedUnitLabel = servingSizeUnit == .count
            ? servingUnitLabel.trimmingCharacters(in: .whitespaces)
            : ""
        // FoodItem stores macros per-100g throughout the app, but this form asks for them
        // per the entered serving size (matching how a nutrition label reads) — scale back.
        let scale = 100 / servingSizeGrams

        if let editingItem {
            editingItem.name = name.trimmingCharacters(in: .whitespaces)
            editingItem.caloriesPer100g = enteredCalories * scale
            editingItem.proteinG = enteredProtein * scale
            editingItem.carbG = enteredCarb * scale
            editingItem.fatG = enteredFat * scale
            editingItem.defaultServingSizeG = servingSizeGrams
            editingItem.servingUnitLabel = trimmedUnitLabel.isEmpty ? nil : trimmedUnitLabel
            try? modelContext.save()
            dismiss()
            return
        }

        let item = FoodItem(
            name: name.trimmingCharacters(in: .whitespaces),
            caloriesPer100g: enteredCalories * scale,
            proteinG: enteredProtein * scale,
            carbG: enteredCarb * scale,
            fatG: enteredFat * scale,
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
