import { Link } from 'react-router-dom'
import type { PrerrequisitoItem } from '@/features/emision/types/prerrequisitos.types'

interface EmisionPrerrequisitosChecklistProps {
  items: PrerrequisitoItem[]
  puedeGestionarCertificados: boolean
}

function estadoIcon(estado: PrerrequisitoItem['estado']) {
  return estado === 'ok' ? '✓' : '!'
}

export function EmisionPrerrequisitosChecklist({
  items,
  puedeGestionarCertificados,
}: EmisionPrerrequisitosChecklistProps) {
  return (
    <ul className="emision-checklist">
      {items.map((item) => {
        const mostrarLinkCertificados =
          item.id === 'certificado' ? puedeGestionarCertificados : true
        const linkTo = mostrarLinkCertificados ? item.linkTo : undefined

        return (
          <li
            key={item.id}
            className={`emision-checklist__item emision-checklist__item--${item.estado}`}
          >
            <div
              className={`emision-checklist__icon emision-checklist__icon--${item.estado}`}
              aria-hidden
            >
              {estadoIcon(item.estado)}
            </div>

            <div className="emision-checklist__content">
              <h3 className="emision-checklist__title">{item.titulo}</h3>
              <p className="emision-checklist__message">{item.mensaje}</p>

              {item.estado === 'pendiente' ? (
                <div className="emision-checklist__actions">
                  {linkTo && item.linkLabel ? (
                    <Link className="emision-checklist__link" to={linkTo}>
                      {item.linkLabel}
                    </Link>
                  ) : item.ayudaSinLink ? (
                    <p className="emision-checklist__hint">{item.ayudaSinLink}</p>
                  ) : null}
                </div>
              ) : null}
            </div>
          </li>
        )
      })}
    </ul>
  )
}
