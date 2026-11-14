import SwiftUI

/// A small round pastel badge holding either an SF Symbol or the mini mascot.
struct IconBadge: View {
    enum Icon {
        case symbol(String)
        case mascot
    }

    let icon: Icon
    var tint: Color = Theme.cream
    var size: CGFloat = 28

    var body: some View {
        ZStack {
            Circle().fill(tint)
            switch icon {
            case .symbol(let name):
                Image(systemName: name)
                    .font(.system(size: size * 0.48, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.poop)
            case .mascot:
                PoopMascot(expression: .happy)
                    .frame(width: size * 0.72, height: size * 0.72)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

#Preview {
    HStack {
        IconBadge(icon: .symbol("hourglass"))
        IconBadge(icon: .mascot, size: 40)
    }
    .padding()
    .background(Theme.peach)
}
