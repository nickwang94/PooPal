import Foundation

/// Frequency statistics derived from a list of poop timestamps.
/// Pure value type so it can be unit-tested with a fixed `now` and calendar.
struct PoopStats: Equatable {
    let totalCount: Int
    let todayCount: Int
    let last7DaysCount: Int
    let last30DaysCount: Int
    /// Calendar days between the latest entry and today (0 = today). `nil` when there are no entries.
    let daysSinceLast: Int?
    let lastDate: Date?
    /// Days from the first entry's day through today, inclusive.
    let trackedDays: Int
    /// Entries per day across the tracked span. `nil` when there are no entries.
    let averagePerDay: Double?
    /// Entries per day over the last 30 days (or fewer, if tracking started more recently).
    let averagePerDayLast30: Double?
    /// Mean gap between consecutive entries, in days. `nil` with fewer than two entries.
    let averageIntervalDays: Double?

    init(dates: [Date], now: Date = .now, calendar: Calendar = .current) {
        let sorted = dates.filter { $0 <= now }.sorted()
        let today = calendar.startOfDay(for: now)

        func countSince(daysBack: Int) -> Int {
            guard let start = calendar.date(byAdding: .day, value: -daysBack, to: today) else { return 0 }
            return sorted.reduce(0) { $0 + ($1 >= start ? 1 : 0) }
        }

        totalCount = sorted.count
        todayCount = countSince(daysBack: 0)
        last7DaysCount = countSince(daysBack: 6)
        last30DaysCount = countSince(daysBack: 29)
        lastDate = sorted.last

        if let first = sorted.first, let last = sorted.last {
            let lastDay = calendar.startOfDay(for: last)
            daysSinceLast = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            let firstDay = calendar.startOfDay(for: first)
            let span = (calendar.dateComponents([.day], from: firstDay, to: today).day ?? 0) + 1
            trackedDays = max(span, 1)
            averagePerDay = Double(sorted.count) / Double(trackedDays)
            averagePerDayLast30 = Double(last30DaysCount) / Double(min(trackedDays, 30))
        } else {
            daysSinceLast = nil
            trackedDays = 0
            averagePerDay = nil
            averagePerDayLast30 = nil
        }

        if sorted.count >= 2, let first = sorted.first, let last = sorted.last {
            let seconds = last.timeIntervalSince(first) / Double(sorted.count - 1)
            averageIntervalDays = seconds / 86_400
        } else {
            averageIntervalDays = nil
        }
    }

    /// Number of entries per calendar day, keyed by the start of that day.
    static func countsByDay(_ dates: [Date], calendar: Calendar = .current) -> [Date: Int] {
        dates.reduce(into: [:]) { result, date in
            result[calendar.startOfDay(for: date), default: 0] += 1
        }
    }

    /// Bristol type counts for entries in the last `days` calendar days (including today).
    static func bristolDistribution(
        _ entries: [(date: Date, type: Int?)],
        days: Int = 30,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [BristolType: Int] {
        guard let start = calendar.date(byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: now)) else { return [:] }
        return entries.reduce(into: [:]) { result, entry in
            guard entry.date >= start, entry.date <= now,
                  let type = entry.type.flatMap(BristolType.init(rawValue:)) else { return }
            result[type, default: 0] += 1
        }
    }

    /// Most frequent Bristol type in the window; ties go to the type closest to the ideal (4).
    static func mostCommonBristol(
        _ entries: [(date: Date, type: Int?)],
        days: Int = 30,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> BristolType? {
        bristolDistribution(entries, days: days, now: now, calendar: calendar)
            .max { a, b in
                a.value != b.value ? a.value < b.value : abs(a.key.rawValue - 4) > abs(b.key.rawValue - 4)
            }?
            .key
    }
}

/// Entry counts grouped into calendar weeks or months, for the trend chart.
struct TrendBucket: Equatable, Identifiable {
    let start: Date
    let count: Int
    var id: Date { start }
}

enum TrendPeriod: String, CaseIterable, Identifiable {
    case week = "按周"
    case month = "按月"
    var id: Self { self }

    var component: Calendar.Component {
        switch self {
        case .week: .weekOfYear
        case .month: .month
        }
    }
}

enum Trends {
    /// The last `count` periods ending with the current one, oldest first, including empty periods.
    static func buckets(
        _ dates: [Date],
        period: TrendPeriod,
        count: Int = 12,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [TrendBucket] {
        guard let current = calendar.dateInterval(of: period.component, for: now) else { return [] }
        let starts: [Date] = (0..<count).reversed().compactMap {
            calendar.date(byAdding: period.component, value: -$0, to: current.start)
        }
        var counts: [Date: Int] = [:]
        for date in dates where date <= now {
            if let interval = calendar.dateInterval(of: period.component, for: date) {
                counts[interval.start, default: 0] += 1
            }
        }
        return starts.map { TrendBucket(start: $0, count: counts[$0] ?? 0) }
    }
}

enum PoopMood: Equatable {
    case noData
    case today
    case yesterday
    case aWhile(days: Int)
    case tooLong(days: Int)

    init(daysSinceLast: Int?) {
        switch daysSinceLast {
        case nil: self = .noData
        case let d? where d <= 0: self = .today
        case 1: self = .yesterday
        case let d? where d == 2: self = .aWhile(days: d)
        case let d?: self = .tooLong(days: d)
        }
    }

    /// SF Symbol shown next to the mood title and in the widget.
    var symbol: String {
        switch self {
        case .noData: "hand.wave.fill"
        case .today: "sparkles"
        case .yesterday: "face.smiling"
        case .aWhile: "leaf.fill"
        case .tooLong: "drop.fill"
        }
    }

    var title: String {
        switch self {
        case .noData: "还没有记录哦"
        case .today: "今天顺顺利利"
        case .yesterday: "昨天来过啦"
        case .aWhile(let days), .tooLong(let days): "已经 \(days) 天没来了"
        }
    }

    var message: String {
        switch self {
        case .noData: "第一次？点下面的大贴纸就记好啦"
        case .today: "肠道小伙伴给你比个心"
        case .yesterday: "今天也记得多喝水呀"
        case .aWhile: "吃点蔬果，起来走走吧"
        case .tooLong: "多喝水、多吃点膳食纤维；一直不舒服记得看医生哦"
        }
    }
}

enum StatsFormat {
    static func perDay(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(format: "%.1f", value)
    }

    /// Human-friendly interval: hours when under a day, otherwise days with one decimal.
    static func interval(_ days: Double?) -> (value: String, unit: String) {
        guard let days else { return ("—", "") }
        let hours = (days * 24).rounded()
        if hours < 24 {
            return (String(format: "%.0f", max(hours, 1)), "小时")
        }
        return (String(format: "%.1f", days), "天")
    }

    /// Elapsed time since the last entry: "刚刚", "3 小时", "2 天".
    static func elapsed(since last: Date?, now: Date = .now) -> String? {
        guard let last else { return nil }
        let minutes = max(0, now.timeIntervalSince(last) / 60)
        if minutes < 60 { return "刚刚" }
        let hours = Int(minutes / 60)
        if hours < 48 { return "\(hours) 小时" }
        return "\(hours / 24) 天"
    }

    static func daysSince(_ days: Int?) -> (value: String, unit: String) {
        guard let days else { return ("—", "") }
        if days == 0 { return ("今天", "") }
        return ("\(days)", "天")
    }
}
