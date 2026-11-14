import Foundation
import SwiftData

@Model
final class PoopEntry {
    var timestamp: Date
    var createdAt: Date
    /// Bristol stool scale type 1–7; `nil` when not recorded. Added in v2, optional so old stores migrate.
    var bristolType: Int?
    /// Free-text note; added in v2.
    var note: String?

    init(timestamp: Date = .now, bristolType: Int? = nil, note: String? = nil) {
        self.timestamp = timestamp
        self.createdAt = .now
        self.bristolType = bristolType
        self.note = note
    }

    var bristol: BristolType? {
        bristolType.flatMap(BristolType.init(rawValue:))
    }

    /// e.g. "4 型 光滑条 · 昨晚吃了火锅"; `nil` when neither type nor note is set.
    var summaryLine: String? {
        let parts = [bristol.map { "\($0.rawValue) 型 \($0.name)" }, trimmedNote].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    var trimmedNote: String? {
        guard let text = note?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return nil }
        return text
    }
}
