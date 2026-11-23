// Renders the PWA icons into public/icons/ from the PooPal wordmark geometry, matching the v4
// iOS app icon: deep plum letters with eyes on a marigold gradient. Run with `npm run icons`.
import { mkdir, writeFile } from 'node:fs/promises'
import sharp from 'sharp'
import { CAP, LOGOTYPE_WIDTH, logotypeGeometry, STROKE } from '../src/logic/logotype.ts'

const out = new URL('../public/icons/', import.meta.url)
const { path, pupils } = logotypeGeometry()

/** The 1024-unit icon; `letterWidth` is the wordmark width (870 on iOS, smaller for maskable). */
function iconSvg({ letterWidth = 870, radius = 0 } = {}) {
  const scale = letterWidth / LOGOTYPE_WIDTH
  const x = (1024 - letterWidth) / 2
  const y = (1024 - CAP * scale) / 2 + 8
  const letters = '#4A2A63'
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    <linearGradient id="g" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#FFD45E"/><stop offset=".5" stop-color="#FFC23A"/><stop offset="1" stop-color="#F7A91F"/>
    </linearGradient>
    <radialGradient id="h" cx="307" cy="154" r="620" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="#fff" stop-opacity=".22"/><stop offset="1" stop-color="#fff" stop-opacity="0"/>
    </radialGradient>
  </defs>
  <rect width="1024" height="1024" rx="${radius}" fill="url(#g)"/>
  <rect width="1024" height="1024" rx="${radius}" fill="url(#h)"/>
  <g transform="translate(${x} ${y}) scale(${scale})">
    <path d="${path}" fill="none" stroke="${letters}" stroke-width="${STROKE}" stroke-linecap="round" stroke-linejoin="round"/>
    ${pupils.map((p) => `<circle cx="${p.cx}" cy="${p.cy}" r="${p.r}" fill="${letters}"/>`).join('')}
  </g>
</svg>`
}

async function png(svg, size, name) {
  await sharp(Buffer.from(svg)).resize(size, size).flatten({ background: '#FFC23A' }).png().toFile(new URL(name, out).pathname)
  console.log(`wrote public/icons/${name}`)
}

await mkdir(out, { recursive: true })
const standard = iconSvg()
await png(standard, 512, 'icon-512.png')
await png(standard, 192, 'icon-192.png')
await png(standard, 180, 'apple-touch-icon.png')
// Maskable icons are cropped to a circle of 80% diameter: keep the wordmark well inside it.
await png(iconSvg({ letterWidth: 640 }), 512, 'icon-maskable-512.png')
await writeFile(new URL('favicon.svg', out), iconSvg({ letterWidth: 900, radius: 224 }))
console.log('wrote public/icons/favicon.svg')
