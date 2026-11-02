import SwiftData
import SwiftUI

struct HistoryView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case calendar = "日历"
        case list = "列表"
        var id: Self { self }
    }

    @Environment(\.modelContext) private var context
    @Query(sort: \PoopEntry.timestamp, order: .reverse) private var entries: [PoopEntry]

    @State private var mode: Mode = .calendar
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    emptyState
                } else {
                    switch mode {
                    case .calendar:
                        CalendarPage(entries: entries, onDelete: delete)
                    case .list:
                        listPage
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
                    .frame(width: 160)
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
                AddEntrySheet()
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
                        EntryRow(entry: entry)
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
            try? context.save()
        }
    }
}

struct EntryRow: View {
    let entry: PoopEntry

    var body: some View {
        HStack(spacing: 12) {
            Text("💩")
                .font(.system(size: 22))
                .frame(width: 40, height: 40)
                .background(Circle().fill(Theme.cream))
            Text(DateText.time(entry.timestamp))
                .font(.rounded(18, weight: .semibold))
                .foregroundStyle(Theme.ink)
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

struct CalendarPage: View {
    let entries: [PoopEntry]
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
                        EntryRow(entry: entry)
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
                    Text("记错了？向左滑动即可删除")
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
                        Color.clear.frame(height: 44)
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
        VStack(spacing: 0) {
            Text("\(Calendar.current.component(.day, from: day))")
                .font(.rounded(13, weight: isToday ? .heavy : .medium))
                .foregroundStyle(isFuture ? Theme.inkSoft.opacity(0.4) : Theme.ink)
            Group {
                if count == 0 {
                    Text(" ")
                } else if count == 1 {
                    Text("💩")
                } else {
                    Text("💩\(count)")
                }
            }
            .font(.system(size: 12))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, minHeight: 44)
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
