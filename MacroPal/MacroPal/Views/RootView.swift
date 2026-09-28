//
//  RootView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// The tabs, plus `.add`: the + beside the tab bar. It's never actually selected — choosing
/// it opens `QuickAddSheet` and the current tab stays put.
enum AppTab: Hashable {
    case nutrition, training, profile, add
}

/// Pushes the Daily Log onto the Nutrition stack from outside it (the + beside the tab bar).
struct DailyLogRoute: Hashable {
    let date: Date
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var plans: [WorkoutPlan]
    @State private var restTimer = RestTimerModel()

    @State private var selectedTab: AppTab = .nutrition
    @State private var nutritionPath = NavigationPath()
    @State private var trainingPath = NavigationPath()
    @State private var isPresentingQuickAdd = false
    /// Held until the sheet has finished closing: pushing while it closes (and while a tab
    /// shows for the first time) drew the pushed page's large title over its content.
    @State private var pendingQuickAdd: QuickAddChoice?

    /// Blue with a white +, like the floating button it replaced. A tab bar draws its icons as
    /// templates in one flat color, so the icon is drawn as a picture and marked
    /// `.alwaysOriginal` to keep its colors. Drawn by hand rather than as a palette SF Symbol,
    /// which the tab bar still recolored (it came out green).
    private static let addIcon: UIImage = {
        let size = CGSize(width: 64, height: 64)
        let plus = UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .bold))?
            .withTintColor(.white, renderingMode: .alwaysOriginal)
        let image = UIGraphicsImageRenderer(size: size).image { _ in
            UIColor.systemBlue.setFill()
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).fill()
            if let plus {
                plus.draw(at: CGPoint(x: (size.width - plus.size.width) / 2,
                                      y: (size.height - plus.size.height) / 2))
            }
        }
        return image.withRenderingMode(.alwaysOriginal)
    }()

    private var todaysWorkout: PlanDay? {
        plans.first?.day(on: Calendar.current.component(.weekday, from: .now))
    }

    /// Picking the + opens the sheet instead of switching to it.
    private var tabSelection: Binding<AppTab> {
        Binding {
            selectedTab
        } set: { tab in
            if tab == .add {
                isPresentingQuickAdd = true
            } else {
                selectedTab = tab
            }
        }
    }

    var body: some View {
        TabView(selection: tabSelection) {
            Tab("Nutrition", systemImage: "fork.knife", value: AppTab.nutrition) {
                NavigationStack(path: $nutritionPath) {
                    DailySummaryView()
                        .navigationDestination(for: DailyLogRoute.self) { route in
                            FoodHistoryView(date: route.date)
                        }
                }
                .restOverCard()
            }

            Tab("Training", systemImage: "dumbbell", value: AppTab.training) {
                NavigationStack(path: $trainingPath) {
                    TrainingView()
                        .navigationDestination(for: PlanDay.self) { day in
                            PlanDayDetailView(day: day)
                        }
                }
                .restOverCard()
            }

            // No Insights tab: each rule's finding shows inline where it's relevant
            // (`InsightCallout`) — protein on Nutrition, weight on the Goals card, stalls on
            // Exercise Progress.

            Tab("Profile", systemImage: "person.circle", value: AppTab.profile) {
                NavigationStack {
                    ProfileView()
                }
                .restOverCard()
            }

            // The search role is what gives a tab its own circle to the right of the tab bar
            // on iPhone; here it's the + for logging, not a search.
            Tab(value: AppTab.add, role: .search) {
                Color.clear
            } label: {
                Label {
                    Text("Add")
                } icon: {
                    Image(uiImage: Self.addIcon)
                }
            }
        }
        .sheet(isPresented: $isPresentingQuickAdd, onDismiss: openPendingQuickAdd) {
            QuickAddSheet(workout: todaysWorkout, hasPlan: !plans.isEmpty) { choice in
                pendingQuickAdd = choice
                isPresentingQuickAdd = false
            }
        }
        // One rest timer for the whole app, so it survives moving between workout screens.
        .environment(restTimer)
        // Here, not in the card: there's one card per tab (and one in the unplanned-workout
        // sheet), but the end of a rest should buzz once.
        .sensoryFeedback(.success, trigger: restTimer.finishedAt) { _, new in new != nil }
        .task {
            StarterExerciseCatalog.regroup(in: modelContext)
            StarterExerciseCatalog.seedIfNeeded(in: modelContext)
        }
    }

    /// Switches to the chosen tab, then — once it's on screen — opens the page on a fresh
    /// stack, so it's one back swipe from the tab's own screen whatever was open there before.
    private func openPendingQuickAdd() {
        guard let choice = pendingQuickAdd else { return }
        pendingQuickAdd = nil
        switch choice {
        case .logFood:
            selectedTab = .nutrition
            DispatchQueue.main.async {
                nutritionPath = NavigationPath([DailyLogRoute(date: Calendar.current.startOfDay(for: .now))])
            }
        case .logWorkout(let day):
            selectedTab = .training
            DispatchQueue.main.async {
                trainingPath = NavigationPath([day])
            }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(
            for: [UserProfile.self, FoodItem.self, FoodEntry.self, WeightEntry.self, Exercise.self, WorkoutSession.self, WorkoutSetEntry.self, Insight.self],
            inMemory: true
        )
}
