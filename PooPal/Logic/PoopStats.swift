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
        } else {
            daysSinceLast = nil
            trackedDays = 0
            averagePerDay = nil
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

    /// SF Symbol shown next to the mood title.
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
        case .today: "今天已经顺畅啦！"
        case .yesterday: "昨天便便过啦"
        case .aWhile(let days), .tooLong(let days): "已经 \(days) 天没便便了"
        }
    }

    var message: String {
        switch self {
        case .noData: "今天便便了吗？点一下大按钮记录吧～"
        case .today: "肠道小伙伴给你点个赞"
        case .yesterday: "今天也要多喝水哦"
        case .aWhile: "吃点蔬菜水果，起来走一走吧"
        case .tooLong: "多喝水、多吃膳食纤维；一直不舒服记得看医生哦"
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
        if days < 1 {
            return (String(format: "%.0f", max(days * 24, 1)), "小时")
        }
        return (String(format: "%.1f", days), "天")
    }

    static func daysSince(_ days: Int?) -> (value: String, unit: String) {
        guard let days else { return ("—", "") }
        if days == 0 { return ("今天", "") }
        return ("\(days)", "天")
    }
}
