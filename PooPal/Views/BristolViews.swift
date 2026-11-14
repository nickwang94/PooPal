import SwiftUI

/// Hand-drawn style illustration for each Bristol type, in the same palette as the mascot.
struct BristolIllustration: View {
    let type: BristolType

    var body: some View {
        Canvas { context, size in
            let s = min(size.width, size.height)
            let origin = CGPoint(x: (size.width - s) / 2, y: (size.height - s) / 2)
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: origin.x + x * s, y: origin.y + y * s) }
            func circle(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) -> Path {
                Path(ellipseIn: CGRect(x: origin.x + (x - r) * s, y: origin.y + (y - r) * s, width: 2 * r * s, height: 2 * r * s))
            }
            func ellipse(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> Path {
                Path(ellipseIn: CGRect(x: origin.x + (x - rx) * s, y: origin.y + (y - ry) * s, width: 2 * rx * s, height: 2 * ry * s))
            }
            let body = GraphicsContext.Shading.linearGradient(
                Gradient(colors: [Theme.poopLight, Theme.poop]),
                startPoint: p(0.5, 0.2), endPoint: p(0.5, 0.85)
            )
            var face = CGPoint(x: 0.5, y: 0.5)

            switch type {
            case .separateLumps:
                for (x, y, r) in [(0.28, 0.36, 0.13), (0.62, 0.30, 0.11), (0.70, 0.64, 0.12), (0.38, 0.68, 0.15)] {
                    context.fill(circle(x, y, r), with: body)
                }
                face = CGPoint(x: 0.38, y: 0.68)
            case .lumpySausage:
                for (i, x) in stride(from: 0.22, through: 0.78, by: 0.14).enumerated() {
                    context.fill(circle(x, 0.52 + (i.isMultiple(of: 2) ? -0.025 : 0.025), 0.15), with: body)
                }
            case .crackedSausage:
                let rect = CGRect(x: origin.x + 0.1 * s, y: origin.y + 0.36 * s, width: 0.8 * s, height: 0.3 * s)
                context.fill(Path(roundedRect: rect, cornerRadius: 0.15 * s), with: body)
                var cracks = Path()
                for x in [0.26, 0.74] {
                    cracks.move(to: p(x - 0.03, 0.38))
                    cracks.addLine(to: p(x + 0.01, 0.45))
                    cracks.addLine(to: p(x - 0.02, 0.5))
                }
                context.stroke(cracks, with: .color(Theme.cream.opacity(0.8)), style: StrokeStyle(lineWidth: 0.025 * s, lineCap: .round, lineJoin: .round))
                face = CGPoint(x: 0.5, y: 0.53)
            case .smoothSnake:
                var snake = Path()
                snake.move(to: p(0.16, 0.62))
                snake.addCurve(to: p(0.84, 0.42), control1: p(0.4, 0.28), control2: p(0.6, 0.78))
                context.stroke(snake, with: body, style: StrokeStyle(lineWidth: 0.24 * s, lineCap: .round))
                context.stroke(snake, with: .color(.white.opacity(0.25)), style: StrokeStyle(lineWidth: 0.05 * s, lineCap: .round, dash: [0.12 * s, 0.4 * s]))
                face = CGPoint(x: 0.5, y: 0.52)
            case .softBlobs:
                context.fill(ellipse(0.3, 0.42, 0.17, 0.14), with: .color(Theme.poopLight))
                context.fill(ellipse(0.7, 0.4, 0.15, 0.12), with: .color(Theme.poopLight))
                context.fill(ellipse(0.5, 0.66, 0.22, 0.16), with: body)
                face = CGPoint(x: 0.5, y: 0.66)
            case .mushy:
                var blob = Path()
                let points = 18
                for i in 0...points {
                    let angle = Double(i) / Double(points) * 2 * .pi
                    let radius = i.isMultiple(of: 2) ? 0.36 : 0.30
                    let point = p(0.5 + radius * cos(angle), 0.55 + radius * 0.75 * sin(angle))
                    if i == 0 { blob.move(to: point) } else { blob.addLine(to: point) }
                }
                context.fill(blob, with: .color(Theme.poopLight))
                face = CGPoint(x: 0.5, y: 0.56)
            case .watery:
                context.fill(ellipse(0.5, 0.68, 0.36, 0.14), with: .color(Theme.poopLight.opacity(0.75)))
                for (x, y, r) in [(0.32, 0.3, 0.06), (0.6, 0.22, 0.05), (0.72, 0.4, 0.045)] {
                    var drop = Path()
                    drop.move(to: p(x, y - r * 1.8))
                    drop.addQuadCurve(to: p(x + r, y), control: p(x + r, y - r))
                    drop.addArc(center: p(x, y), radius: r * s, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
                    drop.addQuadCurve(to: p(x, y - r * 1.8), control: p(x - r, y - r))
                    context.fill(drop, with: .color(Theme.sky))
                }
                face = CGPoint(x: 0.5, y: 0.67)
            }

            let eyeR = 0.035
            for dx in [-0.07, 0.07] {
                context.fill(circle(face.x + dx, face.y - 0.02, eyeR), with: .color(Theme.ink))
                context.fill(circle(face.x + dx + 0.012, face.y - 0.032, eyeR * 0.35), with: .color(.white))
            }
            var smile = Path()
            smile.move(to: p(face.x - 0.035, face.y + 0.035))
            smile.addQuadCurve(to: p(face.x + 0.035, face.y + 0.035), control: p(face.x, face.y + (type.rawValue >= 6 || type == .separateLumps ? 0.01 : 0.075)))
            context.stroke(smile, with: .color(Theme.ink), style: StrokeStyle(lineWidth: 0.022 * s, lineCap: .round))
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("第 \(type.rawValue) 型 \(type.name)")
    }
}

/// Round pastel badge for an entry: its Bristol illustration, or the mascot when no type was recorded.
struct EntryBadge: View {
    let type: BristolType?
    var size: CGFloat = 40

    var body: some View {
        if let type {
            ZStack {
                Circle().fill(type.tint.opacity(0.7))
                BristolIllustration(type: type)
                    .frame(width: size * 0.8, height: size * 0.8)
            }
            .frame(width: size, height: size)
        } else {
            IconBadge(icon: .mascot, tint: Theme.cream, size: size)
        }
    }
}

struct BristolPicker: View {
    @Binding var selection: Int?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("便便形态")
                    .font(.rounded(17, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text("布里斯托分类 · 可不选")
                    .font(.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
            }
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(BristolType.allCases) { type in
                    cell(type)
                }
            }
            if let type = selection.flatMap(BristolType.init(rawValue:)) {
                Label(type.hint, systemImage: "info.circle.fill")
                    .font(.rounded(13, weight: .medium))
                    .foregroundStyle(Theme.inkSoft)
                    .transition(.opacity)
            }
        }
        .animation(.snappy, value: selection)
    }

    private func cell(_ type: BristolType) -> some View {
        let selected = selection == type.rawValue
        return Button {
            selection = selected ? nil : type.rawValue
        } label: {
            VStack(spacing: 2) {
                BristolIllustration(type: type)
                    .frame(width: 44, height: 44)
                Text("\(type.rawValue) 型")
                    .font(.rounded(11, weight: .bold))
                    .foregroundStyle(Theme.inkSoft)
                Text(type.name)
                    .font(.rounded(13, weight: .semibold))
                    .foregroundStyle(Theme.ink)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(selected ? type.tint : type.tint.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(selected ? Theme.poop : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(SquishButtonStyle())
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var selection: Int? = 4
    ScrollView {
        BristolPicker(selection: $selection)
            .padding()
    }
    .background(Theme.background)
}
