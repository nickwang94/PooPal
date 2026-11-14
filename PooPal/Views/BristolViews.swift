import SwiftUI

/// Monochrome drawing of a Bristol type, in one ink color.
struct BristolGlyph: View {
    let type: BristolType
    var color: Color = Theme.ink

    var body: some View {
        Canvas { context, size in
            let s = min(size.width, size.height)
            let o = CGPoint(x: (size.width - s) / 2, y: (size.height - s) / 2)
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: o.x + x * s, y: o.y + y * s) }
            func ellipse(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> Path {
                Path(ellipseIn: CGRect(x: o.x + (x - rx) * s, y: o.y + (y - ry) * s, width: 2 * rx * s, height: 2 * ry * s))
            }
            let ink = GraphicsContext.Shading.color(color)
            let soft = GraphicsContext.Shading.color(color.opacity(0.55))

            switch type {
            case .separateLumps:
                for (x, y, r) in [(0.3, 0.38, 0.12), (0.62, 0.32, 0.1), (0.68, 0.64, 0.12), (0.36, 0.68, 0.13)] {
                    context.fill(ellipse(x, y, r, r), with: ink)
                }
            case .lumpySausage:
                for (i, x) in stride(from: 0.2, through: 0.8, by: 0.15).enumerated() {
                    context.fill(ellipse(x, 0.5 + (i.isMultiple(of: 2) ? -0.02 : 0.02), 0.13, 0.13), with: ink)
                }
            case .crackedSausage:
                let rect = CGRect(x: o.x + 0.1 * s, y: o.y + 0.37 * s, width: 0.8 * s, height: 0.26 * s)
                context.fill(Path(roundedRect: rect, cornerRadius: 0.13 * s), with: ink)
                var cracks = Path()
                for x in [0.32, 0.5, 0.68] {
                    cracks.move(to: p(x - 0.02, 0.37))
                    cracks.addLine(to: p(x + 0.02, 0.47))
                }
                context.blendMode = .destinationOut
                context.stroke(cracks, with: .color(.black), style: StrokeStyle(lineWidth: 0.035 * s, lineCap: .round))
                context.blendMode = .normal
            case .smoothSnake:
                var snake = Path()
                snake.move(to: p(0.16, 0.6))
                snake.addCurve(to: p(0.84, 0.42), control1: p(0.4, 0.3), control2: p(0.6, 0.76))
                context.stroke(snake, with: ink, style: StrokeStyle(lineWidth: 0.2 * s, lineCap: .round))
            case .softBlobs:
                context.fill(ellipse(0.3, 0.42, 0.15, 0.12), with: soft)
                context.fill(ellipse(0.68, 0.38, 0.13, 0.1), with: soft)
                context.fill(ellipse(0.5, 0.64, 0.2, 0.14), with: ink)
            case .mushy:
                var blob = Path()
                let points = 18
                for i in 0...points {
                    let angle = Double(i) / Double(points) * 2 * .pi
                    let radius = i.isMultiple(of: 2) ? 0.34 : 0.28
                    let point = p(0.5 + radius * cos(angle), 0.54 + radius * 0.72 * sin(angle))
                    if i == 0 { blob.move(to: point) } else { blob.addLine(to: point) }
                }
                context.fill(blob, with: soft)
            case .watery:
                context.fill(ellipse(0.5, 0.68, 0.34, 0.12), with: soft)
                for (x, y, r) in [(0.34, 0.32, 0.06), (0.6, 0.24, 0.05), (0.7, 0.42, 0.045)] {
                    var drop = Path()
                    drop.move(to: p(x, y - r * 1.9))
                    drop.addQuadCurve(to: p(x + r, y), control: p(x + r, y - r))
                    drop.addArc(center: p(x, y), radius: r * s, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
                    drop.addQuadCurve(to: p(x, y - r * 1.9), control: p(x - r, y - r))
                    context.fill(drop, with: ink)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("第 \(type.rawValue) 型 \(type.name)")
    }
}

/// Small tile for an entry: its Bristol glyph on the type's pale tint, or an empty tile when unrecorded.
struct EntryBadge: View {
    let type: BristolType?
    var size: CGFloat = 36

    var body: some View {
        ZStack {
            GlazeTile(color: type?.paleTint ?? Theme.surfaceSunk, radius: size * 0.26)
            if let type {
                BristolGlyph(type: type, color: type.tint)
                    .padding(size * 0.14)
            } else {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.38, weight: .semibold))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(type == nil)
    }
}

struct BristolPicker: View {
    @Binding var selection: Int?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(BristolType.allCases) { type in
                    cell(type)
                }
                unsureCell
            }
            if let type = selection.flatMap(BristolType.init(rawValue:)) {
                Text("\(type.group) · \(type.hint)")
                    .font(.footnote)
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .animation(.snappy, value: selection)
        .sensoryFeedback(.selection, trigger: selection)
    }

    private var unsureCell: some View {
        let selected = selection == nil
        return Button {
            selection = nil
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "questionmark")
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 34, height: 34)
                Text("—")
                    .font(.caption.weight(.bold))
                Text("不确定")
                    .font(.caption2)
                    .lineLimit(1)
            }
            .foregroundStyle(selected ? Theme.onGlaze : Theme.inkSoft)
            .frame(maxWidth: .infinity, minHeight: 84)
            .background(GlazeTile(color: selected ? Theme.glaze : Theme.surfaceSunk, radius: 12))
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("不确定形态")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func cell(_ type: BristolType) -> some View {
        let selected = selection == type.rawValue
        return Button {
            selection = selected ? nil : type.rawValue
        } label: {
            VStack(spacing: 4) {
                BristolGlyph(type: type, color: selected ? Theme.onGlaze : type.tint)
                    .frame(width: 34, height: 34)
                Text("\(type.rawValue)")
                    .font(.caption.weight(.bold).monospacedDigit())
                Text(type.name)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(selected ? Theme.onGlaze : Theme.ink)
            .frame(maxWidth: .infinity, minHeight: 84)
            .background(GlazeTile(color: selected ? type.tint : type.paleTint, radius: 12))
        }
        .buttonStyle(PressableStyle())
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// Native-feeling press: slight scale-down, springs back.
struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    @Previewable @State var selection: Int? = 4
    BristolPicker(selection: $selection)
        .padding()
        .background(Theme.ground)
}
