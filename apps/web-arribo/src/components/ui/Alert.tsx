import type { ReactNode } from 'react'
import { AlertCircle, CheckCircle2, Info } from 'lucide-react'
import { Alert as ShadcnAlert, AlertDescription } from '@/components/ui/shadcn/alert'

interface AlertProps {
  variant?: 'error' | 'info' | 'success'
  children: ReactNode
}

const icons = {
  error: AlertCircle,
  info: Info,
  success: CheckCircle2,
} as const

const shadcnVariants = {
  error: 'destructive',
  info: 'info',
  success: 'success',
} as const

export function Alert({ variant = 'info', children }: AlertProps) {
  const Icon = icons[variant]

  return (
    <ShadcnAlert variant={shadcnVariants[variant]}>
      <Icon />
      <AlertDescription>{children}</AlertDescription>
    </ShadcnAlert>
  )
}
