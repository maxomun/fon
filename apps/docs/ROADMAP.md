# FacturaOn — Roadmap y estado del proyecto

Documento de continuidad para retomar el desarrollo. Actualizar al cerrar sesiones de trabajo relevantes.

**Monorepo:** `/apps`  
**Última actualización:** 2026-06-29

---

## Cómo retomar este proyecto en Cursor

1. Abrir el workspace en `/apps` (o el repo raíz `fon`).
2. Iniciar un chat nuevo y referenciar este archivo: `@docs/ROADMAP.md`.
3. Indicar la fase o ítem concreto a continuar (ej. *“Fase M1 — shell multi-tipo DTE”*).
4. Revisar `git log --oneline -20` para cambios recientes no documentados aquí.

Documentación técnica adicional:

| Área | Ubicación |
|------|-----------|
| API DTE / firma | `api-firma/docs/ARQUITECTURA_DTE.md` |
| Algoritmo XML tipo 33 | `api-firma/docs/ALGORITMO_GENERAR_XML_33.md` |
| PDF DTE | `api-firma/docs/especificaciones-pdf/IMPLEMENTACION.md` |
| Descuentos/recargos | `api-firma/docs/DESCUENTOS_RECARGOS_IMPLEMENTACION.md` |
| Set certificación SII | `api-firma/docs/sii/certificacion/SIISetDePruebas120230638.txt` |
| Front local | `web-arribo/docs/DESARROLLO_LOCAL.md` |
| BD local | `db/README.md` |

---

## Arquitectura resumida

```
apps/
├── api-firma/     Rails API — DTE, empresas, productos, firma, PDF
├── web-arribo/    React/Vite — Portal Arribo (UI operadores)
├── db/            PostgreSQL local, dumps, scripts
└── docs/          Este roadmap (contexto transversal)
```

---

## Completado recientemente

### Portal — Header y cuenta (Propuesta A Gmail)

- Menú de cuenta con avatar + popover (nombre, email, Acerca de, Cerrar sesión).
- Sin badges de rol en el header (roles siguen en Dashboard).
- Modal **Acerca de** con versión del portal y versión de la API.
- Versión portal: `package.json` → `VITE_APP_VERSION` (vite.config.ts).
- Versión API: `GET /api/v1/version` ← `config/version.rb` (`APP_VERSION` en deploy).

Archivos clave:

- `web-arribo/src/components/layout/UserAccountMenu.tsx`
- `web-arribo/src/components/layout/AboutModal.tsx`
- `web-arribo/src/config/about.ts`
- `api-firma/app/controllers/api/v1/version_controller.rb`
- `api-firma/config/version.rb`

### Tablas interactivas (zebra, hover, selección)

Patrón: `data-table--interactive`, `useTableRowSelection`, `buildInteractiveRowProps`, `stopRowClickPropagation` en columna acciones.

Aplicado en: documentos, auditoría, productos, empresas, usuarios, impuestos, actecos, tipos documento, personas autorizadas, rangos folios, certificados.  
Solo lectura: líneas en `DocumentoDetalleModal` (`data-table--readonly`).

Utilidades: `web-arribo/src/hooks/useTableRowSelection.ts`, `web-arribo/src/lib/interactiveTableRow.ts`

### Vista previa PDF/XML

- Modal autenticado con blob URL; botones Ver PDF / Ver XML en listado y detalle.

### Logo empresa (L1–L4)

- Active Storage, API logo, sección en editar empresa, PDF con `logo_data_uri`.

### Auditoría — filtro empresa V1

- Select precargado de empresas en lugar de input numérico; soporte `sin_empresa` en backend.

### Productos — duplicar

- Menú ⋮ → **Duplicar**: copia con `{codigo}_copia` y `{nombre}_copia`; resuelve colisión de código (`_copia_2`, etc.).
- Reutiliza `POST /productos` (sin endpoint dedicado).

Archivos: `producto.types.ts` (`productoDuplicadoInput`), `ProductoRowActions.tsx`, `EmpresaProductosPage.tsx`

