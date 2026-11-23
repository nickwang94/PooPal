import { addDays, atTime, calendarDaysBetween, dayKey, startOfDay, type Millis } from './dates'

export interface ReminderSettings {
  inactivityEnabled: boolean
  inactivityDays: number
  dailyEnabled: boolean
  /** Minutes after midnight. */
  dailyMinutes: number
}

export const DEFAULT_REMINDERS: ReminderSettings = {
  inactivityEnabled: true,
  inactivityDays: 3,
  dailyEnabled: false,
  dailyMinutes: 21 * 60,
}

/** Hour of day when the "N days without a record" reminder fires. */
export const INACTIVITY_HOUR = 10

/** A daily reminder missed by more than this (app closed) is dropped rather than shown late. */
export const DAILY_GRACE_MS = 2 * 60 * 60 * 1000

/**
 * When to send the "no record for `days` days" reminder: on the `days`-th calendar day after the
 * last entry at `hour`. If that moment has already passed, the next `hour` after `now` instead.
 */
export function inactivityFireDate(
  lastEntry: Millis | null,
  days: number,
  hour = INACTIVITY_HOUR,
  now: Millis = Date.now(),
): Millis | null {
  if (lastEntry === null || days <= 0) return null
  const target = atTime(addDays(startOfDay(lastEntry), days), hour)
  if (target > now) return target
  const todayAtHour = atTime(now, hour)
  return todayAtHour > now ? todayAtHour : addDays(todayAtHour, 1)
}

export function inactivityMessage(lastEntry: Millis, fireDate: Millis): { title: string; body: string } {
  const days = calendarDaysBetween(lastEntry, fireDate)
  return {
    title: `已经 ${days} 天没有便便记录啦`,
    body: '多喝水、吃点蔬菜水果，便便了记得来 PooPal 记一笔哦',
  }
}

export const DAILY_MESSAGE = { title: '今天便便了吗？', body: '来 PooPal 点一下，记录今天的肠道小日记吧' }

export function dailyComponents(minutes: number): { hour: number; minute: number } {
  const clamped = Math.min(Math.max(Math.round(minutes), 0), 24 * 60 - 1)
  return { hour: Math.floor(clamped / 60), minute: clamped % 60 }
}

/** Day keys of the last time each reminder was shown, so each fires at most once a day. */
export interface ReminderLog {
  inactivity?: string
  daily?: string
}

export interface DueReminder {
  id: 'inactivity' | 'daily'
  title: string
  body: string
}

export interface ReminderPlan {
  due: DueReminder[]
  /** Next moment a reminder could become due while the app stays open. */
  nextCheck: Millis | null
}

/**
 * The web has no way to schedule a local notification for later, so PooPal checks whenever it is
 * open or comes back to the foreground: what is due now, and when to check again.
 */
export function planReminders(
  settings: ReminderSettings,
  lastEntry: Millis | null,
  log: ReminderLog,
  now: Millis = Date.now(),
): ReminderPlan {
  const today = dayKey(now)
  const due: DueReminder[] = []
  const upcoming: Millis[] = []

  if (settings.inactivityEnabled && lastEntry !== null && settings.inactivityDays > 0) {
    const target = atTime(addDays(startOfDay(lastEntry), settings.inactivityDays), INACTIVITY_HOUR)
    const todayAtHour = atTime(now, INACTIVITY_HOUR)
    if (now >= target && now >= todayAtHour && log.inactivity !== today) {
      due.push({ id: 'inactivity', ...inactivityMessage(lastEntry, now) })
    }
    const next = inactivityFireDate(lastEntry, settings.inactivityDays, INACTIVITY_HOUR, now)
    if (next !== null) upcoming.push(next)
  }

  if (settings.dailyEnabled) {
    const { hour, minute } = dailyComponents(settings.dailyMinutes)
    const todayAt = atTime(now, hour, minute)
    if (now >= todayAt && now - todayAt < DAILY_GRACE_MS && log.daily !== today) {
      due.push({ id: 'daily', ...DAILY_MESSAGE })
    }
    upcoming.push(todayAt > now ? todayAt : atTime(addDays(now, 1), hour, minute))
  }

  return { due, nextCheck: upcoming.length ? Math.min(...upcoming) : null }
}
