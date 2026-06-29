export const aboutConfig = {
  productName: 'FacturaOn',
  productSubtitle: 'Portal Arribo',
  developerName: 'FON',
  developerDescription: 'Plataforma de facturación electrónica',
  copyrightYear: new Date().getFullYear(),
} as const

export function getAppVersion(): string {
  return import.meta.env.VITE_APP_VERSION || '0.0.0'
}

export function getBuildDateLabel(): string | null {
  const value = import.meta.env.VITE_BUILD_DATE?.trim()
  if (!value) {
    return null
  }

  const date = new Date(value)
  if (Number.isNaN(date.getTime())) {
    return value
  }

  return date.toLocaleDateString('es-CL', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  })
}
