import SwiftUI

/// The PooPal lettering mark: rounded monoline letters built from one stroke weight,
/// so the "o" rings and the bowls of the "P"s share the same circle. With `eyes`,
/// the two "o"s of "Poo" get pupils and the mark looks back at you.
struct Logotype: View {
    enum Layout {
        case line
        /// "Poo" over "Pal", the two P stems aligned.
        case stacked
    }

    var layout: Layout = .line
    var color: Color = Theme.accent
    var eyes = false
    var eyeColor: Color? = nil

    private static let stroke: CGFloat = 0.28
    private static let cap: CGFloat = 1.40
    private static let xHeight: CGFloat = 1.0
    private static let bowl: CGFloat = 0.96
    private static let gap: CGFloat = 0.17
    private static let leading: CGFloat = 0.34

    private enum Letter { case P, o, a, l }

    private static func width(_ letter: Letter) -> CGFloat {
        switch letter {
        case .P: bowl
        case .o, .a: xHeight
        case .l: stroke
        }
    }

    private static func width(_ word: [Letter]) -> CGFloat {
        word.map(width).reduce(0, +) + gap * CGFloat(word.count - 1)
    }

    private static let first: [Letter] = [.P, .o, .o]
    private static let second: [Letter] = [.P, .a, .l]

    private var unitSize: CGSize {
        switch layout {
        case .line:
            CGSize(width: Self.width(Self.first + Self.second) + Self.gap * 0.4, height: Self.cap)
        case .stacked:
            CGSize(width: max(Self.width(Self.first), Self.width(Self.second)), height: Self.cap * 2 + Self.leading)
        }
    }

    var body: some View {
        let size = unitSize
        Canvas { context, canvasSize in
            let s = min(canvasSize.width / size.width, canvasSize.height / size.height)
            var path = Path()
            var pupils = Path()
            switch layout {
            case .line:
                var x: CGFloat = 0
                for (index, letter) in (Self.first + Self.second).enumerated() {
                    if index == 3 { x += Self.gap * 0.4 }
                    Self.add(letter, at: CGPoint(x: x, y: 0), scale: s, to: &path)
                    if eyes, index == 1 || index == 2 {
                        let r = Self.stroke * 0.46
                        let cx = x + Self.xHeight / 2 + 0.06
                        let cy = Self.cap - Self.xHeight / 2 - 0.04
                        pupils.addEllipse(in: CGRect(x: (cx - r) * s, y: (cy - r) * s, width: 2 * r * s, height: 2 * r * s))
                    }
                    x += Self.width(letter) + Self.gap
                }
            case .stacked:
                for (row, word) in [Self.first, Self.second].enumerated() {
                    var x: CGFloat = 0
                    let top = CGFloat(row) * (Self.cap + Self.leading)
                    for letter in word {
                        Self.add(letter, at: CGPoint(x: x, y: top), scale: s, to: &path)
                        x += Self.width(letter) + Self.gap
                    }
                }
            }
            context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: Self.stroke * s, lineCap: .round, lineJoin: .round))
            context.fill(pupils, with: .color(eyeColor ?? color))
        }
        .aspectRatio(size.width / size.height, contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel("PooPal")
    }

    private static func add(_ letter: Letter, at origin: CGPoint, scale s: CGFloat, to path: inout Path) {
        let w = stroke
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: (origin.x + x) * s, y: (origin.y + y) * s) }
        func stem(_ x: CGFloat, from top: CGFloat, to bottom: CGFloat) {
            path.move(to: p(x, top))
            path.addLine(to: p(x, bottom))
        }
        func ring(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) {
            path.addEllipse(in: CGRect(x: (origin.x + cx - r) * s, y: (origin.y + cy - r) * s, width: 2 * r * s, height: 2 * r * s))
        }
        switch letter {
        case .P:
            let r = (bowl - w) / 2
            stem(w / 2, from: w / 2 + r, to: cap - w / 2)
            ring(w / 2 + r, w / 2 + r, r)
        case .o:
            let r = (xHeight - w) / 2
            ring(xHeight / 2, cap - xHeight / 2, r)
        case .a:
            let r = (xHeight - w) / 2
            ring(xHeight / 2, cap - xHeight / 2, r)
            stem(xHeight - w / 2, from: cap - xHeight / 2, to: cap - w / 2)
        case .l:
            stem(w / 2, from: w / 2, to: cap - w / 2)
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        Logotype()
            .frame(height: 40)
        Logotype(color: Theme.onSunny, eyes: true)
            .frame(width: 240)
            .padding(40)
            .background(Theme.sunny)
    }
}
