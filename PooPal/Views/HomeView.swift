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
                    VStack(alignment: .leading, spacing: 30) {
                        todayHeader
                        VStack(spacing: 12) {
                            LogStickerButton(todayCount: stats.todayCount, burst: logCount, action: logNow)
                            Button {
                                showingAddSheet = true
                            } label: {
                                Label("忘了记？补一条", systemImage: "clock.arrow.circlepath")
                                    .font(.body.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.capsule)
                            .controlSize(.large)
                            .tint(Theme.accent)
                        }
                        WeekStickers(dates: entries.map(\.timestamp))
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
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Logotype(color: Theme.accent)
                    .frame(height: 22)
                Spacer()
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.inkSoft)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("设置")
                .padding(.trailing, -10)
            }
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(DateText.greeting(.now))，\(DateText.header(.now))")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.inkSoft)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("今天")
                        Text("\(stats.todayCount)")
                            .monospacedDigit()
                            .foregroundStyle(Theme.accent)
                            .contentTransition(.numericText())
                        Text("次")
                    }
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Theme.ink)
                    .accessibilityElement(children: .combine)
                    if let elapsed = StatsFormat.elapsed(since: stats.lastDate) {
                        Text(elapsed == "刚刚" ? "刚刚来过" : "距上次 \(elapsed)")
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                            .foregroundStyle(Theme.accent)
                    }
                    Text(mood.message)
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                PalBuddy(face: PalBuddy.Face(mood), hop: logCount)
                    .frame(width: 76, height: 76)
            }
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var recentSection: some View {
        if !entries.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle("最近几次")
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
                            Divider().overlay(Theme.line).padding(.leading, 66)
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
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.ideal)
                    .symbolEffect(.bounce, value: logCount)
                Text("记好啦 · \(DateText.time(lastLogged.timestamp))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                Spacer(minLength: 8)
                Button("加点细节") {
                    editing = lastLogged
                    withAnimation(.easeOut) { self.lastLogged = nil }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.accent)
                Button("撤销") { undo(lastLogged) }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.alert)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(.regularMaterial, in: Capsule())
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
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            logCount += 1
            lastLogged = entry
        }
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
            .font(.title3.weight(.bold))
            .foregroundStyle(Theme.ink)
            .accessibilityAddTraits(.isHeader)
    }
}

/// The primary action: a big marigold sticker. Today's visits appear on it as small stickers.
struct LogStickerButton: View {
    let todayCount: Int
    /// Changes on every log; drives the confetti.
    let burst: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Image(systemName: "plus")
                        .font(.title2.weight(.heavy))
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Theme.onSunny.opacity(0.1)))
                    Spacer(minLength: 0)
                    Text("记一下")
                        .font(.title.weight(.heavy))
                    Text("刚去过？点我就记好")
                        .font(.subheadline.weight(.medium))
                        .opacity(0.75)
                }
                Spacer()
                TodayStickers(count: todayCount)
            }
            .foregroundStyle(Theme.onSunny)
            .padding(22)
            .frame(maxWidth: .infinity, minHeight: 180, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(LinearGradient(colors: [Theme.sunny, Theme.sunnyDeep], startPoint: .top, endPoint: .bottom))
                    .overlay(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .strokeBorder(Theme.stickerEdge, lineWidth: 4)
                    )
                    .shadow(color: Theme.sunnyDeep.opacity(0.45), radius: 16, x: 0, y: 8)
            )
            .overlay { ConfettiBurst(trigger: burst) }
        }
        .buttonStyle(PressableStyle(scale: 0.95))
        .accessibilityLabel("记一下，记录现在")
        .accessibilityValue("今天已记录 \(todayCount) 次")
    }
}

/// Up to 6 small stickers in a 3-column grid; filled ones are today's visits.
struct TodayStickers: View {
    let count: Int
    private let slots = 6

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(18), spacing: 6), count: 3), spacing: 6) {
                ForEach(0..<slots, id: \.self) { index in
                    let filled = index < count
                    ZStack {
                        Circle()
                            .fill(Theme.onSunny.opacity(0.12))
                        if filled {
                            Sticker(color: Color(hex: 0x7A4BA0), edge: 2.5)
                                .transition(.scale(scale: 0.2).combined(with: .opacity))
                        }
                    }
                    .frame(width: 18, height: 18)
                }
            }
            .frame(width: 70)
            .animation(.spring(response: 0.4, dampingFraction: 0.5), value: count)
            Text(count > slots ? "今天 \(count) 次" : "今天")
                .font(.caption.weight(.semibold))
                .opacity(0.75)
        }
        .accessibilityHidden(true)
    }
}

/// A small burst of colored dots, once per trigger change.
struct ConfettiBurst: View {
    let trigger: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat = 1

