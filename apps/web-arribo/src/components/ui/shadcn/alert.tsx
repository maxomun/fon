import * as React from 'react'
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

const alertVariants = cva(
  'relative w-full rounded-lg border px-4 py-3 text-sm grid has-[>svg]:grid-cols-[calc(var(--spacing)*4)_1fr] grid-cols-[0_1fr] has-[>svg]:gap-x-3 gap-y-0.5 items-start [&>svg]:size-4 [&>svg]:translate-y-0.5 [&>svg]:text-current',
  {
    variants: {
      variant: {
        default: 'bg-card text-foreground',
        destructive:
          'text-destructive bg-destructive/5 border-destructive/20 [&>svg]:text-destructive *:data-[slot=alert-description]:text-destructive/90',
        success:
          'border-emerald-200 bg-emerald-50 text-emerald-900 [&>svg]:text-emerald-600',
        info: 'border-sky-200 bg-sky-50 text-sky-900 [&>svg]:text-sky-600',
      },
    },
    defaultVariants: {
      variant: 'default',
    },
  },
)

function Alert({
  className,
  variant,
  ...props
}: React.ComponentProps<'div'> & VariantProps<typeof alertVariants>) {
  return (
    <div data-slot="alert" role="alert" className={cn(alertVariants({ variant }), className)} {...props} />
  )
}

function AlertDescription({ className, ...props }: React.ComponentProps<'div'>) {
  return (
    <div
      data-slot="alert-description"
      className={cn('col-start-2 text-sm leading-relaxed', className)}
      {...props}
    />
  )
}

export { Alert, AlertDescription }