### Emisión DTE tipo 33 (estado funcional base)

- Wizard `/empresas/:id/emitir` → `/empresas/:id/emitir/nuevo`
- Receptor, líneas por producto, descuentos/recargos globales, preview totales, generación firmada.
- Pipeline API: preparar → folios → XML → firmar → persistir → PDF.

---

## En progreso / diseñado (sin implementar)

### Multi-tipo DTE (certificación SII)

**Situación:** solo se emite **tipo 33** end-to-end. El set de certificación exige además **34, 52, 56, 61** (y registrar **46** en libro de compras).

**Decisión de UI acordada:** tabs en `/empresas/:id/emitir/nuevo` por **familia** de documento, no un formulario único con otro código.

| Tab | Tipos | Reutiliza wizard actual |
|-----|-------|-------------------------|
| Factura | 33, 34 | Sí (~80 %) |
| Nota crédito / débito | 61, 56 | Parcial (falta documento origen) |
| Guía de despacho | 52 | No (modelo distinto) |
| Factura de compra | 46 | No (proveedor + retenciones) |

**Familias técnicas:**

- **A (venta):** 33, 34 — mismo wizard; 34 exige validación solo exento/sin IVA.
- **B (ajustes):** 56, 61 — referencia obligatoria al documento origen, `<Referencia>` XML, `asociado_id`.
- **C (otros):** 52 guía traslado; 46 compra con retenciones.

**Backend hoy:**

- Folios, firma, persistencia: genéricos por `tipo_documento`.
- `GeneradorXml`: estructura de factura venta; **sin** `<Referencia>`.
- `PersistidorDocumento`: no asigna `asociado_id`.
- Catálogo BD: falta tipo **52** en `tipo_documentos`.

