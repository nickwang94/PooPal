import type { ReactNode } from 'react'

export type IconName =
  | 'plus'
  | 'gear'
  | 'home'
  | 'grid'
  | 'check'
  | 'question'
  | 'history'
  | 'chevronLeft'
  | 'chevronRight'
  | 'chevronDown'
  | 'bell'
  | 'alarm'
  | 'lock'
  | 'share'
  | 'download'
  | 'halfCircle'
  | 'seal'
  | 'trash'
  | 'globe'

const STROKE = { fill: 'none', stroke: 'currentColor', strokeWidth: 2.2, strokeLinecap: 'round', strokeLinejoin: 'round' } as const

const PATHS: Record<IconName, ReactNode> = {
  plus: <path d="M12 5v14M5 12h14" {...STROKE} strokeWidth={3} />,
  gear: (
    <path
      fill="currentColor"
      fillRule="evenodd"
      d="M10.3 2h3.4l.5 2.6c.7.3 1.3.6 1.9 1.1l2.5-.9 1.7 2.9-2 1.7c.1.4.1.8.1 1.2s0 .8-.1 1.2l2 1.7-1.7 2.9-2.5-.9c-.6.5-1.2.8-1.9 1.1l-.5 2.6h-3.4l-.5-2.6c-.7-.3-1.3-.6-1.9-1.1l-2.5.9-1.7-2.9 2-1.7c-.1-.4-.1-.8-.1-1.2s0-.8.1-1.2l-2-1.7 1.7-2.9 2.5.9c.6-.5 1.2-.8 1.9-1.1zM12 8.6a3.4 3.4 0 1 0 0 6.8 3.4 3.4 0 0 0 0-6.8z"
      transform="translate(0 .1)"
    />
  ),
  home: <path fill="currentColor" d="M12 3.2 2.8 10.6c-.5.4-.2 1.2.4 1.2H5v7.7c0 .8.7 1.5 1.5 1.5H10v-5.5h4V21h3.5c.8 0 1.5-.7 1.5-1.5v-7.7h1.8c.6 0 .9-.8.4-1.2z" />,
  grid: (
    <g fill="currentColor">
      {[5, 12, 19].flatMap((y) => [5, 12, 19].map((x) => <circle key={`${x}-${y}`} cx={x} cy={y} r={2.7} />))}
    </g>
  ),
  check: <path d="M5 12.5l4.5 4.5L19 7.5" {...STROKE} strokeWidth={2.6} />,
  question: <path d="M9 9.2a3 3 0 1 1 4.2 2.8c-.8.4-1.2 1-1.2 1.8v.7M12 18.6v.1" {...STROKE} strokeWidth={2.6} />,
  history: (
    <g {...STROKE}>
      <path d="M4.5 12a7.5 7.5 0 1 0 2.2-5.3L4.5 9" />
      <path d="M4.5 4.5V9H9" />
      <path d="M12 8v4.3l2.8 1.7" />
    </g>
  ),
  chevronLeft: <path d="M15 5l-7 7 7 7" {...STROKE} strokeWidth={2.6} />,
  chevronRight: <path d="M9 5l7 7-7 7" {...STROKE} strokeWidth={2.6} />,
  chevronDown: <path d="M6 9l6 6 6-6" {...STROKE} strokeWidth={2.6} />,
  bell: (
    <g fill="currentColor">
      <path d="M12 3a6 6 0 0 0-6 6v3.6L4.4 15.4c-.3.6.1 1.3.8 1.3h13.6c.7 0 1.1-.7.8-1.3L18 12.6V9a6 6 0 0 0-6-6z" />
      <path d="M9.5 18.2h5a2.5 2.5 0 0 1-5 0z" />
    </g>
  ),
  alarm: (
    <g>
      <circle cx="12" cy="13" r="7" fill="currentColor" />
      <path d="M12 9.5V13l2.3 1.6" fill="none" stroke="var(--icon-cut, #fff)" strokeWidth={2} strokeLinecap="round" />
      <path d="M4 6.5 6.8 4M20 6.5 17.2 4" {...STROKE} />
    </g>
  ),
  lock: (
    <g>
      <path d="M8 10V7.5a4 4 0 0 1 8 0V10" {...STROKE} strokeWidth={2.4} />
      <rect x="5" y="10" width="14" height="10" rx="2.5" fill="currentColor" />
    </g>
  ),
  share: (
    <g {...STROKE}>
      <path d="M12 14V3.5M8 7l4-4 4 4" />
      <path d="M8.5 10H7a2 2 0 0 0-2 2v6.5a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V12a2 2 0 0 0-2-2h-1.5" />
    </g>
  ),
  download: (
    <g {...STROKE}>
      <path d="M12 3.5V14M8 10l4 4 4-4" />
      <path d="M8.5 10H7a2 2 0 0 0-2 2v6.5a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V12a2 2 0 0 0-2-2h-1.5" />
    </g>
  ),
  halfCircle: (
    <g>
      <circle cx="12" cy="12" r="8" fill="none" stroke="currentColor" strokeWidth={2.2} />
      <path d="M12 4a8 8 0 0 0 0 16z" fill="currentColor" />
    </g>
  ),
  seal: (
    <g>
      <path
        fill="currentColor"
        d="M12 2.5l2.2 1.6 2.7-.2.9 2.6 2.3 1.4-.6 2.6.9 2.6-2.1 1.7-.6 2.7-2.7.3L12 21.5l-2.2-1.6-2.7.2-.9-2.6-2.3-1.4.6-2.6-.9-2.6 2.1-1.7.6-2.7 2.7-.3z"
      />
      <path d="M8.2 12.2l2.6 2.6 5-5.2" fill="none" stroke="var(--icon-cut, #fff)" strokeWidth={2.2} strokeLinecap="round" strokeLinejoin="round" />
    </g>
  ),
  globe: (
    <g {...STROKE}>
      <circle cx="12" cy="12" r="8.2" />
      <path d="M3.8 12h16.4M12 3.8c2.3 2.3 3.4 5 3.4 8.2s-1.1 5.9-3.4 8.2c-2.3-2.3-3.4-5-3.4-8.2s1.1-5.9 3.4-8.2z" />
    </g>
  ),
  trash: (
    <g {...STROKE}>
      <path d="M4.5 6.5h15M9.5 6.5V4.5h5v2M6.5 6.5l1 13h9l1-13" />
    </g>
  ),
}

export function Icon({ name, size = 24, className }: { name: IconName; size?: number; className?: string }) {
  return (
    <svg className={className} width={size} height={size} viewBox="0 0 24 24" aria-hidden="true" focusable="false">
      {PATHS[name]}
    </svg>
  )
}
