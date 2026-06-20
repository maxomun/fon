import { forwardRef, type InputHTMLAttributes } from 'react'

interface CheckboxProps extends Omit<InputHTMLAttributes<HTMLInputElement>, 'type'> {
  label: string
  hint?: string
}

export const Checkbox = forwardRef<HTMLInputElement, CheckboxProps>(function Checkbox(
  { label, hint, id, className = '', ...props },
  ref,
) {
  const inputId = id ?? props.name

  return (
    <div className={`field-checkbox ${className}`.trim()}>
      <input ref={ref} id={inputId} type="checkbox" {...props} />
      <label htmlFor={inputId}>
        {label}
        {hint ? <span className="field-checkbox__hint">{hint}</span> : null}
      </label>
    </div>
  )
})
