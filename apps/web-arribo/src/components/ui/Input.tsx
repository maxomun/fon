import { forwardRef, useState, type InputHTMLAttributes } from 'react'

interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label: string
  error?: string
}

function EyeIcon({ hidden }: { hidden: boolean }) {
  if (hidden) {
    return (
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden="true">
        <path
          d="M3 3l18 18M10.58 10.58A2 2 0 0 0 12 15a2 2 0 0 0 1.42-.58M9.88 4.24A10.94 10.94 0 0 1 12 4c5 0 9.27 3.11 11 8-1.02 2.74-2.86 4.97-5.12 6.24M6.61 6.61C4.62 7.86 3.17 9.79 2 12c1.73 4.89 6 8 10 8 1.55 0 3.02-.39 4.28-1.08"
          stroke="currentColor"
          strokeWidth="1.75"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
      </svg>
    )
  }

  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <path
        d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7Z"
        stroke="currentColor"
        strokeWidth="1.75"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <circle
        cx="12"
        cy="12"
        r="3"
        stroke="currentColor"
        strokeWidth="1.75"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  )
}

export const Input = forwardRef<HTMLInputElement, InputProps>(function Input(
  { label, error, id, className = '', type, ...props },
  ref,
) {
  const inputId = id ?? props.name
  const isPassword = type === 'password'
  const [visible, setVisible] = useState(false)
  const inputType = isPassword && visible ? 'text' : type
  const inputClassName = error ? 'input-error' : undefined

  return (
    <div className={`field ${className}`.trim()}>
      <label htmlFor={inputId}>{label}</label>
      {isPassword ? (
        <div className="field-password">
          <input
            ref={ref}
            id={inputId}
            type={inputType}
            className={inputClassName}
            {...props}
          />
          <button
            type="button"
            className="field-password__toggle"
            aria-label={visible ? 'Ocultar contraseña' : 'Mostrar contraseña'}
            aria-pressed={visible}
            disabled={props.disabled}
            onClick={() => setVisible((current) => !current)}
          >
            <EyeIcon hidden={visible} />
          </button>
        </div>
      ) : (
        <input ref={ref} id={inputId} type={type} className={inputClassName} {...props} />
      )}
      {error ? <span className="field-error">{error}</span> : null}
    </div>
  )
})
