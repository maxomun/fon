import { Loader2 } from 'lucide-react'

interface LoadingScreenProps {
  message?: string
}

export function LoadingScreen({ message = 'Cargando…' }: LoadingScreenProps) {
  return (
    <div className="bg-background text-muted-foreground flex min-h-svh flex-col items-center justify-center gap-3">
      <Loader2 className="text-primary size-8 animate-spin" />
      <p className="text-sm">{message}</p>
    </div>
  )
}
