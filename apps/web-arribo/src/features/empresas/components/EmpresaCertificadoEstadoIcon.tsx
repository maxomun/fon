import type { Empresa } from '@/features/empresas/types/empresa.types'

interface EmpresaCertificadoEstadoIconProps {
  empresa: Pick<Empresa, 'tiene_certificado_vigente' | 'fecha_caducacion_certificado'>
}

function formatFechaCorta(value: string) {
  return new Date(`${value}T00:00:00`).toLocaleDateString('es-CL', {
    day: '2-digit',
    month: '2-digit',
    year: '2-digit',
  })
}

function CertificadoIcon({ className }: { className?: string }) {
  return (
    <svg
      className={className}
      width="20"
      height="20"
      viewBox="0 0 24 24"
      fill="none"
      aria-hidden="true"
    >
      <path
        d="M12 2 4 6v6c0 5 3.4 9.7 8 11 4.6-1.3 8-6 8-11V6l-8-4Z"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinejoin="round"
      />
      <path
        d="m9.5 12 1.8 1.8L15 10"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  )
}

export function EmpresaCertificadoEstadoIcon({ empresa }: EmpresaCertificadoEstadoIconProps) {
  if (empresa.tiene_certificado_vigente) {
    return (
      <span
        className="empresa-certificado-estado empresa-certificado-estado--vigente"
        title={
          empresa.fecha_caducacion_certificado
            ? `Certificado vigente hasta ${formatFechaCorta(empresa.fecha_caducacion_certificado)}`
            : 'Certificado vigente'
        }
        aria-label="Certificado vigente"
      >
        <CertificadoIcon />
      </span>
    )
  }

  if (empresa.fecha_caducacion_certificado) {
    return (
      <span
        className="empresa-certificado-estado empresa-certificado-estado--caducado"
        title={`Certificado caducado el ${formatFechaCorta(empresa.fecha_caducacion_certificado)}`}
        aria-label={`Certificado caducado el ${formatFechaCorta(empresa.fecha_caducacion_certificado)}`}
      >
        <svg width="28" height="28" viewBox="0 0 28 28" fill="none" aria-hidden="true">
          <circle cx="14" cy="14" r="11" stroke="currentColor" strokeWidth="1.5" />
        </svg>
        <span className="empresa-certificado-estado__fecha">
          {formatFechaCorta(empresa.fecha_caducacion_certificado)}
        </span>
      </span>
    )
  }

  return (
    <span
      className="empresa-certificado-estado empresa-certificado-estado--sin-certificado"
      title="Sin certificado vigente"
      aria-label="Sin certificado vigente"
    >
      <CertificadoIcon />
    </span>
  )
}
