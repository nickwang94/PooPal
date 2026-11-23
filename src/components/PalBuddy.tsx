import { useEffect, useRef, useState } from 'react'
import { useReducedMotion } from '../data/settings'
import type { Face } from './colors'

/** SVG arc through increasing angles (degrees, y-down), like SwiftUI's `addArc(clockwise: false)`. */
function arc(cx: number, cy: number, r: number, from: number, to: number): string {
  const p = (deg: number) => [cx + r * Math.cos((deg * Math.PI) / 180), cy + r * Math.sin((deg * Math.PI) / 180)]
  const [x1, y1] = p(from)
  const [x2, y2] = p(to)
  return `M${x1} ${y1}A${r} ${r} 0 ${to - from > 180 ? 1 : 0} 1 ${x2} ${y2}`
}

const INK = '#3A2440'

interface Props {
  face?: Face
  /** Changing this makes the buddy hop once. */
  hop?: number
  size?: number
}

/** The "Pal": a soft round marigold buddy whose face follows how things are going. Never poop-shaped. */
export function PalBuddy({ face = 'smile', hop = 0, size = 76 }: Props) {
  const reduceMotion = useReducedMotion()
  const [blinking, setBlinking] = useState(false)
  const bodyRef = useRef<SVGGElement>(null)
  const firstHop = useRef(hop)

  useEffect(() => {
    if (reduceMotion) return
    let timeout: ReturnType<typeof setTimeout>
    const schedule = () => {
      timeout = setTimeout(
        () => {
          setBlinking(true)
          timeout = setTimeout(() => {
            setBlinking(false)
            schedule()
          }, 130)
        },
        2800 + Math.random() * 2200,
      )
    }
    schedule()
    return () => clearTimeout(timeout)
  }, [reduceMotion])

  useEffect(() => {
    if (hop === firstHop.current || reduceMotion) return
    bodyRef.current?.animate(
      [
        { transform: 'translateY(0) scale(1, 1)' },
        { transform: 'translateY(-22%) scale(1.06, 0.96)', offset: 0.35 },
        { transform: 'translateY(0) scale(1, 1)' },
      ],
      { duration: 520, easing: 'cubic-bezier(.3,1.6,.5,1)' },
    )
  }, [hop, reduceMotion])

  const eyeY = 44
  const eyeR = 5.5
  return (
    <svg width={size} height={size} viewBox="0 0 100 100" aria-hidden="true" className="pal-buddy">
      <g ref={bodyRef} style={{ transformOrigin: '50% 100%', transformBox: 'fill-box' }}>
        <ellipse cx="50" cy="50" rx="47.75" ry="43.75" fill="var(--sunny)" stroke="var(--sticker-edge)" strokeWidth="4.5" />
        {[-1, 1].map((side) => {
          const cx = 50 + side * 17
          return (
            <g key={side}>
              {face === 'beaming' ? (
                <path d={arc(cx, eyeY + eyeR * 0.6, eyeR * 1.2, 200, 340)} fill="none" stroke={INK} strokeWidth="4" strokeLinecap="round" />
              ) : (
                <ellipse cx={cx} cy={eyeY} rx={eyeR} ry={blinking ? eyeR * 0.175 : eyeR} fill={INK} />
              )}
              <ellipse cx={cx + side * 8} cy={57.5} rx="6" ry="3.5" fill="var(--blush)" opacity={face === 'worried' ? 0 : 0.55} />
            </g>
          )
        })}
        <path d={mouth(face)} fill="none" stroke={INK} strokeWidth="4" strokeLinecap="round" />
      </g>
    </svg>
  )
}

function mouth(face: Face): string {
  switch (face) {
    case 'beaming':
    case 'hello':
      return arc(50, 60, 9, 20, 160)
    case 'smile':
      return arc(50, 57, 8, 40, 140)
    case 'calm':
      return 'M44 62L56 62'
    case 'worried':
      return arc(50, 69, 7, 220, 320)
  }
}
