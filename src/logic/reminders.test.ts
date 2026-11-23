import { describe, expect, it } from 'vitest'
import {
  dailyComponents,
  DEFAULT_REMINDERS,
  inactivityFireDate,
  inactivityMessage,
  planReminders,
} from './reminders'

const date = (y: number, m: number, d: number, h = 9, min = 0) => new Date(y, m - 1, d, h, min).getTime()
const now = date(2026, 11, 14, 19, 0)

describe('ReminderPlanner', () => {
  it('fires on the Nth day after the last entry', () => {
    expect(inactivityFireDate(date(2026, 11, 13, 21, 30), 3, 10, now)).toBe(date(2026, 11, 16, 10, 0))
  })

  it('fires next morning when already overdue', () => {
    const last = date(2026, 11, 5)
    expect(inactivityFireDate(last, 3, 10, now)).toBe(date(2026, 11, 15, 10, 0))
    expect(inactivityFireDate(last, 3, 10, date(2026, 11, 14, 7, 0))).toBe(date(2026, 11, 14, 10, 0))
  })

  it('needs an entry and positive days', () => {
    expect(inactivityFireDate(null, 3, 10, now)).toBeNull()
    expect(inactivityFireDate(now, 0, 10, now)).toBeNull()
  })

  it('counts calendar days in the message', () => {
    expect(inactivityMessage(date(2026, 11, 13, 23, 0), date(2026, 11, 16, 10, 0)).title).toBe('已经 3 天没有便便记录啦')
  })

  it('clamps daily components', () => {
    expect(dailyComponents(21 * 60 + 30)).toEqual({ hour: 21, minute: 30 })
    expect(dailyComponents(-5)).toEqual({ hour: 0, minute: 0 })
    expect(dailyComponents(9999)).toEqual({ hour: 23, minute: 59 })
  })
})

describe('planReminders (web)', () => {
  const settings = { ...DEFAULT_REMINDERS, dailyEnabled: true, dailyMinutes: 18 * 60 + 30 }

  it('shows an overdue inactivity reminder once per day', () => {
    const last = date(2026, 11, 5)
    const plan = planReminders(settings, last, {}, now)
    expect(plan.due.map((d) => d.id)).toEqual(['inactivity', 'daily'])
    expect(plan.due[0].title).toBe('已经 9 天没有便便记录啦')
    const again = planReminders(settings, last, { inactivity: '2026-11-14', daily: '2026-11-14' }, now)
    expect(again.due).toEqual([])
  })

  it('waits for 10:00 before an overdue inactivity reminder', () => {
    const plan = planReminders(DEFAULT_REMINDERS, date(2026, 11, 5), {}, date(2026, 11, 14, 8, 0))
    expect(plan.due).toEqual([])
    expect(plan.nextCheck).toBe(date(2026, 11, 14, 10, 0))
  })

  it('drops a daily reminder missed by more than the grace period', () => {
    const plan = planReminders(settings, now, {}, date(2026, 11, 14, 21, 0))
    expect(plan.due).toEqual([])
    expect(plan.nextCheck).toBe(date(2026, 11, 15, 18, 30))
  })

  it('plans the next check from the earliest upcoming reminder', () => {
    const plan = planReminders(settings, date(2026, 11, 14, 8), {}, date(2026, 11, 14, 12, 0))
    expect(plan.due).toEqual([])
    expect(plan.nextCheck).toBe(date(2026, 11, 14, 18, 30))
  })

  it('does nothing when both reminders are off', () => {
    const off = { ...DEFAULT_REMINDERS, inactivityEnabled: false }
    expect(planReminders(off, date(2026, 11, 1), {}, now)).toEqual({ due: [], nextCheck: null })
  })
})
