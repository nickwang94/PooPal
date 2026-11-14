import Foundation
import SwiftData
import WidgetKit

extension PoopEntry {
    var backupEntry: BackupEntry {
        BackupEntry(timestamp: timestamp, bristolType: bristolType, note: trimmedNote)
    }
}

@MainActor
enum DataActions {
    /// Saves pending changes, then refreshes the widget and re-plans reminders from the latest entry.
    static func didChange(_ context: ModelContext, requestNotificationPermission: Bool = false) {
        try? context.save()
        guard !PooPalApp.usesInMemoryStore else { return }
        WidgetCenter.shared.reloadAllTimelines()
        let latest = latestEntryDate(context)
        Task {
            await ReminderScheduler.reschedule(lastEntry: latest, requestPermission: requestNotificationPermission)
        }
    }

    static func latestEntryDate(_ context: ModelContext) -> Date? {
        var descriptor = FetchDescriptor<PoopEntry>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first?.timestamp
    }

    static func exportBackup(_ context: ModelContext, password: String?) throws -> URL {
        let entries = try context.fetch(FetchDescriptor<PoopEntry>(sortBy: [SortDescriptor(\.timestamp)]))
        let encrypted = !(password ?? "").isEmpty
        let data = try BackupCodec.encode(entries.map(\.backupEntry), password: encrypted ? password : nil)
        let url = FileManager.default.temporaryDirectory.appending(path: BackupCodec.fileName(encrypted: encrypted))
        try data.write(to: url, options: [.atomic, .completeFileProtection])
        return url
    }

    static func importBackup(_ file: BackupFile, into context: ModelContext) throws -> MergePlan {
        let existing = try context.fetch(FetchDescriptor<PoopEntry>())
        let plan = MergePlan.make(existing: existing.map(\.backupEntry), incoming: file.entries)
        for entry in plan.inserts {
            context.insert(PoopEntry(
                timestamp: entry.timestamp,
                bristolType: entry.bristolType.flatMap { BristolType(rawValue: $0)?.rawValue },
                note: entry.note
            ))
        }
        for fill in plan.fills {
            let target = existing[fill.existingIndex]
            if let type = fill.bristolType { target.bristolType = type }
            if let note = fill.note { target.note = note }
        }
        didChange(context)
        return plan
    }
}
