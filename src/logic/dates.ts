import { messages } from '../i18n'
import { pad } from './pad'

/** Epoch milliseconds. All calendar math uses the device's local time zone. */
export type Millis = number

const DAY_MS = 86_400_000

/** Weeks start on Monday (ISO 8601) in every language, so weekly stats don't shift when the language changes. */
export const WEEK_STARTS_ON = 1

export function startOfDay(t: Millis): Millis {
  const d = new Date(t)
  d.setHours(0, 0, 0, 0)
  return d.getTime()
}

export function addDays(t: Millis, days: number): Millis {
  const d = new Date(t)
  d.setDate(d.getDate() + days)
  return d.getTime()
}

export function addMonths(t: Millis, months: number): Millis {
  const d = new Date(t)
  d.setMonth(d.getMonth() + months)
  return d.getTime()
}

export function startOfWeek(t: Millis): Millis {
  const day = startOfDay(t)
  const offset = (new Date(day).getDay() - WEEK_STARTS_ON + 7) % 7
  return addDays(day, -offset)
}

export function startOfMonth(t: Millis): Millis {
  const d = new Date(t)
  return new Date(d.getFullYear(), d.getMonth(), 1).getTime()
}

/** `t` on the same day at `hour:minute:00`. */
export function atTime(t: Millis, hour: number, minute = 0): Millis {
  const d = new Date(t)
  d.setHours(hour, minute, 0, 0)
  return d.getTime()
}

/** Whole calendar days from `a`'s day to `b`'s day (DST-safe). */
export function calendarDaysBetween(a: Millis, b: Millis): number {
  return Math.round((startOfDay(b) - startOfDay(a)) / DAY_MS)
}

export function isSameDay(a: Millis, b: Millis): boolean {
  return startOfDay(a) === startOfDay(b)
}

export function daysInMonth(t: Millis): number {
  const d = new Date(t)
  return new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate()
}

/** "2026-11-17" in local time; stable key for a calendar day. */
export function dayKey(t: Millis): string {
  const d = new Date(t)
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
}

export { pad }

/** Text helpers mirroring the iOS `DateText`, in the current UI language. */
export const DateText = {
  /** "11月2日 星期一" / "Monday, Nov 2" / "11月2日（月）" */
  header(t: Millis): string {
    return messages().date.header(new Date(t))
  },
  /** "08:30" */
  time(t: Millis): string {
    return messages().date.time(new Date(t))
  },
  /** "2026年11月" / "November 2026" */
  month(t: Millis): string {
    return messages().date.month(new Date(t))
  },
  /** "11月2日" / "Nov 2" */
  monthDay(t: Millis): string {
    return messages().date.monthDay(new Date(t))
  },
  greeting(t: Millis): string {
    const g = messages().date.greeting
    const h = new Date(t).getHours()
    if (h >= 5 && h < 11) return g.morning
    if (h >= 11 && h < 14) return g.noon
    if (h >= 14 && h < 18) return g.afternoon
    if (h >= 18 && h < 23) return g.evening
    return g.night
  },
  /** Short weekday: "一" / "Mon" / "月". */
  weekdayShort(t: Millis): string {
    return messages().date.weekdayShort[new Date(t).getDay()]
  },
  /** Weekday column headers in calendar order. */
  weekdayHeaders(): string[] {
    const names = messages().date.weekdayShort
    return Array.from({ length: 7 }, (_, i) => names[(WEEK_STARTS_ON + i) % 7])
  },
  /** "今天" / "昨天" / "11月2日 星期一" */
  dayTitle(t: Millis, now: Millis = Date.now()): string {
    const diff = calendarDaysBetween(t, now)
    if (diff === 0) return messages().date.today
    if (diff === 1) return messages().date.yesterday
    return DateText.header(t)
  },
  /** "今天 08:30" / "昨天 21:10" / "11月2日 08:30" */
  short(t: Millis, now: Millis = Date.now()): string {
    const diff = calendarDaysBetween(t, now)
    if (diff === 0) return `${messages().date.today} ${DateText.time(t)}`
    if (diff === 1) return `${messages().date.yesterday} ${DateText.time(t)}`
    return `${DateText.monthDay(t)} ${DateText.time(t)}`
  },
}