    private let colors: [Color] = [Theme.accent, Theme.ideal, Theme.dry, Theme.loose, Theme.blush, .white]

    var body: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { index in
                let angle = Double(index) / 12 * 2 * .pi + 0.3
                let distance: CGFloat = index.isMultiple(of: 2) ? 120 : 90
                Circle()
                    .fill(colors[index % colors.count])
                    .frame(width: index.isMultiple(of: 3) ? 10 : 7)
                    .offset(x: cos(angle) * distance * progress, y: sin(angle) * distance * 0.55 * progress)
                    .scaleEffect(1 - 0.5 * progress)
                    .opacity(progress >= 1 ? 0 : 1 - progress * 0.8)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, _ in
            guard !reduceMotion else { return }
            progress = 0
            withAnimation(.easeOut(duration: 0.75)) { progress = 1 }
        }
    }
}

/// This week as seven round stickers; color warms with the day's count.
struct WeekStickers: View {
    let dates: [Date]
    private let calendar = Calendar.current

    private var days: [Date] {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: .now) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: week.start) }
    }

    var body: some View {
        let counts = PoopStats.countsByDay(dates, calendar: calendar)
        let weekTotal = days.reduce(0) { $0 + (counts[$1] ?? 0) }
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                SectionTitle("这一周")
                Spacer()
                Text("\(weekTotal) 次")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Theme.inkSoft)
            }
            HStack(spacing: 6) {
                ForEach(days, id: \.self) { day in
                    let count = counts[day] ?? 0
                    let isToday = calendar.isDateInToday(day)
                    let future = day > .now
                    VStack(spacing: 6) {
                        DaySticker(count: count, isFuture: future, isToday: isToday) {
                            if count > 0 {
                                Text("\(count)")
                                    .font(.subheadline.weight(.bold).monospacedDigit())
                                    .foregroundStyle(Theme.tileInk(for: count))
                            }
                        }
                        Text(isToday ? "今天" : DateText.weekdayShort(day))
                            .font(.caption.weight(isToday ? .bold : .medium))
                            .foregroundStyle(isToday ? Theme.accent : Theme.inkSoft)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(DateText.dayTitle(day))，\(count) 次")
                }
            }
        }
    }
}

/// A day's sticker. Empty past days are flat; future days are a dashed slot waiting for a sticker.
struct DaySticker<Label: View>: View {
    let count: Int
    let isFuture: Bool
    var isToday = false
    var isSelected = false
    @ViewBuilder var label: () -> Label

    var body: some View {
        ZStack {
            if isFuture {
                Circle()
                    .strokeBorder(Theme.line, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
            } else if count == 0 {
                Circle().fill(Theme.surfaceSunk)
            } else {
                Sticker(color: Theme.tile(for: count))
                    .rotationEffect(.degrees(Double((count * 7) % 9) - 4))
            }
            label()
        }
        .aspectRatio(1, contentMode: .fit)
        .overlay(
            Circle()
                .strokeBorder(Theme.accent, lineWidth: isSelected ? 2.5 : 2)
                .padding(-4)
                .opacity(isSelected || isToday ? 1 : 0)
        )
    }
}

/// Plain, exact numbers in one soft panel: label left, value right.
struct StatsPanel: View {
    let stats: PoopStats
    let commonType: BristolType?

    var body: some View {
        let interval = StatsFormat.interval(stats.averageIntervalDays)
        let rows: [(String, String, String)] = [
            ("平均多久一次", interval.value, interval.unit),
            ("平均每天 · 全部", StatsFormat.perDay(stats.averagePerDay), stats.averagePerDay == nil ? "" : "次"),
            ("平均每天 · 近 30 天", StatsFormat.perDay(stats.averagePerDayLast30), stats.averagePerDayLast30 == nil ? "" : "次"),
            ("近 7 天", "\(stats.last7DaysCount)", "次"),
            ("近 30 天", "\(stats.last30DaysCount)", "次"),
            ("一共记了", "\(stats.totalCount)", "次"),
        ]
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("我的小统计")
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    StatRow(label: row.0, value: row.1, unit: row.2)
                    Divider().overlay(Theme.line).padding(.leading, 16)
                }
                HStack {
                    Text("近 30 天最常见")
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    if let commonType {
                        EntryBadge(type: commonType, size: 28)
                        Text("\(commonType.rawValue) 型 · \(commonType.name)")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.ink)
                    } else {
                        Text("—").foregroundStyle(Theme.inkSoft)
                    }
                }
                .padding(.horizontal, 16)
                .frame(minHeight: 50)
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
                .font(.body.weight(.bold).monospacedDigit())
                .foregroundStyle(Theme.ink)
            if !unit.isEmpty {
                Text(unit)
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 50)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HomeView()
        .modelContainer(PreviewData.container)
}
