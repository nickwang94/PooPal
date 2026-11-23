import { useMemo, type CSSProperties } from 'react'
import { EntryBadge } from '../components/Bristol'
import { Icon } from '../components/Icons'
import { Logotype } from '../components/Logotype'
import { faceFor } from '../components/colors'
import { PalBuddy } from '../components/PalBuddy'
import { CommonTypeRow, DaySticker, EntryRow, SectionTitle, StatRow } from '../components/ui'
import type { Entry } from '../data/entries'
import { useReducedMotion } from '../data/settings'
import type { BristolType } from '../logic/bristol'
import { addDays, DateText, isSameDay, startOfDay, startOfWeek } from '../logic/dates'
import { computeStats, countsByDay, moodFor, moodMessage, mostCommonBristol, StatsFormat, type PoopStats } from '../logic/stats'

interface Props {
  entries: Entry[]
  now: number
  logCount: number
  onLog: () => void
  onAdd: () => void
  onEdit: (entry: Entry) => void
  onSettings: () => void
}

export function Home({ entries, now, logCount, onLog, onAdd, onEdit, onSettings }: Props) {
  const stats = useMemo(() => computeStats(entries.map((e) => e.timestamp), now), [entries, now])
  const commonType = useMemo(
    () => mostCommonBristol(entries.map((e) => ({ date: e.timestamp, type: e.bristolType })), 30, now),
    [entries, now],
  )
  const mood = moodFor(stats.daysSinceLast)
  const todayTypes = entries
    .filter((e) => isSameDay(e.timestamp, now) && e.timestamp <= now)
    .reverse()
    .map((e) => e.bristolType)
  const elapsed = StatsFormat.elapsed(stats.lastDate, now)

  return (
    <div className="screen home">
      <header className="home-top">
        <Logotype height={22} />
        <button type="button" className="icon-button" onClick={onSettings} aria-label="设置">
          <Icon name="gear" size={24} />
        </button>
      </header>

      <div className="home-columns">
        <div className="home-main">
          <section className="today-header" aria-label="今天">
            <div className="today-text">
              <p className="greeting">
                {DateText.greeting(now)}，{DateText.header(now)}
              </p>
              <h1 className="today-count">
                今天 <span className="num accent">{stats.todayCount}</span> 次
              </h1>
              {elapsed && <p className="since">{elapsed === '刚刚' ? '刚刚来过' : `距上次 ${elapsed}`}</p>}
              <p className="mood">{moodMessage(mood)}</p>
            </div>
            <PalBuddy face={faceFor(mood)} hop={logCount} size={76} />
          </section>

          <div className="log-group">
            <LogStickerButton todayTypes={todayTypes} burst={logCount} onClick={onLog} />
            <button type="button" className="secondary-button" onClick={onAdd}>
              <Icon name="history" size={20} />
              忘了记？补一条
            </button>
          </div>
        </div>

        <div className="home-side">
          <WeekStickers entries={entries} now={now} />
          <SummaryPanel stats={stats} commonType={commonType} />

          {entries.length > 0 && (
            <section>
              <SectionTitle>最近几次</SectionTitle>
              <div className="panel rows">
                {entries.slice(0, 3).map((entry) => (
                  <EntryRow key={entry.id} entry={entry} dayStyle onClick={() => onEdit(entry)} />
                ))}
              </div>
            </section>
          )}
        </div>
      </div>
    </div>
  )
}

const CONFETTI_COLORS = ['var(--accent)', 'var(--ideal)', 'var(--dry)', 'var(--loose)', 'var(--blush)', '#fff']
const TILTS = [-8, 6, -4, 9, -6]

/** The primary action: a big marigold sticker. Today's visits are pressed onto it as real stickers. */
function LogStickerButton({ todayTypes, burst, onClick }: { todayTypes: (BristolType | undefined)[]; burst: number; onClick: () => void }) {
  const reduceMotion = useReducedMotion()
  const shown = todayTypes.slice(0, 5)
  return (
    <button
      type="button"
      className="log-sticker"
      onClick={onClick}
      aria-label={`记一下，记录现在。今天已记录 ${todayTypes.length} 次`}
    >
      <span className="log-top">
        <span className="log-plus">
          <Icon name="plus" size={24} />
        </span>
        <span className="today-stickers" aria-hidden="true">
          {shown.map((type, i) => (
            <EntryBadge key={i} type={type} size={34} style={{ transform: `rotate(${TILTS[i % 5]}deg)` }} />
          ))}
          {todayTypes.length > 5 && <span className="more-stickers num">+{todayTypes.length - 5}</span>}
        </span>
      </span>
      <span className="log-title">记一下</span>
      <span className="log-subtitle">
        {todayTypes.length === 0 ? '刚去过？点我就记好' : `今天的第 ${todayTypes.length + 1} 张贴纸，点我就记好`}
      </span>
      {burst > 0 && !reduceMotion && (
        <span className="confetti" key={burst} aria-hidden="true">
          {Array.from({ length: 12 }, (_, i) => {
            const angle = (i / 12) * 2 * Math.PI + 0.3
            const distance = i % 2 === 0 ? 120 : 90
            const style = {
              '--dx': `${Math.cos(angle) * distance}px`,
              '--dy': `${Math.sin(angle) * distance * 0.55}px`,
              width: i % 3 === 0 ? 10 : 7,
              height: i % 3 === 0 ? 10 : 7,
              background: CONFETTI_COLORS[i % CONFETTI_COLORS.length],
            } as CSSProperties
            return <span key={i} className="confetti-dot" style={style} />
          })}
        </span>
      )}
    </button>
  )
}

/** This week as seven round stickers; color warms with the day's count. */
function WeekStickers({ entries, now }: { entries: Entry[]; now: number }) {
  const counts = countsByDay(entries.map((e) => e.timestamp))
  const weekStart = startOfWeek(now)
  const days = Array.from({ length: 7 }, (_, i) => addDays(weekStart, i))
  const total = days.reduce((n, d) => n + (counts.get(d) ?? 0), 0)
  const today = startOfDay(now)
  return (
    <section>
      <div className="section-head">
        <SectionTitle>这一周</SectionTitle>
        <span className="muted num">{total} 次</span>
      </div>
      <ol className="week-stickers">
        {days.map((day) => {
          const count = counts.get(day) ?? 0
          const isToday = day === today
          return (
            <li key={day} aria-label={`${DateText.dayTitle(day, now)}，${count} 次`}>
              <DaySticker count={count} isFuture={day > now} isToday={isToday}>
                {count > 0 ? count : null}
              </DaySticker>
              <span className={`week-label${isToday ? ' today' : ''}`} aria-hidden="true">
                {isToday ? '今天' : DateText.weekdayShort(day)}
              </span>
            </li>
          )
        })}
      </ol>
    </section>
  )
}

/** Home's short, friendly summary; the full table lives in 趋势. */
function SummaryPanel({ stats, commonType }: { stats: PoopStats; commonType: BristolType | null }) {
  const interval = StatsFormat.interval(stats.averageIntervalDays)
  return (
    <section>
      <SectionTitle>最近怎么样</SectionTitle>
      <div className="panel rows">
        <StatRow label="近 7 天来了" value={String(stats.last7DaysCount)} unit="次" />
        <StatRow label="大概多久一次" value={interval.value} unit={interval.unit} />
        <CommonTypeRow type={commonType} />
      </div>
    </section>
  )
}
