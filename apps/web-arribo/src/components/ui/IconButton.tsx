import { forwardRef, type ButtonHTMLAttributes } from 'react'
import { Loader2, type LucideIcon } from 'lucide-react'
import { cn } from '@/lib/utils'

interface IconButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  icon: LucideIcon
  label: string
  isLoading?: boolean
  variant?: 'default' | 'danger'
}

export const IconButton = forwardRef<HTMLButtonElement, IconButtonProps>(function IconButton(
  {
    icon: Icon,
    label,
    isLoading = false,
    variant = 'default',
    disabled,
    className,
    type = 'button',
    ...props
  },
  ref,
) {
  return (
    <button
      ref={ref}
      type={type}
      className={cn(
        'icon-btn',
        variant === 'danger' && 'icon-btn--danger',
        className,
      )}
      disabled={disabled || isLoading}
      aria-label={label}
      data-tooltip={label}
      {...props}
    >
      {isLoading ? <Loader2 className="icon-btn__icon icon-btn__icon--spin" /> : <Icon className="icon-btn__icon" />}
    </button>
  )
})
