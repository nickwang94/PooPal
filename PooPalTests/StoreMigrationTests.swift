import SwiftData
import XCTest
@testable import PooPal

@MainActor
final class StoreMigrationTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appending(path: "poopal-migration-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testImportsLegacyEntriesWithoutDuplicates() throws {
        let legacyURL = directory.appending(path: "default.store")
        let shared = Date(timeIntervalSince1970: 1_793_000_000)
        do {
            let legacy = try ModelContainer(for: PoopEntry.self, configurations: ModelConfiguration(url: legacyURL, cloudKitDatabase: .none))
            let context = ModelContext(legacy)
            context.insert(PoopEntry(timestamp: shared))
            context.insert(PoopEntry(timestamp: shared.addingTimeInterval(-86_400), bristolType: 4, note: "旧备注"))
            try context.save()
        }

        let destination = SharedStore.inMemoryContainer()
        let destinationContext = ModelContext(destination)
        destinationContext.insert(PoopEntry(timestamp: shared.addingTimeInterval(0.4)))
        try destinationContext.save()

        XCTAssertEqual(try SharedStore.importEntries(fromStoreAt: legacyURL, into: destination), 1)
        // Running again must not duplicate anything.
        XCTAssertEqual(try SharedStore.importEntries(fromStoreAt: legacyURL, into: destination), 0)

        let all = try ModelContext(destination).fetch(FetchDescriptor<PoopEntry>(sortBy: [SortDescriptor(\.timestamp)]))
        XCTAssertEqual(all.count, 2)
        XCTAssertEqual(all.first?.bristolType, 4)
        XCTAssertEqual(all.first?.note, "旧备注")
        XCTAssertTrue(FileManager.default.fileExists(atPath: legacyURL.path), "legacy store must be kept")
    }

    func testMissingLegacyStoreImportsNothing() throws {
        let missing = directory.appending(path: "nope.store")
        XCTAssertEqual(try SharedStore.importEntries(fromStoreAt: missing, into: SharedStore.inMemoryContainer()), 0)
    }

    func testImportBackupIntoStoreMergesAndFills() throws {
        let container = SharedStore.inMemoryContainer()
        let context = container.mainContext
        let base = Date(timeIntervalSince1970: 1_793_000_000)
        context.insert(PoopEntry(timestamp: base))
        try context.save()

        let file = BackupFile(exportedAt: base, entries: [
            BackupEntry(timestamp: base, bristolType: 4, note: "补充"),
            BackupEntry(timestamp: base.addingTimeInterval(-3600), bristolType: 8, note: nil),
        ])
        let plan = try DataActions.importBackup(file, into: context)
        XCTAssertEqual(plan.inserts.count, 1)
        XCTAssertEqual(plan.fills.count, 1)

        let all = try context.fetch(FetchDescriptor<PoopEntry>(sortBy: [SortDescriptor(\.timestamp)]))
        XCTAssertEqual(all.count, 2)
        XCTAssertNil(all[0].bristolType, "invalid Bristol type 8 must be dropped")
        XCTAssertEqual(all[1].bristolType, 4)
        XCTAssertEqual(all[1].note, "补充")
    }
}
