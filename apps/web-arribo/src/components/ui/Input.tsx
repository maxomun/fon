import type { InputHTMLAttributes } from 'react'

interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label: string
  error?: string
}

export function Input({ label, error, id, className = '', ...props }: InputProps) {
  const inputId = id ?? props.name

  return (
    <div className={`field ${className}`.trim()}>
      <label htmlFor={inputId}>{label}</label>
      <input id={inputId} className={error ? 'input-error' : undefined} {...props} />
      {error ? <span className="field-error">{error}</span> : null}
    </div>
  )
}
