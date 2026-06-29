const AVATAR_PALETTE = [
  { background: '#1a73e8', color: '#ffffff' },
  { background: '#188038', color: '#ffffff' },
  { background: '#e8710a', color: '#ffffff' },
  { background: '#9334e6', color: '#ffffff' },
  { background: '#d93025', color: '#ffffff' },
  { background: '#129eaf', color: '#ffffff' },
  { background: '#5f6368', color: '#ffffff' },
] as const

function hashString(value: string): number {
  let hash = 0

  for (let index = 0; index < value.length; index += 1) {
    hash = (hash << 5) - hash + value.charCodeAt(index)
    hash |= 0
  }

  return Math.abs(hash)
}

export function userAvatarColor(seed: string) {
  const palette = AVATAR_PALETTE[hashString(seed) % AVATAR_PALETTE.length]!
  return {
    backgroundColor: palette.background,
    color: palette.color,
  }
}
