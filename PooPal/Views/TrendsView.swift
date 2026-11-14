import Charts
import SwiftUI

struct TrendsView: View {
    let entries: [PoopEntry]

    @State private var period: TrendPeriod = .week

    private var buckets: [TrendBucket] {
        Trends.buckets(entries.map(\.timestamp), period: period, count: 12)
    }

    private var distribution: [BristolType: Int] {
        PoopStats.bristolDistribution(entries.map { ($0.timestamp, $0.bristolType) })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Picker("周期", selection: $period) {
                    ForEach(TrendPeriod.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                countCard
                bristolCard
            }
            .padding(20)
            .padding(.bottom, 80)
        }
    }

    private var comparisonText: String {
        guard buckets.count >= 2 else { return "" }
        let current = buckets[buckets.count - 1].count
        let previous = buckets[buckets.count - 2].count
        let unit = period == .week ? "周" : "月"
        return "本\(unit) \(current) 次 · 上\(unit) \(previous) 次"
    }

    private var countCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                IconBadge(icon: .symbol("chart.bar.fill"), tint: Theme.mint, size: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text(period == .week ? "最近 12 周" : "最近 12 个月")
                        .font(.rounded(17, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Text(comparisonText)
                        .font(.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            Chart(buckets) { bucket in
                BarMark(
                    x: .value("时间", bucket.start, unit: period.component),
                    y: .value("次数", bucket.count)
                )
                .foregroundStyle(
                    LinearGradient(colors: [Theme.peach, Theme.poopLight], startPoint: .top, endPoint: .bottom)
                )
                .cornerRadius(6)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: period.component, count: 2)) { _ in
                    AxisGridLine().foregroundStyle(Theme.cream)
                    AxisValueLabel(format: period == .week
                        ? .dateTime.month(.defaultDigits).day()
                        : .dateTime.month(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(Theme.cream)
                    AxisValueLabel()
                }
            }
            .frame(height: 200)
        }
        .card()
    }

    private var bristolCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                IconBadge(icon: .symbol("sparkles"), tint: Theme.lavender, size: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text("近 30 天形态分布")
                        .font(.rounded(17, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Text("3–4 型最理想；1–2 偏干，6–7 偏稀")
                        .font(.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            if distribution.isEmpty {
                Text("还没有记录形态。记录时选一下形态，这里就会出现图表啦")
                    .font(.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .padding(.vertical, 20)
            } else {
                Chart(BristolType.allCases) { type in
                    BarMark(
                        x: .value("形态", "\(type.rawValue)"),
                        y: .value("次数", distribution[type] ?? 0)
                    )
                    .foregroundStyle(type.tint)
                    .cornerRadius(6)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine().foregroundStyle(Theme.cream)
                        AxisValueLabel()
                    }
                }
                .frame(height: 150)
                HStack(spacing: 0) {
                    ForEach(BristolType.allCases) { type in
                        BristolIllustration(type: type)
                            .frame(maxWidth: .infinity)
                            .frame(height: 30)
                    }
                }
                .padding(.leading, 24)
            }
        }
        .card()
    }
}
