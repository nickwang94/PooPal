import { describe, expect, it } from 'vitest'
import { BackupError, backupFileName, mergeSummary } from '../logic/backup'
import { bristolInfo, bristolLabel } from '../logic/bristol'
import { DateText } from '../logic/dates'
import { inactivityMessage, planReminders, DEFAULT_REMINDERS } from '../logic/reminders'
import { moodMessage, StatsFormat } from '../logic/stats'
import { currentLanguage, LANGUAGES, messagesFor, resolveSystemLanguage, setLanguagePreference, type Messages } from '.'

const date = (y: number, m: number, d: number, h = 9, min = 0) => new Date(y, m - 1, d, h, min).getTime()

/** Every leaf path of a messages object, with arrays and functions as leaves. */
function shape(value: unknown, prefix = ''): string[] {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    return [`${prefix}:${Array.isArray(value) ? `array${value.length}` : typeof value}`]
  }
  return Object.entries(value).flatMap(([key, v]) => shape(v, prefix ? `${prefix}.${key}` : key))
}

describe('resolveSystemLanguage', () => {
  it('uses the first supported language in the preference list', () => {
    expect(resolveSystemLanguage(['ja-JP', 'en-US'])).toBe('ja')
    expect(resolveSystemLanguage(['fr-FR', 'en-GB', 'zh-CN'])).toBe('en')
    expect(resolveSystemLanguage(['de', 'zh-Hans-CN'])).toBe('zh')
  })

  it('maps every Chinese variant to Simplified Chinese', () => {
    expect(resolveSystemLanguage(['zh-TW'])).toBe('zh')
    expect(resolveSystemLanguage(['zh_HK'])).toBe('zh')
    expect(resolveSystemLanguage(['ZH'])).toBe('zh')
  })

  it('falls back to English', () => {
    expect(resolveSystemLanguage(['fr-FR', 'ko-KR'])).toBe('en')
    expect(resolveSystemLanguage([])).toBe('en')
    expect(resolveSystemLanguage(undefined)).toBe('en')
  })
})

describe('dictionaries', () => {
  it('all have the same keys, array lengths and value kinds', () => {
    const reference = shape(messagesFor('zh'))
    for (const language of LANGUAGES) expect(shape(messagesFor(language))).toEqual(reference)
  })

  it('have no blank strings', () => {
    const strings = (value: unknown): string[] =>
      typeof value === 'string'
        ? [value]
        : typeof value === 'object' && value !== null
          ? Object.values(value).flatMap(strings)
          : []
    for (const language of LANGUAGES) {
      for (const text of strings(messagesFor(language) as Messages)) expect(text.trim()).not.toBe('')
    }
  })

  it('switching language takes effect immediately', () => {
    setLanguagePreference('ja')
    expect(currentLanguage()).toBe('ja')
    setLanguagePreference('en')
    expect(currentLanguage()).toBe('en')
  })
})

describe('English', () => {
  it('formats dates and weekdays', () => {
    setLanguagePreference('en')
    const now = date(2026, 11, 17, 12)
    expect(DateText.header(date(2026, 11, 2))).toBe('Monday, Nov 2')
    expect(DateText.month(date(2026, 11, 2))).toBe('November 2026')
    expect(DateText.weekdayHeaders()).toEqual(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'])
    expect(DateText.dayTitle(date(2026, 11, 17, 8), now)).toBe('Today')
    expect(DateText.short(date(2026, 11, 16, 21, 10), now)).toBe('Yesterday 21:10')
    expect(DateText.short(date(2026, 11, 2, 8, 30), now)).toBe('Nov 2 08:30')
    expect(DateText.greeting(date(2026, 11, 17, 7))).toBe('Good morning')
  })

  it('pluralizes units', () => {
    setLanguagePreference('en')
    const t = date(2026, 11, 17, 12)
    expect(StatsFormat.elapsed(t - 20 * 60_000, t)).toBe('just now')
    expect(StatsFormat.elapsed(t - 1.5 * 3_600_000, t)).toBe('1 hour')
    expect(StatsFormat.elapsed(t - 73 * 3_600_000, t)).toBe('3 days')
    expect(StatsFormat.interval(1.5)).toEqual({ value: '1.5', unit: 'days' })
    expect(StatsFormat.interval(1 / 24)).toEqual({ value: '1', unit: 'hour' })
  })

  it('translates Bristol types, reminders and backups', () => {
    setLanguagePreference('en')
    expect(bristolLabel(4)).toBe('Type 4 · Smooth log')
    expect(bristolInfo(1).group).toBe('Dry')
    expect(inactivityMessage(date(2026, 11, 13, 23), date(2026, 11, 16, 10)).title).toBe('No poop logged for 3 days')
    const plan = planReminders({ ...DEFAULT_REMINDERS, dailyEnabled: true, dailyMinutes: 18 * 60 }, null, {}, date(2026, 11, 14, 19))
    expect(plan.due[0].title).toBe('Have you gone today?')
    expect(mergeSummary({ inserts: [], fills: [], duplicates: 1 })).toBe('0 added, 1 duplicate skipped')
    expect(backupFileName(date(2026, 11, 14, 9, 5), true)).toBe('PooPal-backup-20261114-0905-encrypted.json')
    expect(new BackupError('wrongPassword').message).toBe('Wrong password, try again')
    expect(moodMessage({ kind: 'noData' })).toMatch(/^First time\?/)
  })
})

describe('Japanese', () => {
  it('formats dates and weekdays', () => {
    setLanguagePreference('ja')
    const now = date(2026, 11, 17, 12)
    expect(DateText.header(date(2026, 11, 2))).toBe('11月2日（月）')
    expect(DateText.weekdayHeaders()).toEqual(['月', '火', '水', '木', '金', '土', '日'])
    expect(DateText.dayTitle(date(2026, 11, 16), now)).toBe('昨日')
    expect(StatsFormat.elapsed(now - 5 * 3_600_000, now)).toBe('5時間')
  })

  it('translates Bristol types, reminders and backups', () => {
    setLanguagePreference('ja')
    expect(bristolLabel(4)).toBe('タイプ4・なめらか')
    expect(inactivityMessage(date(2026, 11, 13, 23), date(2026, 11, 16, 10)).title).toBe('3日間うんちの記録がありません')
    expect(mergeSummary({ inserts: [], fills: [], duplicates: 2 })).toBe('0件を追加、重複 2件をスキップ')
    expect(backupFileName(date(2026, 11, 14, 9, 5), false)).toBe('PooPal-バックアップ-20261114-0905.json')
    expect(BackupError.describe('unsupportedVersion', 3)).toContain('3')
  })
})