Ver análisis detallado en sección [Roadmap multi-tipo](#roadmap-multi-tipo-dte) más abajo.

### Auditoría V2/V3 (mencionado, no implementado)

- V2: combobox buscable de empresas.
- V3: búsqueda `q` también por razón social de empresa.

### Iconos en modal detalle documento

- Listado usa iconos; modal detalle aún con botones texto.

---

## Roadmap multi-tipo DTE

### Tipos según documentación SII (emisión electrónica)

| Código | Documento | En BD FacturaOn | Emisión implementada |
|--------|-----------|-----------------|----------------------|
| 33 | Factura Electrónica | Sí | Sí |
| 34 | Factura Exenta | Sí | No |
| 39 | Boleta | Sí | No |
| 41 | Boleta exenta | Sí | No |
| 43 | Liquidación factura | Sí | No |
| 46 | Factura de compra | Sí | No |
| 52 | Guía de despacho | **No** | No |
| 56 | Nota de débito | Sí | No |
| 61 | Nota de crédito | Sí | No |
| 110–112 | Exportación | No | No |

### Set certificación (`SIISetDePruebas120230638.txt`)

**5 tipos a emitir en casos:** 33, 34, 52, 56, 61.  
**46** aparece en indicaciones y libro de compras (registro), sin caso de emisión en el set.

Sets: básico (33+NC+ND), guía (52), factura exenta (34+NC+ND), libros LV/LC/LG.

### Fases propuestas

#### M0 — Fundación multi-tipo (prerrequisito)

- [ ] Quitar hardcode `FACTURA_ELECTRONICA_CODIGO` en front (`useEmisionWizard`, totales, títulos).
- [ ] Shell de tabs en `EmpresaEmitirWizardPage`; tabs visibles según `tipo_habilitados`.
- [ ] API: extraer validación/builder por tipo (`validar_por_tipo`, strategy en `GeneradorXml`).
- [ ] Tests regresión tipo 33.

Archivos front a tocar: `features/emision/**`, `config/pageMeta.ts`  
Archivos API: `dte_controller.rb`, `generador_xml.rb`

#### M1 — Tipo 34 (factura exenta)

- [ ] Validar líneas/totales sin neto afecto ni IVA.
- [ ] Sub-selector 33 vs 34 en tab Factura.
- [ ] Casos set 4919156-x.

Esfuerzo: **S**

#### M2 — Tipos 61 y 56 (NC / ND)

- [ ] Payload `referencias[]`; XML `<Referencia>`.
- [ ] UI: elegir documento emitido origen + motivo SII (`CodRef`, `RazonRef`).
- [ ] Persistir `asociado_id`.
- [ ] Casos set 4919151-5..8 y 4919156-2,4,5,7,8.

Esfuerzo: **M**

#### M3 — Tipo 52 (guía de despacho)

- [ ] Seed/migración `tipo_documentos` código 52.
- [ ] Wizard traslado (`IndTraslado`, tipo despacho, etc.).
- [ ] XML y PDF guía; casos 4919154-x.

Esfuerzo: **L**

#### M4 — Tipo 46 (factura de compra)

- [ ] Wizard proveedor; retenciones en XML si aplica.
- [ ] Registro libro de compras.

Esfuerzo: **L**

#### M5 — Libros electrónicos (post-certificación emisión)

- [ ] Libro ventas (4919152), compras (4919153), guías (4919155).

---

## Roadmap portal (UX / mantenedores)

| Ítem | Estado | Notas |
|------|--------|-------|
| Header estilo Gmail | Hecho | |
| About portal + API | Hecho | `APP_VERSION` / `VITE_APP_VERSION` |
| Tablas interactivas | Hecho | Todas las tablas principales |
| Duplicar producto | Hecho | |
| Refactor productos → hook helpers | Opcional | Productos aún puede unificarse más |
| Filtro auditoría V2/V3 | Pendiente | |
| Iconos modal detalle documento | Pendiente | |

---

## Roadmap API / infra

| Ítem | Estado | Notas |
|------|--------|-------|
| `GET /api/v1/version` | Hecho | Público, sin auth |
| Envío real al SII | Pendiente | `Dte::EnviadorSii` stub |
| Certificación F9 descuentos/recargos | Manual | Ver set de pruebas |
| PDF boletas 39/41 (ticket 80mm) | Pendiente | IMPLEMENTACION.md PDF-5 |
| Tipo 52 en catálogo | Pendiente | Migración/seed |

---

## Convenciones de desarrollo (recordatorio)

- Respuestas y UI en **español**.
- Commits solo cuando el usuario lo pida.
- Tablas: `data-table--interactive` + selección por fila; acciones con `stopRowClickPropagation`.
- Minimizar scope; reutilizar patrones existentes del monorepo.
- Versiones: portal en `web-arribo/package.json`; API en `APP_VERSION` al desplegar.

---

## Archivos clave por feature

### Emisión (solo 33 hoy)

```
web-arribo/src/features/emision/
api-firma/app/controllers/api/v1/dte_controller.rb
api-firma/app/services/dte/generador_xml.rb
api-firma/app/services/dte/persistidor_documento.rb
api-firma/app/models/documento_emitido.rb
```

### Header / About

```
web-arribo/src/components/layout/UserAccountMenu.tsx
web-arribo/src/components/layout/AboutModal.tsx
web-arribo/src/config/about.ts
api-firma/config/version.rb
```

### Productos

```
web-arribo/src/features/productos/
api-firma/app/controllers/api/v1/empresa_productos_controller.rb
```

---

## Changelog del documento

| Fecha | Cambio |
|-------|--------|
| 2026-06-29 | Creación inicial: estado portal, multi-tipo DTE, certificación, fases M0–M5 |

---

## Próximo paso recomendado al retomar

**Fase M0 + M1:** shell de tabs en emisión + soporte tipo 34, manteniendo regresión en 33. Es el entregable que valida la arquitectura UI acordada y avanza certificación (set factura exenta).

Prompt sugerido:

> Lee `docs/ROADMAP.md`. Continuamos con Fase M0 (fundación multi-tipo en emisión): tabs en el wizard, parametrizar `tipo_documento` en front y validadores por tipo en API.
