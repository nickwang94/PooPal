import Foundation
import SwiftData

@Model
final class PoopEntry {
    var timestamp: Date
    var createdAt: Date

    init(timestamp: Date = .now) {
        self.timestamp = timestamp
        self.createdAt = .now
    }
}
