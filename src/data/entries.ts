import { openDB, type DBSchema, type IDBPDatabase } from 'idb'
import { useSyncExternalStore } from 'react'
import { makeMergePlan, type BackupEntry, type BackupFile, type MergePlan } from '../logic/backup'
import { asBristol, type BristolType } from '../logic/bristol'
import type { Millis } from '../logic/dates'
import { demoEntries } from './demo'

export interface Entry {
  id: string
  timestamp: Millis
  createdAt: Millis
  bristolType?: BristolType
  note?: string
}

interface PooPalDB extends DBSchema {
  entries: {
    key: string
    value: Entry
    indexes: { timestamp: number }
  }
}

/** `?demo` opens a throwaway database seeded with sample data (screenshots, trying things out). */
export const isDemo = new URLSearchParams(location.search).has('demo')
const DB_NAME = isDemo ? 'poopal-demo' : 'poopal'

let dbPromise: Promise<IDBPDatabase<PooPalDB>> | null = null

function db(): Promise<IDBPDatabase<PooPalDB>> {
  dbPromise ??= openDB<PooPalDB>(DB_NAME, 1, {
    upgrade(database) {
      const store = database.createObjectStore('entries', { keyPath: 'id' })
      store.createIndex('timestamp', 'timestamp')
    },
  })
  return dbPromise
}

function newId(): string {
  if (typeof crypto !== 'undefined' && 'randomUUID' in crypto) return crypto.randomUUID()
  return `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 10)}`
}

export function cleanNote(note?: string | null): string | undefined {
  const trimmed = note?.trim()
  return trimmed ? trimmed : undefined
}

export function makeEntry(timestamp: Millis, bristolType?: number | null, note?: string | null): Entry {
  const entry: Entry = { id: newId(), timestamp, createdAt: Date.now() }
  const type = asBristol(bristolType)
  if (type !== undefined) entry.bristolType = type
  const text = cleanNote(note)
  if (text !== undefined) entry.note = text
  return entry
}

// MARK: in-memory snapshot shared by all components

interface Snapshot {
  entries: Entry[]
  loaded: boolean
  error: string | null
}

let snapshot: Snapshot = { entries: [], loaded: false, error: null }
const listeners = new Set<() => void>()
const channel = typeof BroadcastChannel !== 'undefined' ? new BroadcastChannel(`poopal-${DB_NAME}`) : null

function publish(entries: Entry[]) {
  snapshot = { entries: [...entries].sort((a, b) => b.timestamp - a.timestamp), loaded: true, error: null }
  listeners.forEach((l) => l())
}

async function reload() {
  try {
    publish(await (await db()).getAll('entries'))
  } catch (error) {
    snapshot = { ...snapshot, loaded: true, error: error instanceof Error ? error.message : String(error) }
    listeners.forEach((l) => l())
  }
}

channel?.addEventListener('message', () => void reload())

async function changed() {
  await reload()
  channel?.postMessage('changed')
  requestPersistence()
}

let askedPersistence = false
/** Ask the browser not to evict our data under storage pressure (granted automatically for installed PWAs). */
function requestPersistence() {
  if (askedPersistence || !navigator.storage?.persist) return
  askedPersistence = true
  void navigator.storage.persist()
}

export async function initEntries() {
  if (isDemo) {
    const database = await db()
    const tx = database.transaction('entries', 'readwrite')
    await tx.store.clear()
    for (const entry of demoEntries()) await tx.store.put(entry)
    await tx.done
  }
  await reload()
}

export function useEntries(): Snapshot {
  return useSyncExternalStore(
    (listener) => {
      listeners.add(listener)
      return () => listeners.delete(listener)
    },
    () => snapshot,
  )
}

export function latestEntryDate(): Millis | null {
  return snapshot.entries[0]?.timestamp ?? null
}

export async function addEntry(entry: Entry) {
  await (await db()).put('entries', entry)
  await changed()
}

export async function updateEntry(entry: Entry) {
  await (await db()).put('entries', entry)
  await changed()
}

export async function deleteEntry(id: string) {
  await (await db()).delete('entries', id)
  await changed()
}

export function toBackupEntry(entry: Entry): BackupEntry {
  const out: BackupEntry = { timestamp: entry.timestamp }
  if (entry.bristolType !== undefined) out.bristolType = entry.bristolType
  const note = cleanNote(entry.note)
  if (note !== undefined) out.note = note
  return out
}

export async function allBackupEntries(): Promise<BackupEntry[]> {
  const entries = await (await db()).getAll('entries')
  return entries.map(toBackupEntry)
}

/** Merges a backup into the database: new entries are added, matches only gain missing details. */
export async function importBackup(file: BackupFile): Promise<MergePlan> {
  const database = await db()
  const existing = await database.getAll('entries')
  const plan = makeMergePlan(existing.map(toBackupEntry), file.entries)
  const tx = database.transaction('entries', 'readwrite')
  for (const entry of plan.inserts) {
    await tx.store.put(makeEntry(entry.timestamp, entry.bristolType, entry.note))
  }
  for (const fill of plan.fills) {
    const target = { ...existing[fill.existingIndex] }
    const type = asBristol(fill.bristolType)
    if (type !== undefined) target.bristolType = type
    if (fill.note !== undefined) target.note = cleanNote(fill.note)
    await tx.store.put(target)
  }
  await tx.done
  await changed()
  return plan
}
