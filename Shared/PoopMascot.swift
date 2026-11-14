import SwiftUI

/// The cute poop character, drawn entirely with shapes so it scales crisply.
struct PoopMascot: View {
    enum Expression {
        case happy, calm, worried
    }

    var expression: Expression = .happy

    var body: some View {
        GeometryReader { geo in
            let w = min(geo.size.width, geo.size.height)
            ZStack {
                PoopTip()
                    .fill(Theme.poop)
                    .frame(width: w * 0.24, height: w * 0.22)
                    .offset(x: w * 0.03, y: -w * 0.36)

                layer(width: 0.50, height: 0.27, y: -0.22, w: w)
                layer(width: 0.74, height: 0.31, y: 0.01, w: w)
                layer(width: 0.96, height: 0.36, y: 0.27, w: w, highlight: false)

                face(w: w)
                    .offset(y: w * 0.24)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }

    private func layer(width: CGFloat, height: CGFloat, y: CGFloat, w: CGFloat, highlight: Bool = true) -> some View {
        ZStack(alignment: .topLeading) {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Theme.poopLight, Theme.poop],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            if highlight {
                Capsule()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: w * width * 0.28, height: w * height * 0.18)
                    .offset(x: w * width * 0.16, y: w * height * 0.16)
            }
        }
        .frame(width: w * width, height: w * height)
        .offset(y: w * y)
    }

    private func face(w: CGFloat) -> some View {
        ZStack {
            HStack(spacing: w * 0.24) {
                eye(w: w)
                eye(w: w)
            }
            .offset(y: -w * 0.03)

            HStack(spacing: w * 0.40) {
                blush(w: w)
                blush(w: w)
            }
            .offset(y: w * 0.06)

            mouth(w: w)
                .offset(y: w * 0.06)
        }
    }

    private func eye(w: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Ellipse()
                .fill(Theme.ink)
                .frame(width: w * 0.10, height: expression == .calm ? w * 0.05 : w * 0.12)
            if expression != .calm {
                Circle()
                    .fill(Color.white)
                    .frame(width: w * 0.04, height: w * 0.04)
                    .offset(x: w * 0.015, y: w * 0.018)
            }
        }
    }

    private func blush(w: CGFloat) -> some View {
        Ellipse()
            .fill(Theme.pink.opacity(0.85))
            .frame(width: w * 0.12, height: w * 0.065)
    }

    @ViewBuilder
    private func mouth(w: CGFloat) -> some View {
        switch expression {
        case .happy:
            SmileShape(depth: 1)
                .fill(Theme.ink)
                .frame(width: w * 0.14, height: w * 0.08)
        case .calm:
            SmileShape(depth: 0.5)
                .stroke(Theme.ink, style: StrokeStyle(lineWidth: w * 0.022, lineCap: .round))
                .frame(width: w * 0.10, height: w * 0.04)
        case .worried:
            SmileShape(depth: -0.6)
                .stroke(Theme.ink, style: StrokeStyle(lineWidth: w * 0.022, lineCap: .round))
                .frame(width: w * 0.10, height: w * 0.04)
        }
    }
}

/// The little curl on top of the poop.
struct PoopTip: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX * 0.85, y: rect.minY),
            control: CGPoint(x: rect.minX + rect.width * 0.15, y: rect.minY + rect.height * 0.2)
        )
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.maxX * 0.75, y: rect.midY)
        )
        p.closeSubpath()
        return p
    }
}

/// A mouth curve. Positive depth smiles, negative depth frowns.
struct SmileShape: Shape {
    var depth: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let top = depth >= 0 ? rect.minY : rect.maxY
        let control = depth >= 0
            ? rect.minY + rect.height * 2 * depth
            : rect.maxY + rect.height * 2 * depth
        p.move(to: CGPoint(x: rect.minX, y: top))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: top), control: CGPoint(x: rect.midX, y: control))
        if depth >= 1 {
            p.closeSubpath()
        }
        return p
    }
}

#Preview {
    HStack {
        PoopMascot(expression: .happy)
        PoopMascot(expression: .calm)
        PoopMascot(expression: .worried)
    }
    .padding()
    .background(Theme.background)
}
