import { pad, type Millis } from './dates'

/**
 * Backup format shared with the iOS app (v1):
 * plain `{ app: "PooPal", version: 1, exportedAt, entries: [{ timestamp, bristolType?, note? }] }`
 * with ISO 8601 dates, or that JSON sealed with AES-256-GCM (nonce ‖ ciphertext ‖ tag, base64)
 * under a PBKDF2-SHA256 key, wrapped as `{ app, format: "encrypted", version, kdf, iterations, salt, payload }`.
 */
export interface BackupEntry {
  timestamp: Millis
  bristolType?: number
  note?: string
}

export interface BackupFile {
  app: 'PooPal'
  version: number
  exportedAt: Millis
  entries: BackupEntry[]
}

export type BackupErrorCode = 'invalidFile' | 'passwordRequired' | 'wrongPassword' | 'unsupportedVersion' | 'cryptoUnavailable'

export class BackupError extends Error {
  readonly code: BackupErrorCode
  readonly version?: number

  constructor(code: BackupErrorCode, version?: number) {
    super(BackupError.describe(code, version))
    this.name = 'BackupError'
    this.code = code
    this.version = version
  }

  static describe(code: BackupErrorCode, version?: number): string {
    switch (code) {
      case 'invalidFile':
        return '这不是 PooPal 的备份文件，或者文件已损坏'
      case 'passwordRequired':
        return '这个备份设置了密码，请输入密码'
      case 'wrongPassword':
        return '密码不对，再试一次吧'
      case 'unsupportedVersion':
        return `备份版本 ${version} 太新了，请先更新 PooPal`
      case 'cryptoUnavailable':
        return '当前浏览器不支持加密（需要 HTTPS 访问），请换用 HTTPS 地址打开 PooPal'
    }
  }
}

export const DEFAULT_ITERATIONS = 210_000
/** Refuse absurd work factors from a crafted file instead of freezing the page. */
const MAX_ITERATIONS = 10_000_000

export interface EncodeOptions {
  exportedAt?: Millis
  password?: string | null
  iterations?: number
}

export async function encodeBackup(entries: BackupEntry[], options: EncodeOptions = {}): Promise<string> {
  const { exportedAt = Date.now(), password, iterations = DEFAULT_ITERATIONS } = options
  const sorted = [...entries].sort((a, b) => a.timestamp - b.timestamp)
  const plain = stringify({
    app: 'PooPal',
    entries: sorted.map((e) => {
      const out: Record<string, unknown> = {}
      if (e.bristolType !== undefined) out.bristolType = e.bristolType
      if (e.note !== undefined) out.note = e.note
      out.timestamp = iso(e.timestamp)
      return out
    }),
    exportedAt: iso(exportedAt),
    version: 1,
  })
  if (!password) return plain

  const subtle = requireSubtle()
  const salt = crypto.getRandomValues(new Uint8Array(16))
  const nonce = crypto.getRandomValues(new Uint8Array(12))
  const key = await deriveKey(password, salt, iterations)
  const sealed = new Uint8Array(
    await subtle.encrypt({ name: 'AES-GCM', iv: nonce }, key, new TextEncoder().encode(plain)),
  )
  const combined = new Uint8Array(nonce.length + sealed.length)
  combined.set(nonce)
  combined.set(sealed, nonce.length)
  return stringify({
    app: 'PooPal',
    format: 'encrypted',
    iterations,
    kdf: 'PBKDF2-SHA256',
    payload: toBase64(combined),
    salt: toBase64(salt),
    version: 1,
  })
}

interface EncryptedWrapper {
  format: 'encrypted'
  iterations: number
  salt: string
  payload: string
}

function parseJSON(text: string): unknown {
  try {
    return JSON.parse(text)
  } catch {
    return undefined
  }
}

function asEncryptedWrapper(value: unknown): EncryptedWrapper | null {
  if (!isRecord(value) || value.format !== 'encrypted') return null
  const { app, version, kdf, iterations, salt, payload } = value
  if (
    typeof app !== 'string' ||
    typeof version !== 'number' ||
    typeof kdf !== 'string' ||
    typeof iterations !== 'number' ||
    typeof salt !== 'string' ||
    typeof payload !== 'string'
  ) {
    return null
  }
  return { format: 'encrypted', iterations, salt, payload }
}

export function isEncryptedBackup(text: string): boolean {
  return asEncryptedWrapper(parseJSON(text)) !== null
}

export async function decodeBackup(text: string, password?: string | null): Promise<BackupFile> {
  let plain = text
  const wrapper = asEncryptedWrapper(parseJSON(text))
  if (wrapper) {
    if (!password) throw new BackupError('passwordRequired')
    const subtle = requireSubtle()
    let salt: Uint8Array
    let combined: Uint8Array
    try {
      salt = fromBase64(wrapper.salt)
      combined = fromBase64(wrapper.payload)
    } catch {
      throw new BackupError('invalidFile')
    }
    if (!Number.isInteger(wrapper.iterations) || wrapper.iterations <= 0 || wrapper.iterations > MAX_ITERATIONS) {
      throw new BackupError('invalidFile')
    }
    const key = await deriveKey(password, salt, wrapper.iterations)
    try {
      const opened = await subtle.decrypt(
        { name: 'AES-GCM', iv: combined.slice(0, 12) },
        key,
        combined.slice(12),
      )
      plain = new TextDecoder().decode(opened)
    } catch {
      throw new BackupError('wrongPassword')
    }
  }

  const file = parsePlain(parseJSON(plain))
  if (file.app !== 'PooPal') throw new BackupError('invalidFile')
  if (file.version > 1) throw new BackupError('unsupportedVersion', file.version)
  return file as BackupFile
}

