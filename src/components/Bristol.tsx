import { useId, type CSSProperties } from 'react'
import { useT } from '../i18n'
import { BRISTOL_TYPES, bristolInfo, type BristolType } from '../logic/bristol'
import { stateVar, stickerInk } from './colors'
import { Icon } from './Icons'

const mushyBlob = (() => {
  const points: string[] = []
  for (let i = 0; i <= 60; i++) {
    const a = (i / 60) * 2 * Math.PI
    const r = 0.31 + 0.035 * Math.sin(a * 5)
    points.push(`${(0.5 + r * Math.cos(a)).toFixed(4)} ${(0.54 + r * 0.72 * Math.sin(a)).toFixed(4)}`)
  }
  return `M${points.join('L')}Z`
})()

function drop(x: number, y: number, r: number): string {
  return `M${x} ${y - r * 1.9}Q${x + r} ${y - r} ${x + r} ${y}A${r} ${r} 0 0 1 ${x - r} ${y}Q${x - r} ${y - r} ${x} ${y - r * 1.9}Z`
}

/** Monochrome drawing of a Bristol type in one ink color (ported from the iOS glyphs). */
export function BristolGlyph({ type, color, size }: { type: BristolType; color: string; size?: number | string }) {
  const maskId = useId()
  const soft = { fill: color, opacity: 0.55 }
  let content
  switch (type) {
    case 1:
      content = [
        [0.3, 0.38, 0.12],
        [0.62, 0.32, 0.1],
        [0.68, 0.64, 0.12],
        [0.36, 0.68, 0.13],
      ].map(([cx, cy, r]) => <circle key={cx} cx={cx} cy={cy} r={r} fill={color} />)
      break
    case 2:
      content = [0.2, 0.35, 0.5, 0.65, 0.8].map((cx, i) => (
        <circle key={cx} cx={cx} cy={0.5 + (i % 2 === 0 ? -0.02 : 0.02)} r={0.13} fill={color} />
      ))
      break
    case 3:
      content = (
        <>
          <mask id={maskId}>
            <rect width="1" height="1" fill="white" />
            {[0.32, 0.5, 0.68].map((x) => (
              <line key={x} x1={x - 0.02} y1={0.37} x2={x + 0.02} y2={0.47} stroke="black" strokeWidth={0.035} strokeLinecap="round" />
            ))}
          </mask>
          <rect x={0.1} y={0.37} width={0.8} height={0.26} rx={0.13} fill={color} mask={`url(#${maskId})`} />
        </>
      )
      break
    case 4:
      content = <path d="M.16 .6C.4 .3 .6 .76 .84 .42" fill="none" stroke={color} strokeWidth={0.2} strokeLinecap="round" />
      break
    case 5:
      content = (
        <>
          <ellipse cx={0.3} cy={0.42} rx={0.15} ry={0.12} {...soft} />
          <ellipse cx={0.68} cy={0.38} rx={0.13} ry={0.1} {...soft} />
          <ellipse cx={0.5} cy={0.64} rx={0.2} ry={0.14} fill={color} />
        </>
      )
      break
    case 6:
      content = <path d={mushyBlob} {...soft} />
      break
    case 7:
      content = (
        <>
          <ellipse cx={0.5} cy={0.68} rx={0.34} ry={0.12} {...soft} />
          {[
            [0.34, 0.32, 0.06],
            [0.6, 0.24, 0.05],
            [0.7, 0.42, 0.045],
          ].map(([x, y, r]) => (
            <path key={x} d={drop(x, y, r)} fill={color} />
          ))}
        </>
      )
      break
  }
  return (
    <svg viewBox="0 0 1 1" width={size} height={size} aria-hidden="true" className="bristol-glyph">
      {content}
    </svg>
  )
}

/** Round sticker for an entry: its Bristol glyph on the type's pale tint, or a check when unrecorded. */
export function EntryBadge({ type, size = 36, style }: { type?: BristolType; size?: number; style?: CSSProperties }) {
  const edge = Math.max(1.5, size * 0.06)
  return (
    <span
      className="sticker entry-badge"
      style={{
        width: size,
        height: size,
        background: type ? stateVar(type, '-pale') : 'var(--surface-sunk)',
        borderWidth: edge,
        ...style,
      }}
      aria-hidden="true"
    >
      {type ? (
        <BristolGlyph type={type} color={stickerInk(type)} size={size * 0.6 - edge} />
      ) : (
        <Icon name="check" size={size * 0.4} />
      )}
    </span>
  )
}

interface PickerProps {
  value?: BristolType
  onChange: (value: BristolType | undefined) => void
}

/** A 4×2 grid of the seven types plus "not sure". The selected sticker fills, lifts and tilts. */
export function BristolPicker({ value, onChange }: PickerProps) {
  const t = useT()
  const hint = value ? t.bristol.hint(bristolInfo(value).group, bristolInfo(value).hint) : null
  return (
    <div className="bristol-picker">
      <div className="bristol-grid" role="radiogroup" aria-label={t.bristol.pickerLabel}>
        {BRISTOL_TYPES.map((type) => {
          const selected = value === type
          return (
            <button
              key={type}
              type="button"
              role="radio"
              aria-checked={selected}
              aria-label={t.bristol.spoken(type, bristolInfo(type).name)}
              className={`picker-sticker${selected ? ' selected' : ''}`}
              style={{
                background: selected ? stateVar(type) : stateVar(type, '-pale'),
                color: selected ? 'var(--on-accent)' : 'var(--day-ink)',
              }}
              onClick={() => onChange(selected ? undefined : type)}
            >
              <BristolGlyph type={type} color={selected ? 'var(--on-accent)' : stickerInk(type)} size={34} />
              <span className="picker-number">{type}</span>
              <span className="picker-name">{bristolInfo(type).name}</span>
            </button>
          )
        })}
        <button
          type="button"
          role="radio"
          aria-checked={value === undefined}
          aria-label={t.bristol.unsureLabel}
          className={`picker-sticker unsure${value === undefined ? ' selected' : ''}`}
          onClick={() => onChange(undefined)}
        >
          <Icon name="question" size={22} />
          <span className="picker-number">{t.bristol.unsure}</span>
          <span className="picker-name">{t.bristol.skip}</span>
        </button>
      </div>
      <p className="picker-hint" aria-live="polite">
        {hint}
      </p>
    </div>
  )
}
