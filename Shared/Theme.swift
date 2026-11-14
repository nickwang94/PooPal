import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Design tokens: porcelain ground, glaze-teal tiles. Every color adapts to light and dark.
enum Theme {
    // Ground and surfaces
    static let ground = dynamic(light: 0xF2F5F4, dark: 0x0A1413)
    static let surface = dynamic(light: 0xFFFFFF, dark: 0x13201E)
    static let surfaceSunk = dynamic(light: 0xE6EDEB, dark: 0x1B2B29)
    static let grout = dynamic(light: 0xD6E0DE, dark: 0x263A37)

    // Text
    static let ink = dynamic(light: 0x0E1E1C, dark: 0xE4EFED)
    static let inkSoft = dynamic(light: 0x4A5E5B, dark: 0x9BB2AE)

    // Glaze (brand + primary action + data)
    static let glaze = dynamic(light: 0x0F5F59, dark: 0x2F9A8F)
    static let glazeDeep = dynamic(light: 0x0A4642, dark: 0x1E6E66)
    static let glazeLight = dynamic(light: 0x6DB3AA, dark: 0x2A7A72)
    static let glazePale = dynamic(light: 0xC4E2DD, dark: 0x1D4743)
    static let onGlaze = Color(hex: 0xF3FBF9)

    // Primary action fill; dimmer in dark so it does not glare at night.
    static let actionTop = dynamic(light: 0x0F5F59, dark: 0x1C6B63)
    static let actionBottom = dynamic(light: 0x0A4642, dark: 0x0F4541)

    // Mosaic levels: lightness steps monotonically toward "more" in each appearance.
    static let mosaic1 = dynamic(light: 0xA8D5CE, dark: 0x1B4A45)
    static let mosaic2 = dynamic(light: 0x3E8C83, dark: 0x2A7F76)
    static let mosaic3 = dynamic(light: 0x0A4642, dark: 0x52C4B6)
    static let mosaicInk1 = dynamic(light: 0x0A4642, dark: 0xCDEBE6)
    static let mosaicInk3 = dynamic(light: 0xF3FBF9, dark: 0x062220)

    // States (Bristol dry / loose)
    static let amber = dynamic(light: 0xC27A1E, dark: 0xE9A956)
    static let amberPale = dynamic(light: 0xF6E2C4, dark: 0x3F2E16)
    static let coral = dynamic(light: 0xC2513D, dark: 0xEE8A75)
    static let coralPale = dynamic(light: 0xF6D6CF, dark: 0x45231D)

    static let radius: CGFloat = 20
    static let tileRadius: CGFloat = 8

    /// Mosaic shade for a day with `count` entries.
    static func tile(for count: Int) -> Color {
        switch count {
        case 0: surfaceSunk
        case 1: mosaic1
        case 2: mosaic2
        default: mosaic3
        }
    }

    /// Numeral color that stays legible on `tile(for:)`.
    static func tileInk(for count: Int) -> Color {
        switch count {
        case 0: inkSoft
        case 1: mosaicInk1
        case 2: onGlaze
        default: mosaicInk3
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

/// Grouped container: one surface with hairline separators between rows (not a card per item).
struct PanelStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                    .strokeBorder(Theme.grout.opacity(0.6), lineWidth: 0.5)
            )
    }
}

extension View {
    func panel() -> some View { modifier(PanelStyle()) }
}

/// A glazed tile: rounded square with a soft top highlight.
struct GlazeTile: View {
    var color: Color = Theme.glaze
    var radius: CGFloat = Theme.tileRadius

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(color)
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(LinearGradient(colors: [.white.opacity(0.22), .clear], startPoint: .top, endPoint: .center))
                    .padding(1)
            )
            .shadow(color: .black.opacity(0.10), radius: 1.5, x: 0, y: 1)
    }
}
