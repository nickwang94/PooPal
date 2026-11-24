import { useCallback, useState } from 'react'
import { BristolPicker } from '../components/Bristol'
import { ConfirmDialog, PickerPill, Sheet } from '../components/ui'
import { addEntry, cleanNote, deleteEntry, makeEntry, updateEntry, type Entry } from '../data/entries'
import { messages, useT } from '../i18n'
import type { BristolType } from '../logic/bristol'
import { addDays, atTime, dayKey, pad } from '../logic/dates'

interface Props {
  entry?: Entry
  onClose: () => void
}

function timeValue(t: number) {
  const d = new Date(t)
  return `${pad(d.getHours())}:${pad(d.getMinutes())}`
}

/** "2026-11-17" → "2026年11月17日" / "Nov 17, 2026" */
function dateDisplay(value: string) {
  const [y, m, d] = value.split('-').map(Number)
  return messages().date.fullDate(y, m, d)
}

function combine(date: string, time: string): number | null {
  const [y, m, d] = date.split('-').map(Number)
  const [h, min] = time.split(':').map(Number)
  if ([y, m, d, h, min].some((n) => n === undefined || Number.isNaN(n))) return null
  return new Date(y, m - 1, d, h, min).getTime()
}

/** Add a past entry (`entry` undefined) or edit one: time, Bristol type, note. */
export function EntryEditor({ entry, onClose }: Props) {
  const isEditing = entry !== undefined
  const [openedAt] = useState(() => Date.now())
  const initial = Math.min(entry?.timestamp ?? openedAt, openedAt)
  const [date, setDate] = useState(dayKey(initial))
  const [time, setTime] = useState(timeValue(initial))
  const [type, setType] = useState<BristolType | undefined>(entry?.bristolType)
  const [note, setNote] = useState(entry?.note ?? '')
  const [confirmingDelete, setConfirmingDelete] = useState(false)
  const [busy, setBusy] = useState(false)
  const t = useT()

  const setFrom = (t: number) => {
    const clamped = Math.min(t, Date.now())
    setDate(dayKey(clamped))
    setTime(timeValue(clamped))
  }

  const save = async () => {
    const chosen = combine(date, time)
    if (chosen === null || busy) return
    setBusy(true)
    const timestamp = Math.min(chosen, Date.now())
    if (entry) {
      const next: Entry = { ...entry, timestamp, bristolType: type, note: cleanNote(note) }
      if (next.bristolType === undefined) delete next.bristolType
      if (next.note === undefined) delete next.note
      await updateEntry(next)
    } else {
      await addEntry(makeEntry(timestamp, type, note))
    }
    onClose()
  }

  const remove = async () => {
    if (!entry) return
    await deleteEntry(entry.id)
    onClose()
  }

  const cancelDelete = useCallback(() => setConfirmingDelete(false), [])

  return (
    <Sheet
      title={isEditing ? t.entry.titleEdit : t.entry.titleAdd}
      onClose={onClose}
      leading={
        <button type="button" className="pill-button" onClick={onClose}>
          {t.entry.cancel}
        </button>
      }
      trailing={
        <button type="button" className="pill-button strong" onClick={save} disabled={busy}>
          {isEditing ? t.entry.save : t.entry.saveNew}
        </button>
      }
    >
      <div className="form-group">
        <div className="row time-row">
          <span>{t.entry.time}</span>
          <span className="time-inputs">
            <PickerPill type="date" label={t.entry.date} value={date} display={dateDisplay(date)} max={dayKey(openedAt)} onChange={setDate} />
            <PickerPill type="time" label={t.entry.clock} value={time} display={time} onChange={setTime} />
          </span>
        </div>
        {!isEditing && (
          <div className="row chips">
            <button type="button" className="chip" onClick={() => setFrom(Date.now() - 3_600_000)}>
              {t.entry.hourAgo}
            </button>
            <button type="button" className="chip" onClick={() => setFrom(atTime(Date.now(), 8))}>
              {t.entry.thisMorning}
            </button>
            <button type="button" className="chip" onClick={() => setFrom(atTime(addDays(Date.now(), -1), 22))}>
              {t.entry.lastNight}
            </button>
          </div>
        )}
      </div>

      <h2 className="form-header">{t.entry.shapeHeader}</h2>
      <div className="form-group padded">
        <BristolPicker value={type} onChange={setType} />
      </div>

      <h2 className="form-header">
        <label htmlFor="note">{t.entry.noteHeader}</label>
      </h2>
      <div className="form-group">
        <textarea
          id="note"
          className="note-input"
          rows={3}
          maxLength={500}
          placeholder={t.entry.notePlaceholder}
          value={note}
          onChange={(e) => setNote(e.target.value)}
        />
      </div>

      {isEditing && (
        <div className="form-group">
          <button type="button" className="row danger-row" onClick={() => setConfirmingDelete(true)}>
            {t.entry.delete}
          </button>
        </div>
      )}

      {confirmingDelete && (
        <ConfirmDialog message={t.entry.deleteMessage} confirmLabel={t.entry.deleteConfirm} onConfirm={remove} onCancel={cancelDelete} />
      )}
    </Sheet>
  )
}
