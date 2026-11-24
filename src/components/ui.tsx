import { useEffect, useRef, type ReactNode } from 'react'
import type { Entry } from '../data/entries'
import { useT } from '../i18n'
import { bristolLabel, type BristolType } from '../logic/bristol'
import { DateText } from '../logic/dates'
import { StatsFormat, type PoopStats } from '../logic/stats'
import { EntryBadge } from './Bristol'
import { stateVar } from './colors'
import { Icon } from './Icons'

export function SectionTitle({ children, as: Tag = 'h2' }: { children: ReactNode; as?: 'h2' | 'h3' }) {
  return <Tag className="section-title">{children}</Tag>
}

interface SegmentedProps<T extends string> {
  label: string
  value: T
  options: { value: T; title: string }[]
  onChange: (value: T) => void
  className?: string
}

export function Segmented<T extends string>({ label, value, options, onChange, className }: SegmentedProps<T>) {
  return (
    <div className={`segmented ${className ?? ''}`} role="radiogroup" aria-label={label}>
      {options.map((o) => (
        <button
          key={o.value}
          type="button"
          role="radio"
          aria-checked={o.value === value}
          className={o.value === value ? 'active' : ''}
          onClick={() => onChange(o.value)}
        >
          {o.title}
        </button>
      ))}
    </div>
  )
}

export function Toggle({ checked, onChange, label }: { checked: boolean; onChange: (v: boolean) => void; label: string }) {
  return (
    <button type="button" role="switch" aria-checked={checked} aria-label={label} className="toggle" onClick={() => onChange(!checked)}>
      <span className="toggle-knob" />
    </button>
  )
}

export function Stepper({
  value,
  min,
  max,
  onChange,
  label,
}: {
  value: number
  min: number
  max: number
  onChange: (v: number) => void
  label: string
}) {
  const t = useT()
  return (
    <div className="stepper" role="group" aria-label={label}>
      <button type="button" aria-label={t.settings.decrease} disabled={value <= min} onClick={() => onChange(Math.max(min, value - 1))}>
        −
      </button>
      <span className="stepper-divider" />
      <button type="button" aria-label={t.settings.increase} disabled={value >= max} onClick={() => onChange(Math.min(max, value + 1))}>
        +
      </button>
    </div>
  )
}

/**
 * A pill that shows a formatted date or time and opens the native picker when tapped. The real
 * `<input>` sits invisibly on top, so iOS Safari still presents its wheel picker.
 */
export function PickerPill({
  type,
  value,
  display,
  label,
  max,
  onChange,
}: {
  type: 'date' | 'time'
  value: string
  display: string
  label: string
  max?: string
  onChange: (value: string) => void
}) {
  return (
    <label className="picker-pill">
      <span aria-hidden="true">{display}</span>
      <input
        type={type}
        value={value}
        max={max}
        aria-label={label}
        required
        onClick={(e) => {
          try {
            e.currentTarget.showPicker?.()
          } catch {
            // Not allowed here (e.g. cross-origin iframe); the native control still works.
          }
        }}
        onChange={(e) => e.target.value && onChange(e.target.value)}
      />
    </label>
  )
}

export function StatRow({ label, value, unit }: { label: string; value: string; unit: string }) {
  return (
    <div className="row stat-row">
      <span>{label}</span>
      <span className="stat-value">
        <b>{value}</b>
        {unit && <small>{unit}</small>}
      </span>
    </div>
  )
}

export function CommonTypeRow({ type }: { type: BristolType | null }) {
  const t = useT()
  return (
    <div className="row stat-row">
      <span>{t.stats.commonType}</span>
      {type ? (
        <span className="stat-value">
          <EntryBadge type={type} size={28} />
          <b>{bristolLabel(type)}</b>
        </span>
      ) : (
        <span className="muted">—</span>
      )}
    </div>
  )
}

/** Every number, plain and exact, in one soft panel: label left, value right. */
export function StatsPanel({ stats, commonType }: { stats: PoopStats; commonType: BristolType | null }) {
  const t = useT()
  const interval = StatsFormat.interval(stats.averageIntervalDays)
  const times = t.units.times
  const rows: [string, string, string][] = [
    [t.stats.averageInterval, interval.value, interval.unit],
    [t.stats.perDayAll, StatsFormat.perDay(stats.averagePerDay), stats.averagePerDay === null ? '' : times(2)],
    [t.stats.perDay30, StatsFormat.perDay(stats.averagePerDayLast30), stats.averagePerDayLast30 === null ? '' : times(2)],
    [t.stats.last7, String(stats.last7DaysCount), times(stats.last7DaysCount)],
    [t.stats.last30, String(stats.last30DaysCount), times(stats.last30DaysCount)],
    [t.stats.total, String(stats.totalCount), times(stats.totalCount)],
  ]
  return (
    <div className="panel rows">
      {rows.map(([label, value, unit]) => (
        <StatRow key={label} label={label} value={value} unit={unit} />
      ))}
      <CommonTypeRow type={commonType} />
    </div>
  )
}

