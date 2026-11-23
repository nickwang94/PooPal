import { useMemo, useState } from 'react'
import { EntryBadge } from '../components/Bristol'
import { stateVar } from '../components/colors'
import { Icon } from '../components/Icons'
import { Segmented, SectionTitle, StatsPanel } from '../components/ui'
import type { Entry } from '../data/entries'
import { BRISTOL_TYPES, bristolLabel } from '../logic/bristol'
import { pad } from '../logic/dates'
import {
  bristolDistribution,
  computeStats,
  mostCommonBristol,
  trendBuckets,
  type TrendBucket,
  type TrendPeriod,
} from '../logic/stats'

const PERIODS: { value: TrendPeriod; title: string }[] = [
  { value: 'week', title: '按周' },
  { value: 'month', title: '按月' },
]

export function Trends({ entries, now }: { entries: Entry[]; now: number }) {
  const [period, setPeriod] = useState<TrendPeriod>('week')
  const dates = useMemo(() => entries.map((e) => e.timestamp), [entries])
  const typed = useMemo(() => entries.map((e) => ({ date: e.timestamp, type: e.bristolType })), [entries])
  const buckets = useMemo(() => trendBuckets(dates, period, 12, now), [dates, period, now])
  const unit = period === 'week' ? '周' : '月'
  const current = buckets[buckets.length - 1]?.count ?? 0
  const previous = buckets[buckets.length - 2]?.count ?? 0
  const average = buckets.length ? buckets.reduce((n, b) => n + b.count, 0) / buckets.length : 0
  const distribution = bristolDistribution(typed, 30, now)
  const total = [...distribution.values()].reduce((a, b) => a + b, 0)
  const stats = computeStats(dates, now)
  const common = mostCommonBristol(typed, 30, now)

  return (
    <div className="trends">
      <section>
        <div className="section-head">
          <SectionTitle>来了几次</SectionTitle>
          <Segmented label="周期" value={period} options={PERIODS} onChange={setPeriod} className="small" />
        </div>
        <div className="panel padded">
          <p className="trend-sentence num">
            这{unit} <b className="accent">{current}</b> 次，上{unit} {previous} 次
          </p>
          <p className="muted">
            最近 12 {unit}平均每{unit} {average.toFixed(1)} 次（虚线）
          </p>
          <BarChart buckets={buckets} period={period} average={average} />
        </div>
      </section>

      <section>
        <div className="section-head">
          <SectionTitle>近 30 天长什么样</SectionTitle>
          <span className="muted num">{total} 次有记录</span>
        </div>
        <div className="panel">
          {total === 0 ? (
            <p className="padded muted">记的时候顺手选一下形态，这里就会画出来。</p>
          ) : (
            <>
              <ul className="distribution">
                {BRISTOL_TYPES.map((type) => {
                  const count = distribution.get(type) ?? 0
                  return (
                    <li key={type}>
                      <EntryBadge type={type} size={30} />
                      <div className="dist-body">
                        <div className="dist-line">
                          <span>{bristolLabel(type)}</span>
                          <b className={`num${count === 0 ? ' muted' : ''}`}>{count}</b>
                        </div>
                        <div className="dist-track">
                          <div
                            className="dist-fill"
                            style={{
                              width: count === 0 ? 0 : `max(6px, ${(count / Math.max(total, 1)) * 100}%)`,
                              background: stateVar(type),
                            }}
                          />
                        </div>
                      </div>
                    </li>
                  )
                })}
              </ul>
              <p className="padded footnote">3–4 型最理想；1–2 型偏干，6–7 型偏稀。</p>
            </>
          )}
        </div>
      </section>

      <details className="all-numbers">
        <summary>
          <SectionTitle>全部数字</SectionTitle>
          <Icon name="chevronDown" size={18} className="disclosure" />
        </summary>
        <StatsPanel stats={stats} commonType={common} />
      </details>
    </div>
  )
}

function niceStep(max: number): number {
  const raw = Math.max(max / 4, 1)
  const magnitude = 10 ** Math.floor(Math.log10(raw))
  for (const f of [1, 2, 5, 10]) if (raw <= f * magnitude) return f * magnitude
  return 10 * magnitude
}

function BarChart({ buckets, period, average }: { buckets: TrendBucket[]; period: TrendPeriod; average: number }) {
  const max = Math.max(...buckets.map((b) => b.count), average, 1)
  const step = niceStep(max)
  const top = Math.ceil(max / step) * step
  const ticks = Array.from({ length: Math.round(top / step) + 1 }, (_, i) => i * step)
  const label = (start: number) => {
    const d = new Date(start)
    return period === 'week' ? `${d.getMonth() + 1}/${d.getDate()}` : `${d.getMonth() + 1}月`
  }
  const unit = period === 'week' ? '周' : '月'
  const description = buckets
    .map((b) => {
      const d = new Date(b.start)
      return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${b.count} 次`
    })
    .join('，')
  return (
    <figure className="bar-chart" aria-label={`最近 12 ${unit}的次数柱状图：${description}`} role="img">
      <div className="chart-plot">
        {ticks.map((t) => (
          <div key={t} className="gridline" style={{ bottom: `${(t / top) * 100}%` }}>
            <span className="tick num">{t}</span>
          </div>
        ))}
        <div className="average-line" style={{ bottom: `${(average / top) * 100}%` }} />
        <div className="bars">
          {buckets.map((b, i) => (
            <div key={b.start} className="bar-slot">
              <div
                className={`bar${i === buckets.length - 1 ? ' current' : ''}`}
                style={{ height: `${(b.count / top) * 100}%` }}
              />
            </div>
          ))}
        </div>
      </div>
      <div className="bar-labels" aria-hidden="true">
        {buckets.map((b, i) => (
          <span key={b.start}>{i % 3 === 0 ? label(b.start) : ''}</span>
        ))}
      </div>
    </figure>
  )
}
