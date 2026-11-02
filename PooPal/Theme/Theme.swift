import SwiftUI

enum Theme {
    static let background = Color(red: 1.00, green: 0.97, blue: 0.93)
    static let card = Color.white
    static let cream = Color(red: 1.00, green: 0.93, blue: 0.84)
    static let peach = Color(red: 1.00, green: 0.80, blue: 0.70)
    static let pink = Color(red: 1.00, green: 0.72, blue: 0.77)
    static let mint = Color(red: 0.72, green: 0.91, blue: 0.82)
    static let sky = Color(red: 0.74, green: 0.86, blue: 0.98)
    static let lavender = Color(red: 0.85, green: 0.80, blue: 0.97)
    static let butter = Color(red: 1.00, green: 0.91, blue: 0.62)

    static let poop = Color(red: 0.62, green: 0.42, blue: 0.29)
    static let poopLight = Color(red: 0.76, green: 0.56, blue: 0.40)
    static let ink = Color(red: 0.33, green: 0.24, blue: 0.20)
    static let inkSoft = Color(red: 0.55, green: 0.46, blue: 0.41)

    static let cornerRadius: CGFloat = 24
}

struct CardStyle: ViewModifier {
    var tint: Color = Theme.card

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .fill(tint)
            )
            .shadow(color: Theme.poop.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

extension View {
    func card(tint: Color = Theme.card) -> some View {
        modifier(CardStyle(tint: tint))
    }
}

extension Font {
    static func rounded(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
