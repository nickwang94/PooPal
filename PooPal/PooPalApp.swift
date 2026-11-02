import SwiftData
import SwiftUI

@main
struct PooPalApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, DateText.locale)
        }
        .modelContainer(PooPalApp.makeContainer())
    }

    /// `-demoData` seeds sample entries into an in-memory store; `-emptyStore` starts from an
    /// empty in-memory store. Both leave the real on-device data untouched (used for screenshots).
    static func makeContainer() -> ModelContainer {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-demoData") {
            return PreviewData.container
        }
        do {
            if arguments.contains("-emptyStore") {
                return try ModelContainer(
                    for: PoopEntry.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                )
            }
            return try ModelContainer(for: PoopEntry.self)
        } catch {
            fatalError("无法创建数据存储：\(error)")
        }
    }
}

struct ContentView: View {
    enum Tab: Hashable {
        case home, history
    }

    /// `-startTab history` opens the history tab on launch (used for screenshots).
    @State private var tab: Tab = UserDefaults.standard.string(forKey: "startTab") == "history" ? .history : .home

    var body: some View {
        TabView(selection: $tab) {
            HomeView()
                .tabItem { Label("首页", systemImage: "house.fill") }
                .tag(Tab.home)
            HistoryView()
                .tabItem { Label("记录", systemImage: "calendar") }
                .tag(Tab.history)
        }
        .tint(Theme.poop)
    }
}

@MainActor
enum PreviewData {
    static let container: ModelContainer = {
        do {
            let container = try ModelContainer(
                for: PoopEntry.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: .now)
            let offsets: [(day: Int, hour: Int)] = [
                (0, 8), (1, 9), (1, 20), (2, 7), (4, 8), (5, 10), (6, 9),
                (8, 8), (9, 21), (11, 7), (12, 9), (14, 8), (15, 19), (17, 8),
                (19, 9), (20, 8), (22, 10), (24, 7), (25, 20), (27, 9),
            ]
            for offset in offsets {
                if let day = calendar.date(byAdding: .day, value: -offset.day, to: today),
                   let date = calendar.date(bySettingHour: offset.hour, minute: 15, second: 0, of: day),
                   date <= .now {
                    container.mainContext.insert(PoopEntry(timestamp: date))
                }
            }
            return container
        } catch {
            fatalError("无法创建预览数据：\(error)")
        }
    }()
}
