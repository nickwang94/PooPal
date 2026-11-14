import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \PoopEntry.timestamp, order: .reverse) private var entries: [PoopEntry]

    @State private var showingAddSheet = UserDefaults.standard.bool(forKey: "showAddEntry")
    @State private var showingSettings = UserDefaults.standard.bool(forKey: "showSettings")
    @State private var editing: PoopEntry?
    @State private var lastLogged: PoopEntry?
    @State private var logCount = 0

    private var stats: PoopStats { PoopStats(dates: entries.map(\.timestamp)) }
    private var mood: PoopMood { PoopMood(daysSinceLast: stats.daysSinceLast) }
    private var commonType: BristolType? {
        PoopStats.mostCommonBristol(entries.map { ($0.timestamp, $0.bristolType) })
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        todayHeader
                        VStack(spacing: 12) {
                            LogTileButton(todayCount: stats.todayCount, action: logNow)
                            Button {
                                showingAddSheet = true
                            } label: {
                                Label("补记一次", systemImage: "clock.arrow.circlepath")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .tint(Theme.glaze)
                        }
                        WeekMosaic(dates: entries.map(\.timestamp))
                        StatsPanel(stats: stats, commonType: commonType)
                            .id("stats")
                        recentSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 96)
                }
                .onAppear {
                    // `-homeScroll stats` (screenshots only).
                    if UserDefaults.standard.string(forKey: "homeScroll") == "stats" {
                        proxy.scrollTo("stats", anchor: .top)
                    }
                }
            }
            .background(Theme.ground.ignoresSafeArea())
            .safeAreaInset(edge: .top, spacing: 0) {
                Color.clear.frame(height: 0).background(Theme.ground)
            }
            .toolbar(.hidden, for: .navigationBar)
            .overlay(alignment: .bottom) { toast }
            .sheet(isPresented: $showingAddSheet) { EntryEditorSheet() }
            .sheet(item: $editing) { EntryEditorSheet(entry: $0) }
            .sheet(isPresented: $showingSettings) { SettingsView() }
            .sensoryFeedback(.success, trigger: logCount)
        }
    }

    private var todayHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Logotype()
                    .frame(height: 22)
                Spacer()
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.title3)
                        .foregroundStyle(Theme.inkSoft)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("设置")
                .padding(.trailing, -10)
            }
            .padding(.bottom, 10)
            Text(DateText.header(.now))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.inkSoft)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("今天")
                    .font(.largeTitle.weight(.bold))
                Text("\(stats.todayCount)")
                    .font(.system(.largeTitle, design: .default, weight: .bold).monospacedDigit())
                    .foregroundStyle(Theme.glaze)
                    .contentTransition(.numericText())
                Text("次")
                    .font(.largeTitle.weight(.bold))
            }
            .foregroundStyle(Theme.ink)
            .accessibilityElement(children: .combine)
            Text(statusLine)
                .font(.body)
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(.top, 8)
    }

    private var statusLine: String {
        guard let elapsed = StatsFormat.elapsed(since: stats.lastDate) else { return mood.message }
        return "距上次 \(elapsed) · \(mood.message)"
    }

    @ViewBuilder
    private var recentSection: some View {
        if !entries.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle("最近")
                VStack(spacing: 0) {
                    let recent = Array(entries.prefix(3))
                    ForEach(recent) { entry in
                        Button {
                            editing = entry
                        } label: {
                            EntryRowContent(entry: entry, dayStyle: true)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if entry.id != recent.last?.id {
                            Divider().overlay(Theme.grout).padding(.leading, 66)
                        }
                    }
                }
                .panel()
            }
        }
    }

    @ViewBuilder
    private var toast: some View {
        if let lastLogged {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.glaze)
                Text("已记录 \(DateText.time(lastLogged.timestamp))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                Spacer(minLength: 8)
                Button("补充详情") {
                    editing = lastLogged
                    withAnimation(.easeOut) { self.lastLogged = nil }
                }
                .font(.subheadline.weight(.semibold))
                Button("撤销") { undo(lastLogged) }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.coral)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(Theme.grout.opacity(0.6), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.12), radius: 16, y: 6)
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func logNow() {
        let entry = PoopEntry(timestamp: .now)
        context.insert(entry)
        DataActions.didChange(context, requestNotificationPermission: true)
        logCount += 1
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { lastLogged = entry }
        let current = logCount
        Task {
            try? await Task.sleep(for: .seconds(6))
            if current == logCount {
                withAnimation(.easeOut) { lastLogged = nil }
            }
        }
    }

    private func undo(_ entry: PoopEntry) {
        context.delete(entry)
        DataActions.didChange(context)
        withAnimation(.easeOut) { lastLogged = nil }
    }
}

struct SectionTitle: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.title3.weight(.semibold))
            .foregroundStyle(Theme.ink)
            .accessibilityAddTraits(.isHeader)
    }
}

