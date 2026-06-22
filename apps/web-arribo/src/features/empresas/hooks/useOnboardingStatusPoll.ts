import { useEffect } from 'react'
import type { PersonaAutorizada } from '@/features/empresas/types/personaAutorizada.types'
import { personaOnboardingEstado } from '@/features/empresas/types/personaAutorizada.types'

const POLL_INTERVAL_MS = 10_000

export function hasPendingOnboarding(personas: PersonaAutorizada[]) {
  return personas.some((persona) => personaOnboardingEstado(persona) !== 'completo')
}

export function useOnboardingStatusPoll(
  personas: PersonaAutorizada[],
  onRefresh: () => void | Promise<void>,
) {
  const hayPendientes = hasPendingOnboarding(personas)

  useEffect(() => {
    if (!hayPendientes) {
      return
    }

    function refreshIfVisible() {
      if (document.visibilityState === 'visible') {
        void onRefresh()
      }
    }

    const intervalId = window.setInterval(refreshIfVisible, POLL_INTERVAL_MS)

    function onVisibilityChange() {
      if (document.visibilityState === 'visible') {
        void onRefresh()
      }
    }

    document.addEventListener('visibilitychange', onVisibilityChange)

    return () => {
      window.clearInterval(intervalId)
      document.removeEventListener('visibilitychange', onVisibilityChange)
    }
  }, [hayPendientes, onRefresh])
}
