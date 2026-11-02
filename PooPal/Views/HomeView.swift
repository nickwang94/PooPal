import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \PoopEntry.timestamp, order: .reverse) private var entries: [PoopEntry]

    @State private var showingAddSheet = false
    @State private var lastLogged: PoopEntry?
    @State private var logCount = 0

    private var stats: PoopStats { PoopStats(dates: entries.map(\.timestamp)) }
    private var mood: PoopMood { PoopMood(daysSinceLast: stats.daysSinceLast) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    MoodCard(mood: mood)
                    BigPoopButton(bounceTrigger: logCount, action: logNow)
                    addPastButton
                    StatsGrid(stats: stats)
                    recentSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(Theme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .overlay(alignment: .bottom) { toast }
            .sheet(isPresented: $showingAddSheet) {
                AddEntrySheet()
                    .presentationDetents([.large])
            }
            .sensoryFeedback(.success, trigger: logCount)
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("PooPal")
                    .font(.rounded(32, weight: .heavy))
                    .foregroundStyle(Theme.poop)
                Text(DateText.header(.now))
                    .font(.rounded(15, weight: .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Text("今日 \(stats.todayCount) 次")
                .font(.rounded(14, weight: .bold))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Theme.butter))
        }
        .padding(.top, 12)
    }

    private var addPastButton: some View {
        Button {
            showingAddSheet = true
        } label: {
            Label("补记一次", systemImage: "clock.arrow.circlepath")
                .font(.rounded(16, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Capsule().fill(Theme.lavender))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var recentSection: some View {
        if !entries.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("最近的记录")
                    .font(.rounded(18, weight: .bold))
                    .foregroundStyle(Theme.ink)
                VStack(spacing: 0) {
                    ForEach(entries.prefix(3)) { entry in
                        HStack {
                            Text("💩")
                            Text(DateText.short(entry.timestamp))
                                .font(.rounded(16, weight: .medium))
                                .foregroundStyle(Theme.ink)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        if entry.id != entries.prefix(3).last?.id {
                            Divider()
                        }
                    }
                }
                .card()
                Text("在「记录」页可以查看全部，左滑删除记错的条目")
                    .font(.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var toast: some View {
        if let lastLogged {
            HStack(spacing: 12) {
                Text("记下啦！\(DateText.time(lastLogged.timestamp)) 💩")
                    .font(.rounded(16, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Button("撤销") { undo(lastLogged) }
                    .font(.rounded(16, weight: .bold))
                    .foregroundStyle(Theme.poop)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Capsule().fill(Theme.mint))
            .shadow(color: Theme.poop.opacity(0.15), radius: 10, y: 4)
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func logNow() {
        let entry = PoopEntry(timestamp: .now)
        context.insert(entry)
        try? context.save()
        logCount += 1
        withAnimation(.spring) { lastLogged = entry }
        let current = logCount
        Task {
            try? await Task.sleep(for: .seconds(4))
            if current == logCount {
                withAnimation(.easeOut) { lastLogged = nil }
            }
        }
    }

    private func undo(_ entry: PoopEntry) {
        context.delete(entry)
        try? context.save()
        withAnimation(.easeOut) { lastLogged = nil }
    }
}

struct MoodCard: View {
    let mood: PoopMood

    private var expression: PoopMascot.Expression {
        switch mood {
        case .today, .noData: .happy
        case .yesterday: .calm
        case .aWhile, .tooLong: .worried
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            PoopMascot(expression: expression)
                .frame(width: 64, height: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(mood.title) \(mood.emoji)")
                    .font(.rounded(19, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text(mood.message)
                    .font(.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .card(tint: Theme.cream)
    }
}

struct BigPoopButton: View {
    var bounceTrigger: Int
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                PoopMascot(expression: .happy)
                    .frame(width: 110, height: 110)
                    .phaseAnimator([false, true], trigger: bounceTrigger) { view, up in
                        view
                            .scaleEffect(up ? 1.15 : 1)
                            .rotationEffect(.degrees(up ? -6 : 0))
                    } animation: { _ in .spring(response: 0.25, dampingFraction: 0.5) }
                Text("我便便啦！")
                    .font(.rounded(26, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                Text("点一下记录现在")
                    .font(.rounded(13, weight: .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
            .frame(width: 240, height: 240)
            .background(
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.butter, Theme.peach],
                            center: .center,
                            startRadius: 10,
                            endRadius: 140
                        )
                    )
            )
            .overlay(Circle().stroke(Color.white, lineWidth: 6))
            .shadow(color: Theme.peach.opacity(0.8), radius: 18, y: 8)
        }
        .buttonStyle(SquishButtonStyle())
        .accessibilityLabel("记录一次便便")
        .padding(.vertical, 6)
    }
}

struct SquishButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct StatsGrid: View {
    let stats: PoopStats

    var body: some View {
        let since = StatsFormat.daysSince(stats.daysSinceLast)
        let interval = StatsFormat.interval(stats.averageIntervalDays)
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            StatTile(icon: "⏳", title: "距上次", value: since.value, unit: since.unit, tint: Theme.sky)
            StatTile(icon: "📈", title: "平均每天", value: StatsFormat.perDay(stats.averagePerDay), unit: "次", tint: Theme.mint)
            StatTile(icon: "🔁", title: "平均间隔", value: interval.value, unit: interval.unit, tint: Theme.pink)
            StatTile(icon: "🗓️", title: "近 7 天", value: "\(stats.last7DaysCount)", unit: "次", tint: Theme.butter)
            StatTile(icon: "🌙", title: "近 30 天", value: "\(stats.last30DaysCount)", unit: "次", tint: Theme.lavender)
            StatTile(icon: "💩", title: "累计记录", value: "\(stats.totalCount)", unit: "次", tint: Theme.peach)
        }
    }
}

struct StatTile: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(icon)
                Text(title)
                    .font(.rounded(14, weight: .semibold))
                    .foregroundStyle(Theme.inkSoft)
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.rounded(28, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(unit)
                    .font(.rounded(14, weight: .semibold))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(tint: tint.opacity(0.55))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HomeView()
        .modelContainer(PreviewData.container)
}
