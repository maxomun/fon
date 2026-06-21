import { forwardRef, useState, type InputHTMLAttributes } from 'react'
import { Eye, EyeOff } from 'lucide-react'
import { Input as ShadcnInput } from '@/components/ui/shadcn/input'
import { Label } from '@/components/ui/shadcn/label'
import { cn } from '@/lib/utils'

interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label: string
  error?: string
}

export const Input = forwardRef<HTMLInputElement, InputProps>(function Input(
  { label, error, id, className = '', type, ...props },
  ref,
) {
  const inputId = id ?? props.name
  const isPassword = type === 'password'
  const [visible, setVisible] = useState(false)
  const inputType = isPassword && visible ? 'text' : type

  return (
    <div className={cn('grid gap-2', className)}>
      <Label htmlFor={inputId}>{label}</Label>
      {isPassword ? (
        <div className="relative">
          <ShadcnInput
            ref={ref}
            id={inputId}
            type={inputType}
            aria-invalid={Boolean(error)}
            className="pr-10"
            {...props}
          />
          <button
            type="button"
            className="absolute inset-y-0 right-0 flex w-10 items-center justify-center text-muted-foreground transition-colors hover:text-foreground disabled:opacity-50"
            aria-label={visible ? 'Ocultar contraseña' : 'Mostrar contraseña'}
            aria-pressed={visible}
            disabled={props.disabled}
            onClick={() => setVisible((current) => !current)}
          >
            {visible ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
          </button>
        </div>
      ) : (
        <ShadcnInput
          ref={ref}
          id={inputId}
          type={type}
          aria-invalid={Boolean(error)}
          {...props}
        />
      )}
      {error ? <p className="text-destructive text-sm">{error}</p> : null}
    </div>
  )
})
