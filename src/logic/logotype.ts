/**
 * Geometry of the PooPal lettering mark, in units of the x-height: rounded monoline letters with
 * one stroke weight, so the "o" rings and the bowls of the "P"s share the same circle. The pupils
 * sit in the two "o"s of "Poo". Shared by the in-app wordmark and `scripts/render-icons.mjs`.
 */
export const STROKE = 0.28
export const CAP = 1.4
const X_HEIGHT = 1.0
const BOWL = 0.96
const GAP = 0.17

type Letter = 'P' | 'o' | 'a' | 'l'
const LETTERS: Letter[] = ['P', 'o', 'o', 'P', 'a', 'l']

const letterWidth = (l: Letter) => (l === 'P' ? BOWL : l === 'l' ? STROKE : X_HEIGHT)

export const LOGOTYPE_WIDTH = LETTERS.reduce((w, l) => w + letterWidth(l), 0) + GAP * (LETTERS.length - 1) + GAP * 0.4

function letterPath(letter: Letter, x: number): string {
  const w = STROKE
  const ring = (cx: number, cy: number, r: number) =>
    `M${x + cx - r} ${cy}a${r} ${r} 0 1 0 ${2 * r} 0a${r} ${r} 0 1 0 ${-2 * r} 0`
  const stem = (sx: number, top: number, bottom: number) => `M${x + sx} ${top}L${x + sx} ${bottom}`
  switch (letter) {
    case 'P': {
      const r = (BOWL - w) / 2
      return stem(w / 2, w / 2 + r, CAP - w / 2) + ring(w / 2 + r, w / 2 + r, r)
    }
    case 'o':
      return ring(X_HEIGHT / 2, CAP - X_HEIGHT / 2, (X_HEIGHT - w) / 2)
    case 'a':
      return ring(X_HEIGHT / 2, CAP - X_HEIGHT / 2, (X_HEIGHT - w) / 2) + stem(X_HEIGHT - w / 2, CAP - X_HEIGHT / 2, CAP - w / 2)
    case 'l':
      return stem(w / 2, w / 2, CAP - w / 2)
  }
}

export interface Pupil {
  cx: number
  cy: number
  r: number
}

export function logotypeGeometry(): { path: string; pupils: Pupil[] } {
  let x = 0
  let path = ''
  const pupils: Pupil[] = []
  LETTERS.forEach((letter, index) => {
    if (index === 3) x += GAP * 0.4
    path += letterPath(letter, x)
    if (index === 1 || index === 2) {
      pupils.push({ cx: x + X_HEIGHT / 2 + 0.06, cy: CAP - X_HEIGHT / 2 - 0.04, r: STROKE * 0.46 })
    }
    x += letterWidth(letter) + GAP
  })
  return { path, pupils }
}
