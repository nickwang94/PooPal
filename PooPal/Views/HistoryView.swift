import SwiftData
import SwiftUI

struct HistoryView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case calendar = "日历"
        case list = "列表"
        case trends = "趋势"
        var id: Self { self }
    }

    @Environment(\.modelContext) private var context
    @Query(sort: \PoopEntry.timestamp, order: .reverse) private var entries: [PoopEntry]

    /// `-historyMode list|trends` picks the initial mode (used for screenshots).
    @State private var mode: Mode = {
        switch UserDefaults.standard.string(forKey: "historyMode") {
        case "list": .list
        case "trends": .trends
        default: .calendar
        }
    }()
    @State private var showingAddSheet = false
    @State private var editing: PoopEntry?

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    emptyState
                } else {
                    switch mode {
                    case .calendar:
                        CalendarPage(entries: entries, onEdit: { editing = $0 }, onDelete: delete)
                    case .list:
                        listPage
                    case .trends:
                        TrendsView(entries: entries)
                    }
                }
            }
            .background(Theme.ground.ignoresSafeArea())
            .navigationTitle("我的贴纸本")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !entries.isEmpty {
                    ToolbarItem(placement: .principal) {
                        Picker("显示方式", selection: $mode) {
                            ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 240)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("补一条")
                }
            }
            .sheet(isPresented: $showingAddSheet) { EntryEditorSheet() }
            .sheet(item: $editing) { EntryEditorSheet(entry: $0) }
        }
    }

    private var groupedByDay: [(day: Date, items: [PoopEntry])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.timestamp) }
        return groups.keys.sorted(by: >).map { ($0, groups[$0] ?? []) }
    }

    private var listPage: some View {
        List {
            ForEach(groupedByDay, id: \.day) { group in
                Section {
                    ForEach(group.items) { entry in
                        Button { editing = entry } label: { EntryRowContent(entry: entry) }
                            .buttonStyle(.plain)
                    }
                    .onDelete { offsets in
                        offsets.map { group.items[$0] }.forEach(delete)
                    }
                } header: {
                    Text("\(DateText.dayTitle(group.day)) · \(group.items.count) 次")
                }
                .listRowBackground(Theme.surface)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("还没有贴纸呢", systemImage: "circle.grid.3x3.fill")
        } description: {
            Text("去首页点一下「记一下」，或者点右上角补一条之前的。")
        }
        .foregroundStyle(Theme.ink)
    }

    private func delete(_ entry: PoopEntry) {
        withAnimation {
            context.delete(entry)
            DataActions.didChange(context)
        }
    }
}

/// One entry: type tile, time, type label, note.
struct EntryRowContent: View {
    let entry: PoopEntry
    /// Show "今天 08:30" instead of just the time.
    var dayStyle = false

    var body: some View {
        HStack(spacing: 14) {
            EntryBadge(type: entry.bristol, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(dayStyle ? DateText.short(entry.timestamp) : DateText.time(entry.timestamp))
                        .font(.body.weight(.semibold).monospacedDigit())
                        .foregroundStyle(Theme.ink)
                    if let type = entry.bristol {
                        Text("\(type.rawValue) 型 · \(type.name)")
                            .font(.subheadline)
                            .foregroundStyle(type.tint)
                    }
                }
                if let note = entry.trimmedNote {
                    Text(note)
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSoft)
                        .lineLimit(2)
                } else if entry.bristol == nil {
                    Text("点一下，补上形态和小备注")
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.inkSoft.opacity(0.6))
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("编辑这条记录")
    }
}

struct CalendarPage: View {
    let entries: [PoopEntry]
    let onEdit: (PoopEntry) -> Void
    let onDelete: (PoopEntry) -> Void

    @State private var month: Date = Calendar.current.startOfMonth(for: .now)
    @State private var selectedDay: Date = Calendar.current.startOfDay(for: .now)

    private let calendar = Calendar.current

    private var counts: [Date: Int] {
        PoopStats.countsByDay(entries.map(\.timestamp), calendar: calendar)
    }

    private var selectedEntries: [PoopEntry] {
        entries.filter { calendar.isDate($0.timestamp, inSameDayAs: selectedDay) }
    }

