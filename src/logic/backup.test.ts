import { describe, expect, it } from 'vitest'
import {
  backupFileName,
  BackupError,
  decodeBackup,
  encodeBackup,
  entryKey,
  isEncryptedBackup,
  makeMergePlan,
  mergeSummary,
  type BackupEntry,
} from './backup'

const base = 1_793_000_000_250

function entry(offsetHours: number, bristolType?: number, note?: string): BackupEntry {
  const e: BackupEntry = { timestamp: base + offsetHours * 3_600_000 }
  if (bristolType !== undefined) e.bristolType = bristolType
  if (note !== undefined) e.note = note
  return e
}

async function expectCode(promise: Promise<unknown>, code: BackupError['code'], version?: number) {
  const error = await promise.then(
    () => null,
    (e: unknown) => e,
  )
  expect(error).toBeInstanceOf(BackupError)
  expect((error as BackupError).code).toBe(code)
  if (version !== undefined) expect((error as BackupError).version).toBe(version)
}

describe('BackupCodec', () => {
  it('round-trips plain backups with milliseconds and fields', async () => {
    const entries = [entry(0, 4, '火锅'), entry(-20)]
    const text = await encodeBackup(entries, { exportedAt: base })
    expect(isEncryptedBackup(text)).toBe(false)
    const file = await decodeBackup(text)
    expect(file.app).toBe('PooPal')
    expect(file.entries).toHaveLength(2)
    // Sorted oldest first.
    expect(file.entries[0].timestamp).toBe(entries[1].timestamp)
    expect(file.entries[1].bristolType).toBe(4)
    expect(file.entries[1].note).toBe('火锅')
    expect(entryKey(file.entries[1].timestamp)).toBe(entryKey(entries[0].timestamp))
  })

  it('writes the iOS layout: sorted keys, ISO dates with milliseconds, omitted nils', async () => {
    const text = await encodeBackup([entry(0, 3)], { exportedAt: base })
    const json = JSON.parse(text)
    expect(Object.keys(json)).toEqual(['app', 'entries', 'exportedAt', 'version'])
    expect(json.exportedAt).toBe('2026-10-26T07:33:20.250Z')
    expect(json.entries[0]).toEqual({ bristolType: 3, timestamp: '2026-10-26T07:33:20.250Z' })
  })

  it('round-trips encrypted backups', async () => {
    const text = await encodeBackup([entry(0, 3)], { password: '便便1234', iterations: 1_000 })
    expect(isEncryptedBackup(text)).toBe(true)
    expect(text).not.toContain('bristolType')
    const wrapper = JSON.parse(text)
    expect(Object.keys(wrapper)).toEqual(['app', 'format', 'iterations', 'kdf', 'payload', 'salt', 'version'])
    expect(wrapper.kdf).toBe('PBKDF2-SHA256')
    const file = await decodeBackup(text, '便便1234')
    expect(file.entries[0].bristolType).toBe(3)
  })

  it('encrypts with the default iterations', async () => {
    const text = await encodeBackup([entry(0)], { password: 'secret' })
    expect(JSON.parse(text).iterations).toBe(210_000)
    expect((await decodeBackup(text, 'secret')).entries).toHaveLength(1)
  })

  it('requires the correct password', async () => {
    const text = await encodeBackup([entry(0)], { password: 'right', iterations: 1_000 })
    await expectCode(decodeBackup(text), 'passwordRequired')
    await expectCode(decodeBackup(text, 'wrong'), 'wrongPassword')
  })

  it('opens a backup sealed by the iOS app (CryptoKit AES.GCM combined box)', async () => {
    // Built with the same layout as the iOS app: PBKDF2-SHA256(password, salt) -> AES-256-GCM,
    // payload = nonce(12) ‖ ciphertext ‖ tag(16), base64.
    const plain = '{"app":"PooPal","entries":[{"bristolType":4,"note":"火锅","timestamp":"2026-11-14T00:30:00.000Z"}],"exportedAt":"2026-11-14T10:00:00Z","version":1}'
    const salt = new Uint8Array(16).fill(7)
    const nonce = new Uint8Array(12).fill(9)
    const material = await crypto.subtle.importKey('raw', new TextEncoder().encode('pw'), 'PBKDF2', false, ['deriveKey'])
    const key = await crypto.subtle.deriveKey(
      { name: 'PBKDF2', hash: 'SHA-256', salt, iterations: 1_000 },
      material,
      { name: 'AES-GCM', length: 256 },
      false,
      ['encrypt'],
    )
    const sealed = new Uint8Array(await crypto.subtle.encrypt({ name: 'AES-GCM', iv: nonce }, key, new TextEncoder().encode(plain)))
    const b64 = (bytes: Uint8Array) => btoa(String.fromCharCode(...bytes))
    const wrapper = JSON.stringify({
      app: 'PooPal',
      format: 'encrypted',
      version: 1,
      kdf: 'PBKDF2-SHA256',
      iterations: 1_000,
      salt: b64(salt),
      payload: b64(new Uint8Array([...nonce, ...sealed])),
    })
    const file = await decodeBackup(wrapper, 'pw')
    expect(file.entries[0]).toEqual({ timestamp: Date.parse('2026-11-14T00:30:00Z'), bristolType: 4, note: '火锅' })
  })

  it('rejects foreign JSON', async () => {
    await expectCode(decodeBackup('{"hello":"world"}'), 'invalidFile')
    await expectCode(decodeBackup('not json'), 'invalidFile')
    await expectCode(
      decodeBackup('{"app":"Other","version":1,"exportedAt":"2026-11-14T10:00:00Z","entries":[]}'),
      'invalidFile',
    )
  })

  it('accepts timestamps without fractional seconds', async () => {
    const file = await decodeBackup(
      '{"app":"PooPal","version":1,"exportedAt":"2026-11-14T10:00:00Z","entries":[{"timestamp":"2026-11-14T08:30:00+08:00"}]}',
    )
    expect(file.entries).toHaveLength(1)
    expect(file.entries[0].bristolType).toBeUndefined()
    expect(file.entries[0].timestamp).toBe(Date.parse('2026-11-14T00:30:00Z'))
  })

  it('rejects newer versions', async () => {
    await expectCode(
      decodeBackup('{"app":"PooPal","version":9,"exportedAt":"2026-11-14T10:00:00Z","entries":[]}'),
      'unsupportedVersion',
      9,
    )
  })

  it('rejects absurd iteration counts', async () => {
    const text = JSON.stringify({ app: 'PooPal', format: 'encrypted', version: 1, kdf: 'PBKDF2-SHA256', iterations: 1e12, salt: 'AA==', payload: 'AA==' })
    await expectCode(decodeBackup(text, 'x'), 'invalidFile')
  })

  it('names files in local time', () => {
    const d = new Date(2026, 10, 14, 9, 5).getTime()
    expect(backupFileName(d, false)).toBe('PooPal-备份-20261114-0905.json')
    expect(backupFileName(d, true)).toBe('PooPal-备份-20261114-0905-加密.json')
  })
})

