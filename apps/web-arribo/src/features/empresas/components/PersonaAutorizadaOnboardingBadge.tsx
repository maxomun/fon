import type { PersonaAutorizada } from '@/features/empresas/types/personaAutorizada.types'
import {
  personaOnboardingEstado,
  personaOnboardingLabel,
} from '@/features/empresas/types/personaAutorizada.types'

export function PersonaAutorizadaOnboardingBadge({
  persona,
}: {
  persona: PersonaAutorizada
}) {
  const estado = personaOnboardingEstado(persona)
  const label = personaOnboardingLabel(persona)

  if (!label) {
    return null
  }

  const className =
    estado === 'completo'
      ? 'badge badge--success'
      : estado === 'sin_cuenta'
        ? 'badge badge--warning'
        : 'badge badge--pending'

  return <span className={className}>{label}</span>
}
