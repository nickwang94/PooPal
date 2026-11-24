import { messages, type Messages } from '../i18n'

/** Bristol stool scale, types 1–7. */
export type BristolType = 1 | 2 | 3 | 4 | 5 | 6 | 7

export const BRISTOL_TYPES: readonly BristolType[] = [1, 2, 3, 4, 5, 6, 7]

/** Color family: tangerine for dry, leaf for ideal, sky for loose. */
export type BristolState = 'dry' | 'ideal' | 'loose'

interface BristolInfo {
  name: string
  hint: string
  group: string
  state: BristolState
}

const GROUPS: Record<BristolType, keyof Messages['bristol']['groups']> = {
  1: 'dry',
  2: 'dry',
  3: 'ideal',
  4: 'ideal',
  5: 'soft',
  6: 'loose',
  7: 'loose',
}

const STATES: Record<BristolType, BristolState> = { 1: 'dry', 2: 'dry', 3: 'ideal', 4: 'ideal', 5: 'ideal', 6: 'loose', 7: 'loose' }

/** Name, hint and group in the current UI language. */
export function bristolInfo(type: BristolType): BristolInfo {
  const t = messages().bristol
  return { name: t.names[type - 1], hint: t.hints[type - 1], group: t.groups[GROUPS[type]], state: STATES[type] }
}

export function asBristol(value: unknown): BristolType | undefined {
  return typeof value === 'number' && Number.isInteger(value) && value >= 1 && value <= 7
    ? (value as BristolType)
    : undefined
}

/** "4 型 · 光滑条" / "Type 4 · Smooth log" */
export function bristolLabel(type: BristolType): string {
  return messages().bristol.label(type, bristolInfo(type).name)
}
