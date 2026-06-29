import { userAvatarColor } from '@/lib/userAvatarColor'
import { userInitials } from '@/lib/userInitials'
import { cn } from '@/lib/utils'

interface UserAvatarProps {
  displayName: string
  email?: string | null
  size?: 'sm' | 'md' | 'lg'
  className?: string
}

const sizeClassName = {
  sm: 'user-avatar--sm',
  md: 'user-avatar--md',
  lg: 'user-avatar--lg',
} as const

export function UserAvatar({
  displayName,
  email,
  size = 'md',
  className,
}: UserAvatarProps) {
  const seed = displayName.trim() || email?.trim() || 'usuario'
  const initials = userInitials(displayName, email)
  const colors = userAvatarColor(seed)

  return (
    <span
      className={cn('user-avatar', sizeClassName[size], className)}
      style={colors}
      aria-hidden="true"
    >
      {initials}
    </span>
  )
}
