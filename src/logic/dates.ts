/** Epoch milliseconds. All calendar math uses the device's local time zone. */
export type Millis = number

const DAY_MS = 86_400_000

/** Weeks start on Monday, as in the zh-CN calendar. */
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

export function pad(n: number): string {
  return String(n).padStart(2, '0')
}

const WEEKDAYS = ['日', '一', '二', '三', '四', '五', '六']

/** Text helpers mirroring the iOS `DateText`. */
export const DateText = {
  /** "11月2日 星期一" */
  header(t: Millis): string {
    const d = new Date(t)
    return `${d.getMonth() + 1}月${d.getDate()}日 星期${WEEKDAYS[d.getDay()]}`
  },
  /** "08:30" */
  time(t: Millis): string {
    const d = new Date(t)
    return `${pad(d.getHours())}:${pad(d.getMinutes())}`
  },
  /** "2026年11月" */
  month(t: Millis): string {
    const d = new Date(t)
    return `${d.getFullYear()}年${d.getMonth() + 1}月`
  },
  /** "11月2日" */
  monthDay(t: Millis): string {
    const d = new Date(t)
    return `${d.getMonth() + 1}月${d.getDate()}日`
  },
  greeting(t: Millis): string {
    const h = new Date(t).getHours()
    if (h >= 5 && h < 11) return '早上好'
    if (h >= 11 && h < 14) return '中午好'
    if (h >= 14 && h < 18) return '下午好'
    if (h >= 18 && h < 23) return '晚上好'
    return '夜深了'
  },
  /** Single-character weekday: "一" … "日". */
  weekdayShort(t: Millis): string {
    return WEEKDAYS[new Date(t).getDay()]
  },
  /** Weekday column headers in calendar order. */
  weekdayHeaders(): string[] {
    return Array.from({ length: 7 }, (_, i) => WEEKDAYS[(WEEK_STARTS_ON + i) % 7])
  },
  /** "今天" / "昨天" / "11月2日 星期一" */
  dayTitle(t: Millis, now: Millis = Date.now()): string {
    const diff = calendarDaysBetween(t, now)
    if (diff === 0) return '今天'
    if (diff === 1) return '昨天'
    return DateText.header(t)
  },
  /** "今天 08:30" / "昨天 21:10" / "11月2日 08:30" */
  short(t: Millis, now: Millis = Date.now()): string {
    const diff = calendarDaysBetween(t, now)
    if (diff === 0) return `今天 ${DateText.time(t)}`
    if (diff === 1) return `昨天 ${DateText.time(t)}`
    return `${DateText.monthDay(t)} ${DateText.time(t)}`
  },
}
