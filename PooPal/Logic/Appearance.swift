import SwiftUI

/// In-app appearance override. Stored as a raw string in `UserDefaults.standard`.
enum Appearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    static let storageKey = "appearance"

    var id: Self { self }

    var title: String {
        switch self {
        case .system: "跟随系统"
        case .light: "浅色"
        case .dark: "深色"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