/// The primary action: one large glazed tile. Today's entries appear inside it as small tiles.
struct LogTileButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let todayCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 30, weight: .semibold))
                    Spacer(minLength: 0)
                    Text("记一次")
                        .font(.title.weight(.bold))
                    Text("点一下，记录现在")
                        .font(.subheadline)
                        .opacity(0.9)
                }
                Spacer()
                TodayTiles(count: todayCount)
            }
            .foregroundStyle(Theme.onGlaze)
            .padding(22)
            .frame(maxWidth: .infinity, minHeight: 176, alignment: .leading)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(LinearGradient(colors: [Theme.actionTop, Theme.actionBottom], startPoint: .topLeading, endPoint: .bottomTrailing))
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(RadialGradient(colors: [.white.opacity(colorScheme == .dark ? 0.08 : 0.16), .clear], center: .topLeading, startRadius: 0, endRadius: 260))
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                }
            )
            .shadow(color: Theme.glazeDeep.opacity(0.35), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(PressableStyle(scale: 0.97))
        .accessibilityLabel("记一次，记录现在")
        .accessibilityValue("今天已记录 \(todayCount) 次")
    }
}

/// Up to 6 small tiles in a 3-column grid; filled ones are today's entries.
struct TodayTiles: View {
    let count: Int
    private let slots = 6

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(18), spacing: 5), count: 3), spacing: 5) {
                ForEach(0..<slots, id: \.self) { index in
                    let filled = index < count
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(filled ? Theme.onGlaze : Theme.onGlaze.opacity(0.16))
                        .frame(width: 18, height: 18)
                        .scaleEffect(filled ? 1 : 0.86)
                        .animation(.spring(response: 0.35, dampingFraction: 0.55).delay(Double(index) * 0.02), value: count)
                }
            }
            .frame(width: 64)
            Text(count > slots ? "今天 \(count) 次" : "今天")
                .font(.caption.weight(.medium))
                .opacity(0.9)
        }
        .accessibilityHidden(true)
    }
}

/// This week as seven tiles; shade deepens with the day's count.
struct WeekMosaic: View {
    let dates: [Date]
    private let calendar = Calendar.current

    private var days: [Date] {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: .now) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: week.start) }
    }

    var body: some View {
        let counts = PoopStats.countsByDay(dates, calendar: calendar)
        let weekTotal = days.reduce(0) { $0 + (counts[$1] ?? 0) }
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                SectionTitle("本周")
                Spacer()
                Text("\(weekTotal) 次")
                    .font(.subheadline.weight(.medium).monospacedDigit())
                    .foregroundStyle(Theme.inkSoft)
            }
            HStack(spacing: 8) {
                ForEach(days, id: \.self) { day in
                    let count = counts[day] ?? 0
                    let isToday = calendar.isDateInToday(day)
                    let future = day > .now
                    VStack(spacing: 6) {
                        ZStack {
                            GlazeTile(color: future ? Theme.surfaceSunk.opacity(0.5) : Theme.tile(for: count), radius: 10)
                            if count > 1 {
                                Text("\(count)")
                                    .font(.caption.weight(.bold).monospacedDigit())
                                    .foregroundStyle(Theme.tileInk(for: count))
                            }
                        }
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(isToday ? Theme.glaze : .clear, lineWidth: 1.5)
                                .padding(-3)
                        )
                        Text(DateText.weekdayShort(day))
                            .font(.caption2.weight(isToday ? .bold : .regular))
                            .foregroundStyle(isToday ? Theme.ink : Theme.inkSoft)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(DateText.dayTitle(day))，\(count) 次")
                }
            }
        }
    }
}

/// Plain, exact numbers in one grouped panel: label left, value right.
struct StatsPanel: View {
    let stats: PoopStats
    let commonType: BristolType?

    var body: some View {
        let interval = StatsFormat.interval(stats.averageIntervalDays)
        let rows: [(String, String, String)] = [
            ("平均间隔", interval.value, interval.unit),
            ("日均 · 全部", StatsFormat.perDay(stats.averagePerDay), stats.averagePerDay == nil ? "" : "次"),
            ("日均 · 近 30 天", StatsFormat.perDay(stats.averagePerDayLast30), stats.averagePerDayLast30 == nil ? "" : "次"),
            ("近 7 天", "\(stats.last7DaysCount)", "次"),
            ("近 30 天", "\(stats.last30DaysCount)", "次"),
            ("累计", "\(stats.totalCount)", "次"),
        ]
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle("数据")
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    StatRow(label: row.0, value: row.1, unit: row.2)
                    Divider().overlay(Theme.grout).padding(.leading, 16)
                }
                HStack {
                    Text("近 30 天常见形态")
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    if let commonType {
                        EntryBadge(type: commonType, size: 26)
                        Text("\(commonType.rawValue) 型 · \(commonType.name)")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.ink)
                    } else {
                        Text("—").foregroundStyle(Theme.inkSoft)
                    }
                }
                .padding(.horizontal, 16)
                .frame(minHeight: 48)
                .accessibilityElement(children: .combine)
            }
            .panel()
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(label)
                .foregroundStyle(Theme.ink)
            Spacer()
            Text(value)
                .font(.body.weight(.semibold).monospacedDigit())
                .foregroundStyle(Theme.ink)
            if !unit.isEmpty {
                Text(unit)
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 48)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HomeView()
        .modelContainer(PreviewData.container)
}
