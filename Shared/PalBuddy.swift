import SwiftUI

/// The "Pal": a soft round marigold buddy whose face follows how things are going.
/// Abstract on purpose; never poop-shaped.
struct PalBuddy: View {
    enum Face {
        case beaming, smile, calm, worried, hello

        init(_ mood: PoopMood) {
            switch mood {
            case .noData: self = .hello
            case .today: self = .beaming
            case .yesterday: self = .smile
            case .aWhile: self = .calm
            case .tooLong: self = .worried
            }
        }
    }

    var face: Face = .smile
    /// Changing this makes the buddy hop once.
    var hop = 0
    var color: Color = Theme.sunny

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var blinking = false
    @State private var lift: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            ZStack {
                Ellipse()
                    .fill(color)
                    .overlay(Ellipse().strokeBorder(Theme.stickerEdge, lineWidth: max(1.5, size * 0.045)))
                    .frame(width: size, height: size * 0.92)
                    .shadow(color: .black.opacity(0.12), radius: size * 0.04, y: size * 0.03)
                faceCanvas(size: size)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .offset(y: -lift * size)
            .scaleEffect(x: 1 + lift * 0.06, y: 1 - lift * 0.04, anchor: .bottom)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
        .onChange(of: hop) { _, _ in
            guard !reduceMotion else { return }
            withAnimation(.spring(response: 0.22, dampingFraction: 0.5)) { lift = 0.22 }
            withAnimation(.spring(response: 0.38, dampingFraction: 0.45).delay(0.16)) { lift = 0 }
        }
        .task {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Double.random(in: 2.8...5.0)))
                withAnimation(.easeInOut(duration: 0.08)) { blinking = true }
                try? await Task.sleep(for: .milliseconds(130))
                withAnimation(.easeInOut(duration: 0.1)) { blinking = false }
            }
        }
    }

    private func faceCanvas(size: CGFloat) -> some View {
        Canvas { context, canvas in
            let w = canvas.width
            let ink = Theme.onSunny
            let eyeY = w * 0.44
            let eyeDX = w * 0.17
            let eyeR = w * 0.055
            for side in [-1.0, 1.0] {
                let cx = w / 2 + side * eyeDX
                if face == .beaming {
                    var arc = Path()
                    arc.addArc(center: CGPoint(x: cx, y: eyeY + eyeR * 0.6), radius: eyeR * 1.2,
                               startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
                    context.stroke(arc, with: .color(ink), style: StrokeStyle(lineWidth: w * 0.04, lineCap: .round))
                } else {
                    let h = blinking ? eyeR * 0.35 : eyeR * 2
                    context.fill(Path(ellipseIn: CGRect(x: cx - eyeR, y: eyeY - h / 2, width: eyeR * 2, height: h)), with: .color(ink))
                }
                let cheek = CGRect(x: cx + side * w * 0.08 - w * 0.06, y: eyeY + w * 0.1, width: w * 0.12, height: w * 0.07)
                context.fill(Path(ellipseIn: cheek), with: .color(Theme.blush.opacity(face == .worried ? 0 : 0.55)))
            }
            var mouth = Path()
            let my = w * 0.62
            switch face {
            case .beaming, .hello:
                mouth.addArc(center: CGPoint(x: w / 2, y: my - w * 0.02), radius: w * 0.09,
                             startAngle: .degrees(20), endAngle: .degrees(160), clockwise: false)
            case .smile:
                mouth.addArc(center: CGPoint(x: w / 2, y: my - w * 0.05), radius: w * 0.08,
                             startAngle: .degrees(40), endAngle: .degrees(140), clockwise: false)
            case .calm:
                mouth.move(to: CGPoint(x: w / 2 - w * 0.06, y: my))
                mouth.addLine(to: CGPoint(x: w / 2 + w * 0.06, y: my))
            case .worried:
                mouth.addArc(center: CGPoint(x: w / 2, y: my + w * 0.07), radius: w * 0.07,
                             startAngle: .degrees(220), endAngle: .degrees(320), clockwise: false)
            }
            context.stroke(mouth, with: .color(ink), style: StrokeStyle(lineWidth: w * 0.04, lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    HStack {
        ForEach([PalBuddy.Face.hello, .beaming, .smile, .calm, .worried], id: \.self) { face in
            PalBuddy(face: face).frame(width: 60)
        }
    }
    .padding()
    .background(Theme.ground)
}
