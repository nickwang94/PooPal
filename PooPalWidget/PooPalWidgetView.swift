import SwiftUI
import WidgetKit

struct PooPalWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PoopWidgetEntry

    private var statusText: String {
        switch entry.daysSinceLast {
        case nil: "还没有记录哦"
        case 0?: entry.lastDate.map { "上次 \(DateText.time($0))" } ?? "今天来过啦"
        case 1?: "昨天来过啦"
        case let days?: "\(days) 天没来了"
        }
    }

    private var face: PalBuddy.Face {
        PalBuddy.Face(PoopMood(daysSinceLast: entry.daysSinceLast))
    }

    var body: some View {
        Group {
            switch family {
            case .systemMedium: medium
            default: small
            }
        }
        .fontDesign(.rounded)
        .foregroundStyle(Theme.onSunny)
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(entry.todayCount)")
                        .font(.system(size: 40, weight: .heavy).monospacedDigit())
                        .contentTransition(.numericText())
                    Text("今天 · 次")
                        .font(.caption.weight(.bold))
                        .opacity(0.7)
                }
                Spacer(minLength: 0)
                PalBuddy(face: face, color: .white, edgeColor: .white)
                    .frame(width: 40, height: 40)
            }
            Text(statusText)
                .font(.caption2.weight(.medium))
                .opacity(0.75)
                .lineLimit(1)
                .padding(.top, 2)
            Spacer(minLength: 8)
            logButton
        }
    }

    private var medium: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    PalBuddy(face: face, color: .white, edgeColor: .white)
                        .frame(width: 34, height: 34)
                    Logotype(color: Theme.onSunny)
                        .frame(height: 15)
                }
                Spacer(minLength: 6)
                HStack(alignment: .firstTextBaseline, spacing: 18) {
                    stat("\(entry.todayCount)", "今天")
                    stat("\(entry.last7DaysCount)", "近 7 天")
                }
                Text(statusText)
                    .font(.caption.weight(.medium))
                    .opacity(0.75)
                    .padding(.top, 2)
            }
            Spacer(minLength: 0)
            logButton
                .frame(width: 112)
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .font(.system(size: 32, weight: .heavy).monospacedDigit())
                .contentTransition(.numericText())
            Text(label)
                .font(.caption.weight(.bold))
                .opacity(0.7)
        }
    }

    private var logButton: some View {
        Button(intent: LogPoopIntent()) {
            Group {
                if family == .systemMedium {
                    VStack(spacing: 2) {
                        Image(systemName: "plus").font(.title3.weight(.heavy))
                        Text("记一下").font(.headline.weight(.heavy))
                    }
                } else {
                    Label("记一下", systemImage: "plus")
                        .font(.subheadline.weight(.heavy))
                }
            }
            .foregroundStyle(Color(hex: 0x7A4BA0))
            .frame(maxWidth: .infinity, minHeight: family == .systemMedium ? 112 : 38)
            .background(
                RoundedRectangle(cornerRadius: family == .systemMedium ? 26 : 19, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.12), radius: 3, y: 2)
            )
            .widgetAccentable()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("记录一次便便")
    }
}
