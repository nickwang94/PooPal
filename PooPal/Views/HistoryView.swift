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
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("便便记录")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("显示方式", selection: $mode) {
                        ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 210)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("补记一次")
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                EntryEditorSheet()
            }
            .sheet(item: $editing) { entry in
                EntryEditorSheet(entry: entry)
            }
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
                        EntryRow(entry: entry) { editing = entry }
                    }
                    .onDelete { offsets in
                        offsets.map { group.items[$0] }.forEach(delete)
                    }
                } header: {
                    Text("\(DateText.dayTitle(group.day)) · \(group.items.count) 次")
                        .font(.rounded(14, weight: .bold))
                        .foregroundStyle(Theme.inkSoft)
                }
                .listRowBackground(Theme.card)
            }
        }
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            PoopMascot(expression: .calm)
                .frame(width: 120, height: 120)
            Text("还没有任何记录")
                .font(.rounded(20, weight: .bold))
                .foregroundStyle(Theme.ink)
            Text("回到首页点一下大按钮，\n或者右上角补记一次吧～")
                .font(.rounded(15))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func delete(_ entry: PoopEntry) {
        withAnimation {
            context.delete(entry)
            DataActions.didChange(context)
        }
    }
}

struct EntryRow: View {
    let entry: PoopEntry
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                EntryBadge(type: entry.bristol, size: 42)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(DateText.time(entry.timestamp))
                            .font(.rounded(18, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                        if let type = entry.bristol {
                            Text("\(type.rawValue) 型 \(type.name)")
                                .font(.rounded(12, weight: .bold))
                                .foregroundStyle(Theme.ink)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(type.tint.opacity(0.6)))
                        }
                    }
                    if let note = entry.trimmedNote {
                        Text(note)
                            .font(.rounded(14))
                            .foregroundStyle(Theme.inkSoft)
                            .lineLimit(2)
                    } else if entry.bristol == nil {
                        Text("点一下补充形态和备注")
                            .font(.rounded(13))
                            .foregroundStyle(Theme.inkSoft.opacity(0.7))
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
                MonthGrid(month: $month, selectedDay: $selectedDay, counts: counts)
                    .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
            }
            .listRowBackground(Theme.card)

            Section {
                if selectedEntries.isEmpty {
                    Text("这天没有便便记录")
                        .font(.rounded(15))
                        .foregroundStyle(Theme.inkSoft)
                } else {
                    ForEach(selectedEntries) { entry in
                        EntryRow(entry: entry) { onEdit(entry) }
                            .swipeActions {
                                Button("删除", role: .destructive) { onDelete(entry) }
                            }
                    }
                }
            } header: {
                Text("\(DateText.dayTitle(selectedDay)) · \(selectedEntries.count) 次")
                    .font(.rounded(14, weight: .bold))
                    .foregroundStyle(Theme.inkSoft)
            } footer: {
                if !selectedEntries.isEmpty {
                    Text("点一条可以编辑；记错了就向左滑动删除")
                        .font(.rounded(12))
                }
            }
            .listRowBackground(Theme.card)
        }
        .scrollContentBackground(.hidden)
    }
}

struct MonthGrid: View {
    @Binding var month: Date
    @Binding var selectedDay: Date
    let counts: [Date: Int]

    private let calendar = Calendar.current
    private let weekdaySymbols = ["日", "一", "二", "三", "四", "五", "六"]

    private var days: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: month)
        let leading = Array(repeating: Date?.none, count: firstWeekday - 1)
        let monthDays: [Date?] = range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: month)
        }
        return leading + monthDays
    }

    private var canGoForward: Bool {
        month < calendar.startOfMonth(for: .now)
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Button { shiftMonth(-1) } label: { Image(systemName: "chevron.left.circle.fill") }
                    .accessibilityLabel("上个月")
                Spacer()
                Text(DateText.month(month))
                    .font(.rounded(18, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Button { shiftMonth(1) } label: { Image(systemName: "chevron.right.circle.fill") }
                    .disabled(!canGoForward)
                    .accessibilityLabel("下个月")
            }
            .font(.system(size: 24))
            .foregroundStyle(Theme.poop)
            .buttonStyle(.plain)

            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.rounded(12, weight: .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    if let day {
                        DayCell(
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
                        Color.clear.frame(height: 48)
                    }
                }
            }
        }
    }

    private func shiftMonth(_ delta: Int) {
        if let next = calendar.date(byAdding: .month, value: delta, to: month) {
            withAnimation(.snappy) { month = next }
        }
    }
}

struct DayCell: View {
    let day: Date
    let count: Int
    let isSelected: Bool
    let isToday: Bool
    let isFuture: Bool

    var body: some View {
        VStack(spacing: 1) {
            Text("\(Calendar.current.component(.day, from: day))")
                .font(.rounded(13, weight: isToday ? .heavy : .medium))
                .foregroundStyle(isFuture ? Theme.inkSoft.opacity(0.4) : Theme.ink)
            HStack(spacing: 1) {
                if count > 0 {
                    PoopMascot(expression: .happy)
                        .frame(width: 16, height: 16)
                    if count > 1 {
                        Text("×\(count)")
                            .font(.rounded(10, weight: .bold))
                            .foregroundStyle(Theme.poop)
                    }
                }
            }
            .frame(height: 16)
        }
        .frame(maxWidth: .infinity, minHeight: 48)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? Theme.peach : (count > 0 ? Theme.cream : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isToday ? Theme.poop : Color.clear, lineWidth: 1.5)
        )
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(DateText.dayTitle(day))，\(count) 次")
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
