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
                    LinearGradient(colors: [Theme.butter, Theme.peach], startPoint: .top, endPoint: .bottom)
                }
        }
        .configurationDisplayName("PooPal 一键记录")
        .description("在桌面点一下就能记录便便，还能看到今天的次数。")
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

struct PooPalWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PoopWidgetEntry

    private var statusText: String {
        switch entry.daysSinceLast {
        case nil: "还没有记录"
        case 0?: entry.lastDate.map { "上次 \(DateText.time($0))" } ?? "今天记过啦"
        case 1?: "昨天便便过"
        case let days?: "\(days) 天没记录了"
        }
    }

    var body: some View {
        switch family {
        case .systemMedium: medium
        default: small
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                PoopMascot(expression: entry.daysSinceLast.map { $0 >= 2 } ?? false ? .worried : .happy)
                    .frame(width: 40, height: 40)
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(entry.todayCount)")
                        .font(.rounded(26, weight: .heavy))
                        .foregroundStyle(Theme.ink)
                        .contentTransition(.numericText())
                    Text("今日次数")
                        .font(.rounded(11, weight: .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            Text(statusText)
                .font(.rounded(12, weight: .medium))
                .foregroundStyle(Theme.inkSoft)
                .lineLimit(1)
            Spacer(minLength: 0)
            logButton(compact: true)
        }
    }

    private var medium: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    PoopMascot(expression: .happy)
                        .frame(width: 34, height: 34)
                    Text("PooPal")
                        .font(.rounded(18, weight: .heavy))
                        .foregroundStyle(Theme.poop)
                }
                HStack(spacing: 14) {
                    stat("\(entry.todayCount)", "今日")
                    stat("\(entry.last7DaysCount)", "近 7 天")
                }
                Text(statusText)
                    .font(.rounded(12, weight: .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer(minLength: 0)
            logButton(compact: false)
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .font(.rounded(24, weight: .heavy))
                .foregroundStyle(Theme.ink)
                .contentTransition(.numericText())
            Text(label)
                .font(.rounded(11, weight: .semibold))
                .foregroundStyle(Theme.inkSoft)
        }
    }

    @ViewBuilder
    private func logButton(compact: Bool) -> some View {
        Button(intent: LogPoopIntent()) {
            if compact {
                Label("记一次", systemImage: "plus")
                    .font(.rounded(14, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.white.opacity(0.85)))
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                    Text("记一次")
                        .font(.rounded(13, weight: .bold))
                }
                .foregroundStyle(Theme.ink)
                .frame(width: 96, height: 96)
                .background(Circle().fill(Color.white.opacity(0.85)))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("记录一次便便")
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