    var body: some View {
        List {
            Section {
                MonthMosaic(month: $month, selectedDay: $selectedDay, counts: counts)
                    .listRowInsets(EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14))
            }
            .listRowBackground(Theme.surface)
            .listSectionSpacing(.compact)

            Section {
                if selectedEntries.isEmpty {
                    Text("这天没有贴纸")
                        .foregroundStyle(Theme.inkSoft)
                } else {
                    ForEach(selectedEntries) { entry in
                        Button { onEdit(entry) } label: { EntryRowContent(entry: entry) }
                            .buttonStyle(.plain)
                            .swipeActions {
                                Button("删除", role: .destructive) { onDelete(entry) }
                            }
                    }
                }
            } header: {
                Text("\(DateText.dayTitle(selectedDay)) · \(selectedEntries.count) 次")
            } footer: {
                if !selectedEntries.isEmpty {
                    Text("点一条可以改，往左滑可以删。")
                }
            }
            .listRowBackground(Theme.surface)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .contentMargins(.top, 4, for: .scrollContent)
    }
}

/// The month as a mosaic of tiles; shade deepens with the day's count.
struct MonthMosaic: View {
    @Binding var month: Date
    @Binding var selectedDay: Date
    let counts: [Date: Int]

    private let calendar = Calendar.current

    private var weekdaySymbols: [String] {
        let names = ["日", "一", "二", "三", "四", "五", "六"]
        return (0..<7).map { names[(calendar.firstWeekday - 1 + $0) % 7] }
    }

    private var days: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
        let weekday = calendar.component(.weekday, from: month)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        let monthDays: [Date?] = range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: month) }
        return Array(repeating: nil, count: leading) + monthDays
    }

    private var canGoForward: Bool { month < calendar.startOfMonth(for: .now) }

    private var monthTotal: Int {
        days.compactMap { $0 }.reduce(0) { $0 + (counts[$1] ?? 0) }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(DateText.month(month))
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                    Text("共 \(monthTotal) 次")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Button { shiftMonth(-1) } label: { Image(systemName: "chevron.left") }
                    .accessibilityLabel("上个月")
                    .frame(width: 44, height: 44)
                Button { shiftMonth(1) } label: { Image(systemName: "chevron.right") }
                    .disabled(!canGoForward)
                    .accessibilityLabel("下个月")
                    .frame(width: 44, height: 44)
            }
            .font(.body.weight(.semibold))
            .buttonStyle(.borderless)

            let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.inkSoft)
                }
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    if let day {
                        DayTile(
                            day: day,
                            count: counts[day] ?? 0,
                            isSelected: calendar.isDate(day, inSameDayAs: selectedDay),
                            isToday: calendar.isDateInToday(day),
                            isFuture: day > .now
                        )
                        .onTapGesture {
                            if day <= .now { selectedDay = day }
                        }
                    } else {
                        Color.clear.aspectRatio(1, contentMode: .fit)
                    }
                }
            }
            .sensoryFeedback(.selection, trigger: selectedDay)

            HStack(spacing: 6) {
                Text("少").font(.caption2).foregroundStyle(Theme.inkSoft)
                ForEach(0..<4) { count in
                    Sticker(color: Theme.tile(for: count), edge: 1.5, lifted: false).frame(width: 14, height: 14)
                }
                Text("多").font(.caption2).foregroundStyle(Theme.inkSoft)
                Spacer()
            }
            .accessibilityHidden(true)
        }
    }

    private func shiftMonth(_ delta: Int) {
        if let next = calendar.date(byAdding: .month, value: delta, to: month) {
            withAnimation(.snappy) { month = next }
        }
    }
}

struct DayTile: View {
    let day: Date
    let count: Int
    let isSelected: Bool
    let isToday: Bool
    let isFuture: Bool

    var body: some View {
        DaySticker(count: count, isFuture: isFuture, isToday: isToday && !isSelected, isSelected: isSelected) {
            Text("\(Calendar.current.component(.day, from: day))")
                .font(.footnote.weight(isToday ? .heavy : .semibold).monospacedDigit())
                .foregroundStyle(isFuture ? Theme.inkSoft.opacity(0.6) : Theme.tileInk(for: count))
        }
        .overlay(alignment: .topTrailing) {
            if count > 1 {
                Text("\(count)")
                    .font(.caption2.weight(.heavy).monospacedDigit())
                    .foregroundStyle(Theme.onAccent)
                    .frame(minWidth: 16, minHeight: 16)
                    .background(Circle().fill(Theme.accent))
                    .offset(x: 3, y: -3)
            }
        }
        .padding(2)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(DateText.dayTitle(day))，\(count) 次")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: date)) ?? startOfDay(for: date)
    }
}

#Preview {
    HistoryView()
        .modelContainer(PreviewData.container)
}
