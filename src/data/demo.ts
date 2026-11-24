import { messages } from '../i18n'
import { asBristol } from '../logic/bristol'
import { addDays, atTime, startOfDay } from '../logic/dates'
import type { Entry } from './entries'

/** The same deterministic sample pattern as the iOS `-demoData` mode: 12 weeks, mostly once a day. */
export function demoEntries(now = Date.now()): Entry[] {
  const today = startOfDay(now)
  const types = [4, 3, 4, 5, 4, 2, 4, 6, 3, 4, 4, 1, 3, 4, 5]
  const notes = messages().demoNotes
  const entries: Entry[] = []
  for (let day = 0; day < 84; day++) {
    const pattern = (day * 7 + Math.floor(day / 5)) % 9
    const times = day === 0 ? 1 : pattern === 0 || pattern === 4 ? 0 : pattern === 7 ? 2 : 1
    for (let index = 0; index < times; index++) {
      const timestamp = atTime(addDays(today, -day), index === 0 ? 8 : 20, 10 + (day % 40))
      if (timestamp > now) continue
      const entry: Entry = { id: `demo-${day}-${index}`, timestamp, createdAt: timestamp }
      const type = day % 5 === 3 ? undefined : asBristol(types[(day + index) % types.length])
      if (type !== undefined) entry.bristolType = type
      const note = index === 0 ? notes[day] : undefined
      if (note) entry.note = note
      entries.push(entry)
    }
  }
  return entries
}