describe('MergePlan', () => {
  it('skips duplicates and inserts new entries', () => {
    const plan = makeMergePlan([entry(0), entry(-24)], [entry(0), entry(-24), entry(-48), entry(-48)])
    expect(plan.inserts).toEqual([entry(-48)])
    expect(plan.duplicates).toBe(3)
    expect(plan.fills).toEqual([])
  })

  it('matches within the same second', () => {
    expect(makeMergePlan([{ timestamp: 1_000_100 }], [{ timestamp: 1_000_900 }]).duplicates).toBe(1)
  })

  it('fills missing details but never overwrites', () => {
    const plan = makeMergePlan([entry(0), entry(-24, 5, '原备注')], [entry(0, 4, '新备注'), entry(-24, 1, '别覆盖')])
    expect(plan.fills).toEqual([{ existingIndex: 0, bristolType: 4, note: '新备注' }])
    expect(plan.duplicates).toBe(1)
    expect(plan.inserts).toEqual([])
  })

  it('ignores invalid Bristol types when filling', () => {
    const plan = makeMergePlan([entry(0)], [entry(0, 9)])
    expect(plan.fills).toEqual([])
    expect(plan.duplicates).toBe(1)
  })

  it('summarizes', () => {
    expect(mergeSummary({ inserts: [entry(0)], fills: [], duplicates: 2 })).toBe('新增 1 条，跳过 2 条重复')
    expect(mergeSummary({ inserts: [], fills: [{ existingIndex: 0 }], duplicates: 0 })).toBe(
      '新增 0 条，补充 1 条的形态或备注，跳过 0 条重复',
    )
  })
})
