import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Design tokens: a sticker habit journal. Warm-milk ground, sunny marigold brand field,
/// plum ink and tint. Every color adapts to light and dark.
enum Theme {
    // Ground and surfaces
    static let ground = dynamic(light: 0xFFF8F0, dark: 0x1C1620)
    static let surface = dynamic(light: 0xFFFFFF, dark: 0x2A2230)
    static let surfaceSunk = dynamic(light: 0xF6ECE1, dark: 0x352B3B)
    static let line = dynamic(light: 0xEDE1D5, dark: 0x41364A)

    // Text
    static let ink = dynamic(light: 0x3A2A3E, dark: 0xF7EEE6)
    static let inkSoft = dynamic(light: 0x7A6A7E, dark: 0xB9A9BD)

    // Plum: interactive tint
    static let accent = dynamic(light: 0x7A4BA0, dark: 0xC59BEA)
    static let accentSoft = dynamic(light: 0xD6C3E8, dark: 0x5A4470)
    static let accentPale = dynamic(light: 0xF1E8F8, dark: 0x3A2E48)
    static let onAccent = dynamic(light: 0xFFFFFF, dark: 0x241A2B)

    // Sunny marigold: brand field and the log sticker
    static let sunny = dynamic(light: 0xFFC83D, dark: 0xF5B83A)
    static let sunnyDeep = dynamic(light: 0xF6AE22, dark: 0xD99A22)
    static let sunnyPale = dynamic(light: 0xFFEDC0, dark: 0x4A3A22)
    static let onSunny = Color(hex: 0x3A2440)

    // Bristol states and alerts
    static let dry = dynamic(light: 0xD9711F, dark: 0xF5A25A)
    static let ideal = dynamic(light: 0x3B8D5A, dark: 0x7CCB95)
    static let loose = dynamic(light: 0x3A7FC6, dark: 0x86BDF2)
    // Sticker fills stay light in both appearances, with fixed deep glyph inks on them.
    static let dryPale = dynamic(light: 0xFDE6D0, dark: 0xF2D6BC)
    static let idealPale = dynamic(light: 0xDDF1E2, dark: 0xCBE6D3)
    static let loosePale = dynamic(light: 0xDCEAF9, dark: 0xCCDDF1)
    static let dryInk = Color(hex: 0xC2631A)
    static let idealInk = Color(hex: 0x2F7A4B)
    static let looseInk = Color(hex: 0x2F6DB0)
    static let alert = dynamic(light: 0xD23F5C, dark: 0xFF8098)
    static let blush = Color(hex: 0xFF8FA3)

    /// The white die-cut edge around a sticker.
    static let stickerEdge = dynamic(light: 0xFFFFFF, dark: 0xEDE3EA)

    static let radius: CGFloat = 24
    static let tileRadius: CGFloat = 12

    // Day stickers stay bright in both appearances (real stickers do); saturation and warmth
    // step up toward "more": pale butter, marigold, tangerine. Never darkened into brown.
    static let day1 = dynamic(light: 0xFFE7A6, dark: 0xEBD7A2)
    static let day2 = dynamic(light: 0xFFC83D, dark: 0xF2B53A)
    static let day3 = dynamic(light: 0xF29A2E, dark: 0xEE8F2A)
    static let dayInk = Color(hex: 0x3A2440)

    /// Sticker color for a day with `count` entries.
    static func tile(for count: Int) -> Color {
        switch count {
        case 0: surfaceSunk
        case 1: day1
        case 2: day2
        default: day3
        }
    }

    /// Numeral color that stays legible on `tile(for:)`.
    static func tileInk(for count: Int) -> Color {
        switch count {
        case 0: inkSoft
        default: dayInk
        }
    }

    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        #if canImport(UIKit)
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
        #else
        Color(hex: light)
        #endif
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

#if canImport(UIKit)
extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
#endif

/// Soft grouped container: one rounded surface, rows separated by inset hairlines.
struct PanelStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                    .fill(Theme.surface)
                    .shadow(color: Color(hex: 0x5A3A2A).opacity(colorScheme == .dark ? 0 : 0.07), radius: 14, x: 0, y: 6)
            )
    }
}

extension View {
    func panel() -> some View { modifier(PanelStyle()) }
}

/// A die-cut sticker: colored shape with a white edge and a soft lift shadow.
/// `radius == nil` makes it round.
struct Sticker: View {
    var color: Color = Theme.sunny
    var radius: CGFloat? = nil
    var edge: CGFloat = 2.5
    var lifted = true

    var body: some View {
        Group {
            if let radius {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(color)
                    .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(Theme.stickerEdge, lineWidth: edge))
            } else {
                Circle()
                    .fill(color)
                    .overlay(Circle().strokeBorder(Theme.stickerEdge, lineWidth: edge))
            }
        }
        .shadow(color: .black.opacity(lifted ? 0.12 : 0), radius: 2.5, x: 0, y: 1.5)
    }
}
