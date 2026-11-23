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

const INFO: Record<BristolType, BristolInfo> = {
  1: { name: '硬球球', hint: '一颗颗硬硬的，可能有点便秘了', group: '偏干', state: 'dry' },
  2: { name: '疙瘩条', hint: '成条但疙疙瘩瘩，偏干', group: '偏干', state: 'dry' },
  3: { name: '裂纹条', hint: '成条有点裂纹，挺好的', group: '理想', state: 'ideal' },
  4: { name: '光滑条', hint: '光滑柔软，完美！', group: '理想', state: 'ideal' },
  5: { name: '软团团', hint: '软软的小团，边缘清楚', group: '偏软', state: 'ideal' },
  6: { name: '糊糊状', hint: '糊糊的，有点稀', group: '偏稀', state: 'loose' },
  7: { name: '水水状', hint: '水水的，记得多补水哦', group: '偏稀', state: 'loose' },
}

export function bristolInfo(type: BristolType): BristolInfo {
  return INFO[type]
}

export function asBristol(value: unknown): BristolType | undefined {
  return typeof value === 'number' && Number.isInteger(value) && value >= 1 && value <= 7
    ? (value as BristolType)
    : undefined
}

/** "4 型 · 光滑条" */
export function bristolLabel(type: BristolType): string {
  return `${type} 型 · ${INFO[type].name}`
}
