import SwiftUI
import WidgetKit

struct PooPalWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PoopWidgetEntry

    private var statusText: String {
        switch entry.daysSinceLast {
        case nil: "还没有记录"
        case 0?: entry.lastDate.map { "上次 \(DateText.time($0))" } ?? "今天已记录"
        case 1?: "上次是昨天"
        case let days?: "\(days) 天没记录"
        }
    }

    var body: some View {
        switch family {
        case .systemMedium: medium
        default: small
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            Logotype(color: Theme.onGlaze.opacity(0.85))
                .frame(height: 13)
            Spacer(minLength: 6)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(entry.todayCount)")
                    .font(.system(size: 38, weight: .bold).monospacedDigit())
                    .contentTransition(.numericText())
                Text("次 · 今天")
                    .font(.caption.weight(.semibold))
                    .opacity(0.8)
            }
            Text(statusText)
                .font(.caption2)
                .opacity(0.75)
                .lineLimit(1)
            Spacer(minLength: 8)
            logButton
        }
        .foregroundStyle(Theme.onGlaze)
    }

    private var medium: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                Logotype(color: Theme.onGlaze.opacity(0.85))
                    .frame(height: 15)
                Spacer(minLength: 6)
                HStack(alignment: .firstTextBaseline, spacing: 18) {
                    stat("\(entry.todayCount)", "今天")
                    stat("\(entry.last7DaysCount)", "近 7 天")
                }
                Text(statusText)
                    .font(.caption)
                    .opacity(0.75)
                    .padding(.top, 2)
            }
            Spacer(minLength: 0)
            logButton
                .frame(width: 112)
        }
        .foregroundStyle(Theme.onGlaze)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .font(.system(size: 32, weight: .bold).monospacedDigit())
                .contentTransition(.numericText())
            Text(label)
                .font(.caption.weight(.semibold))
                .opacity(0.8)
        }
    }

    private var logButton: some View {
        Button(intent: LogPoopIntent()) {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.subheadline.weight(.bold))
                Text("记一次")
                    .font(.subheadline.weight(.bold))
            }
            .foregroundStyle(Theme.glazeDeep)
            .frame(maxWidth: .infinity, minHeight: family == .systemMedium ? 112 : 36)
            .background(
                RoundedRectangle(cornerRadius: family == .systemMedium ? 18 : 12, style: .continuous)
                    .fill(Theme.onGlaze)
            )
            .widgetAccentable()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("记录一次便便")
    }
}
