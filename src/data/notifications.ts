import { dayKey } from '../logic/dates'
import { planReminders } from '../logic/reminders'
import { latestEntryDate } from './entries'
import { getSettings, readReminderLog, writeReminderLog } from './settings'

export type NotificationSupport = 'unsupported' | 'default' | 'granted' | 'denied'

export function notificationSupport(): NotificationSupport {
  if (typeof Notification === 'undefined' || !('serviceWorker' in navigator)) return 'unsupported'
  return Notification.permission
}

/** Must be called from a user gesture (Safari requires it). */
export async function requestNotificationPermission(): Promise<NotificationSupport> {
  if (notificationSupport() === 'unsupported') return 'unsupported'
  try {
    return await Notification.requestPermission()
  } catch {
    return notificationSupport()
  }
}

export function isStandalone(): boolean {
  return (
    matchMedia('(display-mode: standalone)').matches ||
    (navigator as Navigator & { standalone?: boolean }).standalone === true
  )
}

async function show(title: string, body: string, tag: string) {
  const options: NotificationOptions = { body, tag, icon: `${import.meta.env.BASE_URL}icons/icon-192.png` }
  const registration = await navigator.serviceWorker.getRegistration()
  if (registration) {
    await registration.showNotification(title, options)
  } else {
    new Notification(title, options)
  }
}

let timer: ReturnType<typeof setTimeout> | undefined

/**
 * Best-effort reminders. Browsers can't schedule a local notification for later without a push
 * server, so this checks whenever PooPal is open or comes back to the foreground, and keeps a timer
 * for the next due time while the page stays alive.
 */
export async function checkReminders(now = Date.now()) {
  clearTimeout(timer)
  if (notificationSupport() !== 'granted') return
  const log = readReminderLog()
  const plan = planReminders(getSettings().reminders, latestEntryDate(), log, now)
  for (const reminder of plan.due) {
    try {
      await show(reminder.title, reminder.body, `poopal-${reminder.id}`)
      log[reminder.id] = dayKey(now)
    } catch {
      // Notification blocked or SW unavailable; try again next time.
    }
  }
  writeReminderLog(log)
  if (plan.nextCheck !== null) {
    const delay = Math.min(Math.max(plan.nextCheck - Date.now(), 1000), 2 ** 31 - 1)
    timer = setTimeout(() => void checkReminders(), delay)
  }
}
