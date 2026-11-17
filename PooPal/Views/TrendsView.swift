import Charts
import SwiftUI

struct TrendsView: View {
    let entries: [PoopEntry]

    @State private var period: TrendPeriod = .week
    @State private var showingAllNumbers = false

    private var buckets: [TrendBucket] {
        Trends.buckets(entries.map(\.timestamp), period: period, count: 12)
    }

    private var distribution: [BristolType: Int] {
        PoopStats.bristolDistribution(entries.map { ($0.timestamp, $0.bristolType) })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                countSection
                bristolSection
                allNumbersSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 96)
        }
    }

    private var unit: String { period == .week ? "周" : "月" }

    private var countSection: some View {
        let current = buckets.last?.count ?? 0
        let previous = buckets.dropLast().last?.count ?? 0
        let average = buckets.isEmpty ? 0 : Double(buckets.map(\.count).reduce(0, +)) / Double(buckets.count)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                SectionTitle("来了几次")
                Spacer()
                Picker("周期", selection: $period) {
                    ForEach(TrendPeriod.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }
            VStack(alignment: .leading, spacing: 16) {
                (Text("这\(unit) ") + Text("\(current)").bold().foregroundStyle(Theme.accent) + Text(" 次，上\(unit) \(previous) 次"))
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Theme.ink)
                Text(String(format: "最近 12 \(unit)平均每\(unit) %.1f 次（虚线）", average))
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft)
                Chart {
                    ForEach(buckets) { bucket in
                        BarMark(
                            x: .value("时间", bucket.start, unit: period.component),
                            y: .value("次数", bucket.count),
                            width: .ratio(0.62)
                        )
                        .foregroundStyle(bucket.id == buckets.last?.id ? Theme.accent : Theme.accentSoft)
                        .clipShape(Capsule())
                    }
                    RuleMark(y: .value("平均", average))
                        .foregroundStyle(Theme.inkSoft.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: period.component, count: 3)) { _ in
                        AxisGridLine().foregroundStyle(Theme.line)
                        AxisValueLabel(format: period == .week
                            ? .dateTime.month(.defaultDigits).day()
                            : .dateTime.month(.defaultDigits))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing) { _ in
                        AxisGridLine().foregroundStyle(Theme.line)
                        AxisValueLabel().foregroundStyle(Theme.inkSoft)
                    }
                }
                .frame(height: 200)
                .accessibilityLabel("最近 12 \(unit)的次数柱状图")
            }
            .padding(16)
            .panel()
        }
    }

    private var allNumbersSection: some View {
        let stats = PoopStats(dates: entries.map(\.timestamp))
        let common = PoopStats.mostCommonBristol(entries.map { ($0.timestamp, $0.bristolType) })
        return DisclosureGroup(isExpanded: $showingAllNumbers) {
            StatsPanel(stats: stats, commonType: common)
                .padding(.top, 12)
        } label: {
            SectionTitle("全部数字")
        }
        .tint(Theme.accent)
    }

    private var bristolSection: some View {
        let total = distribution.values.reduce(0, +)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                SectionTitle("近 30 天长什么样")
                Spacer()
                Text("\(total) 次有记录")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Theme.inkSoft)
            }
            VStack(alignment: .leading, spacing: 0) {
                if total == 0 {
                    Text("记的时候顺手选一下形态，这里就会画出来。")
                        .foregroundStyle(Theme.inkSoft)
                        .padding(16)
                } else {
                    ForEach(BristolType.allCases) { type in
                        let count = distribution[type] ?? 0
                        HStack(spacing: 12) {
                            EntryBadge(type: type, size: 30)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("\(type.rawValue) 型 · \(type.name)")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(Theme.ink)
                                    Spacer()
                                    Text("\(count)")
                                        .font(.subheadline.weight(.semibold).monospacedDigit())
                                        .foregroundStyle(count == 0 ? Theme.inkSoft : Theme.ink)
                                }
                                GeometryReader { proxy in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Theme.surfaceSunk)
                                        Capsule().fill(type.tint)
                                            .frame(width: max(count == 0 ? 0 : 6, proxy.size.width * CGFloat(count) / CGFloat(max(total, 1))))
                                    }
                                }
                                .frame(height: 8)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .accessibilityElement(children: .combine)
                    }
                    Text("3–4 型最理想；1–2 型偏干，6–7 型偏稀。")
                        .font(.footnote)
                        .foregroundStyle(Theme.inkSoft)
                        .padding(16)
                }
            }
            .panel()
        }
    }
}
