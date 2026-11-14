import XCTest
@testable import PooPal

final class BackupTests: XCTestCase {
    private let base = Date(timeIntervalSince1970: 1_793_000_000.250)

    private func entry(_ offsetHours: Double, type: Int? = nil, note: String? = nil) -> BackupEntry {
        BackupEntry(timestamp: base.addingTimeInterval(offsetHours * 3600), bristolType: type, note: note)
    }

    func testPlainRoundTripKeepsMillisecondsAndFields() throws {
        let entries = [entry(0, type: 4, note: "火锅"), entry(-20)]
        let data = try BackupCodec.encode(entries, exportedAt: base)
        XCTAssertFalse(BackupCodec.isEncrypted(data))
        let file = try BackupCodec.decode(data)
        XCTAssertEqual(file.app, "PooPal")
        XCTAssertEqual(file.entries.count, 2)
        // Sorted oldest first.
        XCTAssertEqual(file.entries[0].timestamp.timeIntervalSince1970, entries[1].timestamp.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(file.entries[1].bristolType, 4)
        XCTAssertEqual(file.entries[1].note, "火锅")
        XCTAssertEqual(EntryKey.of(file.entries[1].timestamp), EntryKey.of(entries[0].timestamp))
    }

    func testEncryptedRoundTrip() throws {
        let data = try BackupCodec.encode([entry(0, type: 3)], password: "便便1234", iterations: 1_000)
        XCTAssertTrue(BackupCodec.isEncrypted(data))
        XCTAssertNil(String(data: data, encoding: .utf8)?.range(of: "bristolType"), "payload must not be readable")
        let file = try BackupCodec.decode(data, password: "便便1234")
        XCTAssertEqual(file.entries.first?.bristolType, 3)
    }

    func testEncryptedWithDefaultIterations() throws {
        let data = try BackupCodec.encode([entry(0)], password: "secret")
        XCTAssertEqual(try BackupCodec.decode(data, password: "secret").entries.count, 1)
    }

    func testEncryptedRequiresCorrectPassword() throws {
        let data = try BackupCodec.encode([entry(0)], password: "right", iterations: 1_000)
        XCTAssertThrowsError(try BackupCodec.decode(data)) { XCTAssertEqual($0 as? BackupError, .passwordRequired) }
        XCTAssertThrowsError(try BackupCodec.decode(data, password: "wrong")) { XCTAssertEqual($0 as? BackupError, .wrongPassword) }
    }

    func testRejectsForeignJSON() {
        let data = Data(#"{"hello":"world"}"#.utf8)
        XCTAssertThrowsError(try BackupCodec.decode(data)) { XCTAssertEqual($0 as? BackupError, .invalidFile) }
        let other = Data(#"{"app":"Other","version":1,"exportedAt":"2026-11-14T10:00:00Z","entries":[]}"#.utf8)
        XCTAssertThrowsError(try BackupCodec.decode(other)) { XCTAssertEqual($0 as? BackupError, .invalidFile) }
    }

    func testAcceptsTimestampsWithoutFractionalSeconds() throws {
        let json = #"{"app":"PooPal","version":1,"exportedAt":"2026-11-14T10:00:00Z","entries":[{"timestamp":"2026-11-14T08:30:00+08:00"}]}"#
        let file = try BackupCodec.decode(Data(json.utf8))
        XCTAssertEqual(file.entries.count, 1)
        XCTAssertNil(file.entries[0].bristolType)
    }

    func testRejectsNewerVersion() {
        let json = #"{"app":"PooPal","version":9,"exportedAt":"2026-11-14T10:00:00Z","entries":[]}"#
        XCTAssertThrowsError(try BackupCodec.decode(Data(json.utf8))) { XCTAssertEqual($0 as? BackupError, .unsupportedVersion(9)) }
    }

    func testMergeSkipsDuplicatesAndInsertsNew() {
        let existing = [entry(0), entry(-24)]
        let incoming = [entry(0), entry(-24), entry(-48), entry(-48)]
        let plan = MergePlan.make(existing: existing, incoming: incoming)
        XCTAssertEqual(plan.inserts, [entry(-48)])
        XCTAssertEqual(plan.duplicates, 3)
        XCTAssertTrue(plan.fills.isEmpty)
    }

    func testMergeMatchesWithinSameSecond() {
        let existing = [BackupEntry(timestamp: Date(timeIntervalSince1970: 1000.1))]
        let incoming = [BackupEntry(timestamp: Date(timeIntervalSince1970: 1000.9))]
        XCTAssertEqual(MergePlan.make(existing: existing, incoming: incoming).duplicates, 1)
    }

    func testMergeFillsMissingDetailsButNeverOverwrites() {
        let existing = [entry(0), entry(-24, type: 5, note: "原备注")]
        let incoming = [entry(0, type: 4, note: "新备注"), entry(-24, type: 1, note: "别覆盖")]
        let plan = MergePlan.make(existing: existing, incoming: incoming)
        XCTAssertEqual(plan.fills, [MergePlan.Fill(existingIndex: 0, bristolType: 4, note: "新备注")])
        XCTAssertEqual(plan.duplicates, 1)
        XCTAssertTrue(plan.inserts.isEmpty)
    }

    func testMergeIgnoresInvalidBristolWhenFilling() {
        let plan = MergePlan.make(existing: [entry(0)], incoming: [entry(0, type: 9)])
        XCTAssertTrue(plan.fills.isEmpty)
        XCTAssertEqual(plan.duplicates, 1)
    }

    func testMergeSummary() {
        var plan = MergePlan()
        plan.inserts = [entry(0)]
        plan.duplicates = 2
        XCTAssertEqual(plan.summary, "新增 1 条，跳过 2 条重复")
    }

    func testFileName() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let date = calendar.date(from: DateComponents(year: 2026, month: 11, day: 14, hour: 9, minute: 5))!
        XCTAssertEqual(BackupCodec.fileName(for: date, encrypted: false), "PooPal-备份-20261114-0905.json")
        XCTAssertEqual(BackupCodec.fileName(for: date, encrypted: true), "PooPal-备份-20261114-0905-加密.json")
    }
}