/** One entry: badge, time, type label, note. */
export function EntryRow({ entry, dayStyle = false, onClick }: { entry: Entry; dayStyle?: boolean; onClick: () => void }) {
  const type = entry.bristolType
  const t = useT()
  return (
    <button type="button" className="row entry-row" onClick={onClick} aria-description={t.entry.edit}>
      <EntryBadge type={type} size={36} />
      <span className="entry-text">
        <span className="entry-line">
          <b className="num">{dayStyle ? DateText.short(entry.timestamp) : DateText.time(entry.timestamp)}</b>
          {type && (
            <span className="entry-type" style={{ color: stateVar(type) }}>
              {bristolLabel(type)}
            </span>
          )}
        </span>
        {entry.note ? (
          <span className="entry-note">{entry.note}</span>
        ) : (
          !type && <span className="entry-note">{t.entry.addDetailsHint}</span>
        )}
      </span>
      <Icon name="chevronRight" size={14} className="chevron" />
    </button>
  )
}

/** A day's round sticker. Empty past days are flat; future days are a dashed slot. */
export function DaySticker({
  count,
  isFuture,
  isToday = false,
  isSelected = false,
  children,
}: {
  count: number
  isFuture: boolean
  isToday?: boolean
  isSelected?: boolean
  children?: ReactNode
}) {
  const level = isFuture ? 'future' : `c${Math.min(count, 3)}`
  const tilt = count > 0 && !isFuture ? ((count * 7) % 9) - 4 : 0
  return (
    <span className={`day-sticker ${level}${isSelected ? ' selected' : isToday ? ' today' : ''}`}>
      <span className="day-face" style={{ transform: `rotate(${tilt}deg)` }} />
      <span className="day-label">{children}</span>
    </span>
  )
}

/** Bottom sheet with an iOS-style header: cancel, title, primary action. */
export function Sheet({
  title,
  onClose,
  leading,
  trailing,
  children,
  labelledBy,
}: {
  title: string
  onClose: () => void
  leading?: ReactNode
  trailing?: ReactNode
  children: ReactNode
  labelledBy?: string
}) {
  const ref = useRef<HTMLDivElement>(null)
  useEffect(() => {
    const previous = document.activeElement as HTMLElement | null
    ref.current?.focus()
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose()
    }
    document.addEventListener('keydown', onKey)
    document.body.classList.add('sheet-open')
    return () => {
      document.removeEventListener('keydown', onKey)
      document.body.classList.remove('sheet-open')
      previous?.focus?.()
    }
  }, [onClose])
  const titleId = labelledBy ?? `sheet-${title}`
  return (
    <div className="sheet-backdrop" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="sheet" role="dialog" aria-modal="true" aria-labelledby={titleId} tabIndex={-1} ref={ref}>
        <header className="sheet-header">
          <div className="sheet-side">{leading}</div>
          <h1 id={titleId}>{title}</h1>
          <div className="sheet-side end">{trailing}</div>
        </header>
        <div className="sheet-body">{children}</div>
      </div>
    </div>
  )
}

/** Centered alert with an optional body (e.g. a password field) and actions. */
export function AlertDialog({
  title,
  children,
  actions,
  onDismiss,
}: {
  title: string
  children?: ReactNode
  actions: ReactNode
  onDismiss: () => void
}) {
  const ref = useRef<HTMLDivElement>(null)
  useEffect(() => {
    const first = ref.current?.querySelector<HTMLElement>('input, button')
    first?.focus()
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.stopPropagation()
        onDismiss()
      }
    }
    document.addEventListener('keydown', onKey, true)
    return () => document.removeEventListener('keydown', onKey, true)
  }, [onDismiss])
  return (
    <div className="confirm-backdrop center">
      <div className="alert" role="alertdialog" aria-modal="true" aria-labelledby="alert-title" ref={ref}>
        <h2 id="alert-title">{title}</h2>
        {children}
        <div className="alert-actions">{actions}</div>
      </div>
    </div>
  )
}

/** Action-sheet style confirmation, e.g. before deleting. */
export function ConfirmDialog({
  message,
  confirmLabel,
  onConfirm,
  onCancel,
}: {
  message: string
  confirmLabel: string
  onConfirm: () => void
  onCancel: () => void
}) {
  const confirmRef = useRef<HTMLButtonElement>(null)
  const t = useT()
  useEffect(() => {
    confirmRef.current?.focus()
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.stopPropagation()
        onCancel()
      }
    }
    document.addEventListener('keydown', onKey, true)
    return () => document.removeEventListener('keydown', onKey, true)
  }, [onCancel])
  return (
    <div className="confirm-backdrop" onClick={(e) => e.target === e.currentTarget && onCancel()}>
      <div className="confirm" role="alertdialog" aria-modal="true" aria-label={message}>
        <div className="confirm-group">
          <p>{message}</p>
          <button type="button" className="confirm-danger" ref={confirmRef} onClick={onConfirm}>
            {confirmLabel}
          </button>
        </div>
        <button type="button" className="confirm-cancel" onClick={onCancel}>
          {t.entry.cancel}
        </button>
      </div>
    </div>
  )
}
