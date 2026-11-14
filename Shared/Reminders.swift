import Foundation
import UserNotifications

/// User-configurable reminder settings, stored in the App Group defaults so the widget can read them.
enum ReminderSettings {
    static let inactivityEnabledKey = "reminder.inactivity.enabled"
    static let inactivityDaysKey = "reminder.inactivity.days"
    static let dailyEnabledKey = "reminder.daily.enabled"
    static let dailyMinutesKey = "reminder.daily.minutes"

    static let defaultInactivityDays = 3
    static let defaultDailyMinutes = 21 * 60
    /// Hour of day when the "N days without a record" reminder fires.
    static let inactivityHour = 10

    static func registerDefaults(in defaults: UserDefaults = SharedStore.defaults) {
        defaults.register(defaults: [
            inactivityEnabledKey: true,
            inactivityDaysKey: defaultInactivityDays,
            dailyEnabledKey: false,
            dailyMinutesKey: defaultDailyMinutes,
        ])
    }
}

enum ReminderPlanner {
    /// When to send the "no record for `days` days" reminder: on the `days`-th calendar day after the last
    /// entry at `hour`. If that moment has already passed, the next `hour` after `now` instead.
    static func inactivityFireDate(
        lastEntry: Date?,
        days: Int,
        hour: Int = ReminderSettings.inactivityHour,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Date? {
        guard let lastEntry, days > 0,
              let day = calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: lastEntry)),
              let target = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) else { return nil }
        if target > now { return target }
        guard let todayAtHour = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: now) else { return nil }
        return todayAtHour > now ? todayAtHour : calendar.date(byAdding: .day, value: 1, to: todayAtHour)
    }

    static func inactivityMessage(lastEntry: Date, fireDate: Date, calendar: Calendar = .current) -> (title: String, body: String) {
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastEntry), to: calendar.startOfDay(for: fireDate)).day ?? 0
        return ("已经 \(days) 天没有便便记录啦", "多喝水、吃点蔬菜水果，便便了记得来 PooPal 记一笔哦")
    }

    static func dailyComponents(minutes: Int) -> DateComponents {
        let clamped = min(max(minutes, 0), 24 * 60 - 1)
        return DateComponents(hour: clamped / 60, minute: clamped % 60)
    }
}

enum ReminderScheduler {
    static let inactivityID = "poopal.reminder.inactivity"
    static let dailyID = "poopal.reminder.daily"

    /// Re-plans both reminders from the current settings. Asks for permission only when `requestPermission`
    /// is true (from an explicit user action); otherwise silently does nothing without permission.
    static func reschedule(lastEntry: Date?, requestPermission: Bool = false) async {
        ReminderSettings.registerDefaults()
        let defaults = SharedStore.defaults
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [inactivityID, dailyID])

        let inactivityOn = defaults.bool(forKey: ReminderSettings.inactivityEnabledKey)
        let dailyOn = defaults.bool(forKey: ReminderSettings.dailyEnabledKey)
        guard inactivityOn || dailyOn else { return }
        guard await isAuthorized(center: center, request: requestPermission) else { return }

        if inactivityOn,
           let lastEntry,
           let fireDate = ReminderPlanner.inactivityFireDate(
               lastEntry: lastEntry,
               days: defaults.integer(forKey: ReminderSettings.inactivityDaysKey)
           ) {
            let message = ReminderPlanner.inactivityMessage(lastEntry: lastEntry, fireDate: fireDate)
            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            try? await center.add(request(
                id: inactivityID, title: message.title, body: message.body,
                trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            ))
        }

        if dailyOn {
            let comps = ReminderPlanner.dailyComponents(minutes: defaults.integer(forKey: ReminderSettings.dailyMinutesKey))
            try? await center.add(request(
                id: dailyID, title: "今天便便了吗？", body: "来 PooPal 点一下，记录今天的肠道小日记吧",
                trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            ))
        }
    }

    static func isAuthorized(center: UNUserNotificationCenter = .current(), request: Bool) async -> Bool {
        let status = await center.notificationSettings().authorizationStatus
        switch status {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined where request:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        default:
            return false
        }
    }

    private static func request(id: String, title: String, body: String, trigger: UNNotificationTrigger) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        return UNNotificationRequest(identifier: id, content: content, trigger: trigger)
    }
}
