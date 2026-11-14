import AppIntents
import SwiftData
import WidgetKit

/// One-tap logging from the home-screen widget. Runs in the widget extension process.
struct LogPoopIntent: AppIntent {
    static var title: LocalizedStringResource = "记录一次便便"
    static var description = IntentDescription("在桌面小组件上一键记录现在便便了一次。")

    func perform() async throws -> some IntentResult {
        let context = ModelContext(SharedStore.container)
        let now = Date.now
        context.insert(PoopEntry(timestamp: now))
        try context.save()
        SharedStore.markExternalChange()
        await ReminderScheduler.reschedule(lastEntry: now)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
