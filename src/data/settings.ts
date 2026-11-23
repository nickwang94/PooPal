import { useEffect, useSyncExternalStore } from 'react'
import { DEFAULT_REMINDERS, type ReminderLog, type ReminderSettings } from '../logic/reminders'

export type Appearance = 'system' | 'light' | 'dark'

export const APPEARANCE_OPTIONS: { value: Appearance; title: string }[] = [
  { value: 'system', title: '跟随系统' },
  { value: 'light', title: '浅色' },
  { value: 'dark', title: '深色' },
]

const APPEARANCE_KEY = 'poopal.appearance'
const REMINDERS_KEY = 'poopal.reminders'
const REMINDER_LOG_KEY = 'poopal.reminders.log'

function read<T>(key: string, fallback: T): T {
  try {
    const raw = localStorage.getItem(key)
    return raw === null ? fallback : (JSON.parse(raw) as T)
  } catch {
    return fallback
  }
}

function write(key: string, value: unknown) {
  try {
    localStorage.setItem(key, JSON.stringify(value))
  } catch {
    // Private mode or full storage: settings just won't persist.
  }
}

function readAppearance(): Appearance {
  try {
    const raw = localStorage.getItem(APPEARANCE_KEY)
    return raw === 'light' || raw === 'dark' ? raw : 'system'
  } catch {
    return 'system'
  }
}

interface SettingsState {
  appearance: Appearance
  reminders: ReminderSettings
}

let state: SettingsState = {
  appearance: readAppearance(),
  reminders: { ...DEFAULT_REMINDERS, ...read<Partial<ReminderSettings>>(REMINDERS_KEY, {}) },
}
const listeners = new Set<() => void>()

function emit() {
  listeners.forEach((l) => l())
}

export function useSettings(): SettingsState {
  return useSyncExternalStore(
    (l) => {
      listeners.add(l)
      return () => listeners.delete(l)
    },
    () => state,
  )
}

export function getSettings(): SettingsState {
  return state
}

export function setAppearance(appearance: Appearance) {
  try {
    localStorage.setItem(APPEARANCE_KEY, appearance)
  } catch {
    // ignore
  }
  state = { ...state, appearance }
  emit()
}

export function updateReminders(patch: Partial<ReminderSettings>) {
  state = { ...state, reminders: { ...state.reminders, ...patch } }
  write(REMINDERS_KEY, state.reminders)
  emit()
}

export function readReminderLog(): ReminderLog {
  return read<ReminderLog>(REMINDER_LOG_KEY, {})
}

export function writeReminderLog(log: ReminderLog) {
  write(REMINDER_LOG_KEY, log)
}

const darkQuery = matchMedia('(prefers-color-scheme: dark)')

/** Keeps `<html data-theme>` and the browser chrome color in sync with the appearance setting. */
export function useApplyAppearance(appearance: Appearance) {
  useEffect(() => {
    const apply = () => {
      const dark = appearance === 'dark' || (appearance === 'system' && darkQuery.matches)
      document.documentElement.dataset.theme = dark ? 'dark' : 'light'
      document.querySelector('meta[name="theme-color"]')?.setAttribute('content', dark ? '#1C1620' : '#FFF8F0')
    }
    apply()
    darkQuery.addEventListener('change', apply)
    return () => darkQuery.removeEventListener('change', apply)
  }, [appearance])
}

const motionQuery = matchMedia('(prefers-reduced-motion: reduce)')

export function useReducedMotion(): boolean {
  return useSyncExternalStore(
    (l) => {
      motionQuery.addEventListener('change', l)
      return () => motionQuery.removeEventListener('change', l)
    },
    () => motionQuery.matches,
  )
}

export function prefersReducedMotion(): boolean {
  return motionQuery.matches
}
