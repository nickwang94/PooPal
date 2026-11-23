import { bristolInfo, type BristolType } from '../logic/bristol'
import type { PoopMood } from '../logic/stats'

const STICKER_INK: Record<string, string> = { dry: '#C2631A', ideal: '#2F7A4B', loose: '#2F6DB0' }

/** Glyph color on a type's pale sticker; fixed because the sticker stays light in dark mode. */
export function stickerInk(type: BristolType): string {
  return STICKER_INK[bristolInfo(type).state]
}

/** The type's state color (`dry` / `ideal` / `loose`) or its pale sticker tint, as a CSS variable. */
export function stateVar(type: BristolType, variant: '' | '-pale' = ''): string {
  return `var(--${bristolInfo(type).state}${variant})`
}

export type Face = 'beaming' | 'smile' | 'calm' | 'worried' | 'hello'

export function faceFor(mood: PoopMood): Face {
  switch (mood.kind) {
    case 'noData':
      return 'hello'
    case 'today':
      return 'beaming'
    case 'yesterday':
      return 'smile'
    case 'aWhile':
      return 'calm'
    case 'tooLong':
      return 'worried'
  }
}

