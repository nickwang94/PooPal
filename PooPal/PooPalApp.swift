import SwiftData
import SwiftUI

@main
struct PooPalApp: App {
    private let container: ModelContainer
    /// In-memory screenshot/demo modes must not touch the real store, widget or reminders.
    static let usesInMemoryStore = ProcessInfo.processInfo.arguments.contains("-demoData")
        || ProcessInfo.processInfo.arguments.contains("-emptyStore")

    init() {
        ReminderSettings.registerDefaults()
        container = PooPalApp.makeContainer()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, DateText.locale)
        }
        .modelContainer(container)
    }

    /// `-demoData` seeds sample entries into an in-memory store; `-emptyStore` starts from an
    /// empty in-memory store. Both leave the real on-device data untouched (used for screenshots).
    static func makeContainer() -> ModelContainer {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-demoData") {
            return PreviewData.container
        }
        if arguments.contains("-emptyStore") {
            return SharedStore.inMemoryContainer()
        }
        let container = SharedStore.container
        SharedStore.importLegacyStoreIfNeeded(into: container)
        return container
    }
}

struct ContentView: View {
    enum Tab: Hashable {
        case home, history
    }

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var context

    /// `-startTab history` opens the history tab on launch (used for screenshots).
    @State private var tab: Tab = UserDefaults.standard.string(forKey: "startTab") == "history" ? .history : .home
    /// Bumped when the widget wrote to the store, so the queries refetch.
    @State private var refreshToken = 0
    @State private var seenExternalChange = SharedStore.lastExternalChange

    var body: some View {
        TabView(selection: $tab) {
            HomeView()
                .id(refreshToken)
                .tabItem { Label("首页", systemImage: "house.fill") }
                .tag(Tab.home)
            HistoryView()
                .id(refreshToken)
                .tabItem { Label("记录", systemImage: "calendar") }
                .tag(Tab.history)
        }
        .tint(Theme.poop)
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, !PooPalApp.usesInMemoryStore else { return }
            let latest = SharedStore.lastExternalChange
            if latest != seenExternalChange {
                seenExternalChange = latest
                refreshToken += 1
            }
            let lastEntry = DataActions.latestEntryDate(context)
            Task { await ReminderScheduler.reschedule(lastEntry: lastEntry) }
        }
    }
}

@MainActor
enum PreviewData {
    static let container: ModelContainer = {
        let container = SharedStore.inMemoryContainer()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let types = [4, 3, 4, 5, 4, 2, 4, 6, 3, 4, 4, 1, 3, 4, 5]
        let notes: [Int: String] = [1: "昨晚吃了火锅", 6: "早上喝了一大杯咖啡", 13: "有点肚子不舒服", 30: "旅行第一天"]
        for day in 0..<84 {
            // Deterministic "random" pattern: mostly once a day, some skipped days, some twice.
            let pattern = (day * 7 + day / 5) % 9
            let times = day == 0 ? 1 : (pattern == 0 || pattern == 4 ? 0 : (pattern == 7 ? 2 : 1))
            for index in 0..<times {
                guard let dayDate = calendar.date(byAdding: .day, value: -day, to: today),
                      let date = calendar.date(bySettingHour: index == 0 ? 8 : 20, minute: 10 + day % 40, second: 0, of: dayDate),
                      date <= .now else { continue }
                let type = day % 5 == 3 ? nil : types[(day + index) % types.count]
                container.mainContext.insert(PoopEntry(timestamp: date, bristolType: type, note: index == 0 ? notes[day] : nil))
            }
        }
        return container
    }()
}
