import { useMemo, useState } from 'react'
import { Icon } from '../components/Icons'
import { DaySticker, EntryRow, Segmented } from '../components/ui'
import type { Entry } from '../data/entries'
import { useT } from '../i18n'
import { addMonths, DateText, daysInMonth, startOfDay, startOfMonth, WEEK_STARTS_ON } from '../logic/dates'
import { countsByDay } from '../logic/stats'
import { Trends } from './Trends'

export type HistoryMode = 'calendar' | 'list' | 'trends'

interface Props {
  entries: Entry[]
  now: number
  mode: HistoryMode
  onModeChange: (mode: HistoryMode) => void
  onAdd: () => void
  onEdit: (entry: Entry) => void
}

export function History({ entries, now, mode, onModeChange, onAdd, onEdit }: Props) {
  const t = useT()
  const modes: { value: HistoryMode; title: string }[] = [
    { value: 'calendar', title: t.history.calendar },
    { value: 'list', title: t.history.list },
    { value: 'trends', title: t.history.trends },
  ]
  return (
    <div className="screen history">
      <div className="history-bar">
        {entries.length > 0 ? (
          <Segmented label={t.history.viewMode} value={mode} options={modes} onChange={onModeChange} className="glass" />
        ) : (
          <span />
        )}
        <button type="button" className="round-button glass" onClick={onAdd} aria-label={t.history.add}>
          <Icon name="plus" size={22} />
        </button>
      </div>
      <h1 className="large-title">{t.history.title}</h1>
      {entries.length === 0 ? (
        <div className="empty-state">
          <Icon name="grid" size={44} />
          <h2>{t.history.emptyTitle}</h2>
          <p>{t.history.emptyBody}</p>
        </div>
      ) : mode === 'calendar' ? (
        <CalendarPage entries={entries} now={now} onEdit={onEdit} />
      ) : mode === 'list' ? (
        <ListPage entries={entries} now={now} onEdit={onEdit} />
      ) : (
        <Trends entries={entries} now={now} />
      )}
    </div>
  )
}

const PAGE_DAYS = 60

function ListPage({ entries, now, onEdit }: { entries: Entry[]; now: number; onEdit: (e: Entry) => void }) {
  const [limit, setLimit] = useState(PAGE_DAYS)
  const t = useT()
  const groups = useMemo(() => {
    const map = new Map<number, Entry[]>()
    for (const entry of entries) {
      const day = startOfDay(entry.timestamp)
      const list = map.get(day)
      if (list) list.push(entry)
      else map.set(day, [entry])
    }
    return [...map.entries()].sort((a, b) => b[0] - a[0])
  }, [entries])
  return (
    <div className="list-page">
      {groups.slice(0, limit).map(([day, items]) => (
        <section key={day} className="list-group">
          <h2 className="group-header">{t.history.groupHeader(DateText.dayTitle(day, now), items.length)}</h2>
          <div className="panel rows">
            {items.map((entry) => (
              <EntryRow key={entry.id} entry={entry} onClick={() => onEdit(entry)} />
            ))}
          </div>
        </section>
      ))}
      {groups.length > limit && (
        <button type="button" className="secondary-button" onClick={() => setLimit((l) => l + PAGE_DAYS)}>
          {t.history.more}
        </button>
      )}
      <p className="footnote">{t.history.footnote}</p>
    </div>
  )
}

function CalendarPage({ entries, now, onEdit }: { entries: Entry[]; now: number; onEdit: (e: Entry) => void }) {
  const [month, setMonth] = useState(() => startOfMonth(now))
  const [selectedDay, setSelectedDay] = useState(() => startOfDay(now))
  const counts = useMemo(() => countsByDay(entries.map((e) => e.timestamp)), [entries])
  const selected = entries.filter((e) => startOfDay(e.timestamp) === selectedDay)
  const t = useT()
  return (
    <div className="calendar-page">
      <div className="panel calendar-panel">
        <MonthMosaic month={month} onMonthChange={setMonth} selectedDay={selectedDay} onSelect={setSelectedDay} counts={counts} now={now} />
      </div>
      <section className="list-group">
        <h2 className="group-header">{t.history.groupHeader(DateText.dayTitle(selectedDay, now), selected.length)}</h2>
        <div className="panel rows">
          {selected.length === 0 ? (
            <p className="row muted">{t.history.emptyDay}</p>
          ) : (
            selected.map((entry) => <EntryRow key={entry.id} entry={entry} onClick={() => onEdit(entry)} />)
          )}
        </div>
        {selected.length > 0 && <p className="footnote">{t.history.footnote}</p>}
      </section>
    </div>
  )
}

function MonthMosaic({
  month,
  onMonthChange,
  selectedDay,
  onSelect,
  counts,
  now,
}: {
  month: number
  onMonthChange: (m: number) => void
  selectedDay: number
  onSelect: (d: number) => void
  counts: Map<number, number>
  now: number
}) {
  const leading = (new Date(month).getDay() - WEEK_STARTS_ON + 7) % 7
  const days = Array.from({ length: daysInMonth(month) }, (_, i) => {
    const d = new Date(month)
    d.setDate(i + 1)
    return d.getTime()
  })
  const total = days.reduce((n, d) => n + (counts.get(d) ?? 0), 0)
  const canGoForward = month < startOfMonth(now)
  const today = startOfDay(now)
  const t = useT()

  return (
    <div className="month-mosaic">
      <div className="month-head">
        <div>
          <h2 className="month-title">{DateText.month(month)}</h2>
          <p className="muted num">{t.history.monthTotal(total)}</p>
        </div>
        <div className="month-nav">
          <button type="button" className="icon-button accent" onClick={() => onMonthChange(addMonths(month, -1))} aria-label={t.history.prevMonth}>
            <Icon name="chevronLeft" size={20} />
          </button>
          <button
            type="button"
            className="icon-button accent"
            onClick={() => onMonthChange(addMonths(month, 1))}
            disabled={!canGoForward}
            aria-label={t.history.nextMonth}
          >
            <Icon name="chevronRight" size={20} />
          </button>
        </div>
      </div>
      <div className="mosaic-grid" role="grid" aria-label={DateText.month(month)}>
        {DateText.weekdayHeaders().map((w, i) => (
          <span key={i} className="weekday" aria-hidden="true">
            {w}
          </span>
        ))}
        {Array.from({ length: leading }, (_, i) => (
          <span key={`pad-${i}`} />
        ))}
        {days.map((day) => {
          const count = counts.get(day) ?? 0
          const isFuture = day > now
          const isSelected = day === selectedDay
          const isToday = day === today
          return (
            <button
              key={day}
              type="button"
              className={`day-tile${isToday ? ' is-today' : ''}`}
              disabled={isFuture}
              aria-pressed={isSelected}
              aria-label={t.home.dayLabel(DateText.dayTitle(day, now), count)}
              onClick={() => onSelect(day)}
            >
              <DaySticker count={count} isFuture={isFuture} isToday={isToday} isSelected={isSelected}>
                {new Date(day).getDate()}
              </DaySticker>
              {count > 1 && <span className="count-badge num">{count}</span>}
            </button>
          )
        })}
      </div>
      <div className="legend" aria-hidden="true">
        <span>{t.history.legendLess}</span>
        {[0, 1, 2, 3].map((c) => (
          <span key={c} className={`legend-dot c${c}`} />
        ))}
        <span>{t.history.legendMore}</span>
      </div>
    </div>
  )
}
