import Foundation
import SwiftData

/// Location of the SwiftData store shared by the app and the widget extension (via the App Group).
enum SharedStore {
    static let appGroupID = "group.com.nickwang.PooPal"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    /// v1 builds used SwiftData's default location inside the app's own container.
    static var legacyStoreURL: URL {
        URL.applicationSupportDirectory.appending(path: "default.store")
    }

    static var storeURL: URL {
        guard let group = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return legacyStoreURL
        }
        return group.appending(path: "Library/Application Support/PooPal.store")
    }

    /// The on-disk container used by both processes. Created once per process.
    static let container: ModelContainer = {
        do {
            try FileManager.default.createDirectory(
                at: storeURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            return try ModelContainer(
                for: PoopEntry.self,
                configurations: ModelConfiguration(url: storeURL, cloudKitDatabase: .none)
            )
        } catch {
            fatalError("无法打开数据存储：\(error)")
        }
    }()

    static func inMemoryContainer() -> ModelContainer {
        do {
            return try ModelContainer(
                for: PoopEntry.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
            )
        } catch {
            fatalError("无法创建内存数据存储：\(error)")
        }
    }

    // MARK: v1 → v2 migration

    private static let legacyImportedKey = "store.legacyImported"

    /// Copies entries from the v1 store into the shared store once. Runs record by record (deduplicated by
    /// timestamp) so it is safe even if the widget already created the shared store. The legacy file is
    /// never deleted; on failure the flag stays unset and the import is retried on the next launch.
    static func importLegacyStoreIfNeeded(into container: ModelContainer) {
        guard !defaults.bool(forKey: legacyImportedKey) else { return }
        do {
            try importEntries(fromStoreAt: legacyStoreURL, into: container)
            defaults.set(true, forKey: legacyImportedKey)
        } catch {
            print("PooPal: legacy import failed, will retry: \(error)")
        }
    }

    /// Returns the number of entries inserted.
    @discardableResult
    static func importEntries(fromStoreAt url: URL, into container: ModelContainer) throws -> Int {
        guard url.standardizedFileURL != storeURL.standardizedFileURL,
              FileManager.default.fileExists(atPath: url.path) else { return 0 }
        let legacy = try ModelContainer(
            for: PoopEntry.self,
            configurations: ModelConfiguration(url: url, cloudKitDatabase: .none)
        )
        let oldEntries = try ModelContext(legacy).fetch(FetchDescriptor<PoopEntry>())
        let context = ModelContext(container)
        var known = Set(try context.fetch(FetchDescriptor<PoopEntry>()).map { EntryKey.of($0.timestamp) })
        var inserted = 0
        for old in oldEntries where known.insert(EntryKey.of(old.timestamp)).inserted {
            let copy = PoopEntry(timestamp: old.timestamp, bristolType: old.bristolType, note: old.note)
            copy.createdAt = old.createdAt
            context.insert(copy)
            inserted += 1
        }
        try context.save()
        return inserted
    }

    // MARK: Cross-process change signal

    private static let externalChangeKey = "store.lastExternalChange"

    /// Called by the widget after it writes, so the app knows to refetch when it comes to the foreground.
    static func markExternalChange() {
        defaults.set(Date.now.timeIntervalSince1970, forKey: externalChangeKey)
    }

    static var lastExternalChange: Double {
        defaults.double(forKey: externalChangeKey)
    }
}

/// Identity used to detect duplicate entries (same second), e.g. when merging backups.
enum EntryKey {
    static func of(_ date: Date) -> Int64 {
        Int64(date.timeIntervalSince1970.rounded(.down))
    }
}
