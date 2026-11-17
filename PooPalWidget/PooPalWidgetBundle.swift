import SwiftData
import SwiftUI
import WidgetKit

@main
struct PooPalWidgetBundle: WidgetBundle {
    var body: some Widget {
        PooPalWidget()
    }
}

struct PooPalWidget: Widget {
    static let kind = "PooPalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: PoopTimelineProvider()) { entry in
            PooPalWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(colors: [Theme.sunny, Theme.sunnyDeep], startPoint: .top, endPoint: .bottom)
                }
        }
        .configurationDisplayName("PooPal 一键记录")
        .description("在桌面点一下就记好，还能看看今天来了几次。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct PoopWidgetEntry: TimelineEntry {
    let date: Date
    let todayCount: Int
    let last7DaysCount: Int
    let daysSinceLast: Int?
    let lastDate: Date?

    static let sample = PoopWidgetEntry(date: .now, todayCount: 1, last7DaysCount: 6, daysSinceLast: 0, lastDate: .now)
}

struct PoopTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> PoopWidgetEntry { .sample }

    func getSnapshot(in context: Context, completion: @escaping (PoopWidgetEntry) -> Void) {
        completion(context.isPreview ? .sample : load())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PoopWidgetEntry>) -> Void) {
        let entry = load()
        // Day-based numbers change at midnight even without new records.
        let midnight = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: .now)) ?? .now
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }

    private func load() -> PoopWidgetEntry {
        let context = ModelContext(SharedStore.container)
        let dates = ((try? context.fetch(FetchDescriptor<PoopEntry>())) ?? []).map(\.timestamp)
        let stats = PoopStats(dates: dates)
        return PoopWidgetEntry(
            date: .now,
            todayCount: stats.todayCount,
            last7DaysCount: stats.last7DaysCount,
            daysSinceLast: stats.daysSinceLast,
            lastDate: stats.lastDate
        )
    }
}

#Preview(as: .systemSmall) {
    PooPalWidget()
} timeline: {
    PoopWidgetEntry.sample
}

#Preview(as: .systemMedium) {
    PooPalWidget()
} timeline: {
    PoopWidgetEntry.sample
}
