import Foundation

enum DateText {
    static let locale = Locale(identifier: "zh_Hans_CN")

    private static func formatter(_ template: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = locale
        f.setLocalizedDateFormatFromTemplate(template)
        return f
    }

    private static let monthDayWeekday = formatter("MMMdEEEE")
    private static let monthDay = formatter("MMMd")
    private static let yearMonth = formatter("yyyyMMMM")
    private static let time = formatter("HH:mm")

    /// e.g. "11月2日 星期一"
    static func header(_ date: Date) -> String { monthDayWeekday.string(from: date) }

    static func time(_ date: Date) -> String { time.string(from: date) }

    static func month(_ date: Date) -> String { yearMonth.string(from: date) }

    /// "今天" / "昨天" / "11月2日 星期一"
    static func dayTitle(_ date: Date, calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(date) { return "今天" }
        if calendar.isDateInYesterday(date) { return "昨天" }
        return header(date)
    }

    /// "今天 08:30" / "昨天 21:10" / "11月2日 08:30"
    static func short(_ date: Date, calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(date) { return "今天 \(time(date))" }
        if calendar.isDateInYesterday(date) { return "昨天 \(time(date))" }
        return "\(monthDay.string(from: date)) \(time(date))"
    }
}
