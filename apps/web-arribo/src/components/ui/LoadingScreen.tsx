interface LoadingScreenProps {
  message?: string
}

export function LoadingScreen({ message = 'Cargando…' }: LoadingScreenProps) {
  return (
    <div className="loading-screen">
      <p>{message}</p>
    </div>
  )
}
