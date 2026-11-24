import { useMemo, type CSSProperties } from 'react'
import { EntryBadge } from '../components/Bristol'
import { Icon } from '../components/Icons'
import { Logotype } from '../components/Logotype'
import { faceFor } from '../components/colors'
import { PalBuddy } from '../components/PalBuddy'
import { CommonTypeRow, DaySticker, EntryRow, SectionTitle, StatRow } from '../components/ui'
import type { Entry } from '../data/entries'
import { useReducedMotion } from '../data/settings'
import { useT } from '../i18n'
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
  const t = useT()
  const [countBefore, countAfter] = t.home.todayCount(stats.todayCount)

  return (
    <div className="screen home">
      <header className="home-top">
        <Logotype height={22} />
        <button type="button" className="icon-button" onClick={onSettings} aria-label={t.home.settings}>
          <Icon name="gear" size={24} />
        </button>
      </header>

      <div className="home-columns">
        <div className="home-main">
          <section className="today-header" aria-label={t.home.todaySection}>
            <div className="today-text">
              <p className="greeting">
                {t.date.greetingLine(DateText.greeting(now), DateText.header(now))}
              </p>
              <h1 className="today-count">
                {countBefore}
                <span className="num accent">{stats.todayCount}</span>
                {countAfter}
              </h1>
              {elapsed && stats.lastDate !== null && (
                <p className="since">{StatsFormat.isJustNow(stats.lastDate, now) ? t.home.justVisited : t.home.sinceLast(elapsed)}</p>
              )}
              <p className="mood">{moodMessage(mood)}</p>
            </div>
            <PalBuddy face={faceFor(mood)} hop={logCount} size={76} />
          </section>

          <div className="log-group">
            <LogStickerButton todayTypes={todayTypes} burst={logCount} onClick={onLog} />
            <button type="button" className="secondary-button" onClick={onAdd}>
              <Icon name="history" size={20} />
              {t.home.addPast}
            </button>
          </div>
        </div>

        <div className="home-side">
          <WeekStickers entries={entries} now={now} />
          <SummaryPanel stats={stats} commonType={commonType} />

          {entries.length > 0 && (
            <section>
              <SectionTitle>{t.home.recent}</SectionTitle>
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
  const t = useT()
  const shown = todayTypes.slice(0, 5)
  return (
    <button
      type="button"
      className="log-sticker"
      onClick={onClick}
      aria-label={t.home.logLabel(todayTypes.length)}
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
      <span className="log-title">{t.home.logTitle}</span>
      <span className="log-subtitle">
        {todayTypes.length === 0 ? t.home.logFirst : t.home.logNth(todayTypes.length + 1)}
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
  const t = useT()
  return (
    <section>
      <div className="section-head">
        <SectionTitle>{t.home.thisWeek}</SectionTitle>
        <span className="muted num">{t.units.count(total)}</span>
      </div>
      <ol className="week-stickers">
        {days.map((day) => {
          const count = counts.get(day) ?? 0
          const isToday = day === today
          return (
            <li key={day} aria-label={t.home.dayLabel(DateText.dayTitle(day, now), count)}>
              <DaySticker count={count} isFuture={day > now} isToday={isToday}>
                {count > 0 ? count : null}
              </DaySticker>
              <span className={`week-label${isToday ? ' today' : ''}`} aria-hidden="true">
                {isToday ? t.date.today : DateText.weekdayShort(day)}
              </span>
            </li>
          )
        })}
      </ol>
    </section>
  )
}

/** Home's short, friendly summary; the full table lives in Trends. */
function SummaryPanel({ stats, commonType }: { stats: PoopStats; commonType: BristolType | null }) {
  const interval = StatsFormat.interval(stats.averageIntervalDays)
  const t = useT()
  return (
    <section>
      <SectionTitle>{t.home.summary}</SectionTitle>
      <div className="panel rows">
        <StatRow label={t.home.last7Days} value={String(stats.last7DaysCount)} unit={t.units.times(stats.last7DaysCount)} />
        <StatRow label={t.home.howOften} value={interval.value} unit={interval.unit} />
        <CommonTypeRow type={commonType} />
      </div>
    </section>
  )
}
