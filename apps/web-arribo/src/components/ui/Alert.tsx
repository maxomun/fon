interface AlertProps {
  variant?: 'error' | 'info' | 'success'
  children: string
}

export function Alert({ variant = 'info', children }: AlertProps) {
  return <div className={`alert alert-${variant}`}>{children}</div>
}
