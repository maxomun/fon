import { forwardRef, type ButtonHTMLAttributes } from 'react'
import { Loader2 } from 'lucide-react'
import { Button as ShadcnButton } from '@/components/ui/shadcn/button'
import { cn } from '@/lib/utils'

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary'
  isLoading?: boolean
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(function Button(
  {
    variant = 'primary',
    isLoading = false,
    disabled,
    children,
    className = '',
    type = 'button',
    ...props
  },
  ref,
) {
  return (
    <ShadcnButton
      ref={ref}
      type={type}
      variant={variant === 'primary' ? 'default' : 'secondary'}
      disabled={disabled || isLoading}
      className={cn('w-full sm:w-auto', className)}
      {...props}
    >
      {isLoading ? (
        <>
          <Loader2 className="size-4 animate-spin" />
          Cargando…
        </>
      ) : (
        children
      )}
    </ShadcnButton>
  )
})
