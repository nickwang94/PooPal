import { CAP, LOGOTYPE_WIDTH, logotypeGeometry, STROKE } from '../logic/logotype'

const geometry = logotypeGeometry()

interface Props {
  height?: number
  color?: string
  eyes?: boolean
  className?: string
}

/** The PooPal wordmark; the only display voice. Never set in a font. */
export function Logotype({ height = 22, color = 'var(--accent)', eyes = false, className }: Props) {
  return (
    <svg
      className={className}
      viewBox={`${-STROKE / 2} ${-STROKE / 2} ${LOGOTYPE_WIDTH + STROKE} ${CAP + STROKE}`}
      height={height}
      role="img"
      aria-label="PooPal"
    >
      <path d={geometry.path} fill="none" stroke={color} strokeWidth={STROKE} strokeLinecap="round" strokeLinejoin="round" />
      {eyes && geometry.pupils.map((p, i) => <circle key={i} cx={p.cx} cy={p.cy} r={p.r} fill={color} />)}
    </svg>
  )
}