function parsePlain(value: unknown): { app: string; version: number; exportedAt: Millis; entries: BackupEntry[] } {
  const invalid = () => new BackupError('invalidFile')
  if (!isRecord(value)) throw invalid()
  const { app, version, exportedAt, entries } = value
  if (typeof app !== 'string' || !Number.isInteger(version) || !Array.isArray(entries)) throw invalid()
  const exported = parseDate(exportedAt)
  if (exported === null) throw invalid()
  const parsed = entries.map((raw): BackupEntry => {
    if (!isRecord(raw)) throw invalid()
    const timestamp = parseDate(raw.timestamp)
    if (timestamp === null) throw invalid()
    const entry: BackupEntry = { timestamp }
    if (raw.bristolType !== undefined && raw.bristolType !== null) {
      if (!Number.isInteger(raw.bristolType)) throw invalid()
      entry.bristolType = raw.bristolType as number
    }
    if (raw.note !== undefined && raw.note !== null) {
      if (typeof raw.note !== 'string') throw invalid()
      entry.note = raw.note
    }
    return entry
  })
  return { app, version: version as number, exportedAt: exported, entries: parsed }
}

/** ISO 8601 with or without fractional seconds, `Z` or a numeric offset. */
const ISO_PATTERN = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:?\d{2})$/

function parseDate(value: unknown): Millis | null {
  if (typeof value !== 'string' || !ISO_PATTERN.test(value)) return null
  const t = Date.parse(value)
  return Number.isNaN(t) ? null : t
}

/** "PooPal-备份-20261114-0905.json" in local time. */
export function backupFileName(date: Millis = Date.now(), encrypted: boolean): string {
  const d = new Date(date)
  const stamp = `${d.getFullYear()}${pad(d.getMonth() + 1)}${pad(d.getDate())}-${pad(d.getHours())}${pad(d.getMinutes())}`
  return `PooPal-备份-${stamp}${encrypted ? '-加密' : ''}.json`
}

/** Entries are matched by timestamp, to the second. */
export function entryKey(timestamp: Millis): number {
  return Math.floor(timestamp / 1000)
}

export interface MergeFill {
  existingIndex: number
  bristolType?: number
  note?: string
}

export interface MergePlan {
  inserts: BackupEntry[]
  fills: MergeFill[]
  duplicates: number
}

const isBlank = (text?: string | null) => !text || text.trim() === ''

/** How an import changes existing data. Matches are never overwritten; they only gain a missing type / note. */
export function makeMergePlan(existing: BackupEntry[], incoming: BackupEntry[]): MergePlan {
  const plan: MergePlan = { inserts: [], fills: [], duplicates: 0 }
  const indexByKey = new Map<number, number>()
  existing.forEach((entry, index) => {
    const key = entryKey(entry.timestamp)
    if (!indexByKey.has(key)) indexByKey.set(key, index)
  })
  const seenIncoming = new Set<number>()

  for (const entry of [...incoming].sort((a, b) => a.timestamp - b.timestamp)) {
    const key = entryKey(entry.timestamp)
    if (seenIncoming.has(key)) {
      plan.duplicates += 1
      continue
    }
    seenIncoming.add(key)
    const index = indexByKey.get(key)
    if (index === undefined) {
      plan.inserts.push(entry)
      continue
    }
    const current = existing[index]
    const validType =
      entry.bristolType !== undefined && entry.bristolType >= 1 && entry.bristolType <= 7 ? entry.bristolType : undefined
    const newType = current.bristolType === undefined ? validType : undefined
    const newNote = isBlank(current.note) && !isBlank(entry.note) ? entry.note : undefined
    if (newType !== undefined || newNote !== undefined) {
      const fill: MergeFill = { existingIndex: index }
      if (newType !== undefined) fill.bristolType = newType
      if (newNote !== undefined) fill.note = newNote
      plan.fills.push(fill)
    } else {
      plan.duplicates += 1
    }
  }
  return plan
}

export function mergeSummary(plan: MergePlan): string {
  const parts = [`新增 ${plan.inserts.length} 条`]
  if (plan.fills.length > 0) parts.push(`补充 ${plan.fills.length} 条的形态或备注`)
  parts.push(`跳过 ${plan.duplicates} 条重复`)
  return parts.join('，')
}

// MARK: helpers

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
}

function iso(t: Millis): string {
  return new Date(t).toISOString()
}

/** Pretty-printed with sorted keys, like the iOS encoder. */
function stringify(value: unknown): string {
  return JSON.stringify(value, null, 2)
}

function requireSubtle(): SubtleCrypto {
  if (typeof crypto === 'undefined' || !crypto.subtle) throw new BackupError('cryptoUnavailable')
  return crypto.subtle
}

async function deriveKey(password: string, salt: Uint8Array, iterations: number): Promise<CryptoKey> {
  const subtle = requireSubtle()
  const material = await subtle.importKey('raw', new TextEncoder().encode(password), 'PBKDF2', false, ['deriveKey'])
  return subtle.deriveKey(
    { name: 'PBKDF2', hash: 'SHA-256', salt: salt as BufferSource, iterations },
    material,
    { name: 'AES-GCM', length: 256 },
    false,
    ['encrypt', 'decrypt'],
  )
}

function toBase64(bytes: Uint8Array): string {
  let binary = ''
  for (const b of bytes) binary += String.fromCharCode(b)
  return btoa(binary)
}

function fromBase64(text: string): Uint8Array {
  const binary = atob(text)
  return Uint8Array.from(binary, (c) => c.charCodeAt(0))
}
