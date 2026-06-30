# Referencias en DTE tipo 33 — Análisis por fases

Documento de implementación derivado de `PROMPT_PROGRAMADOR_REFERENCIA.md`.

**Objetivo:** ingresar, validar, persistir y serializar referencias SII en facturas electrónicas (33), con reflejo en XML y PDF.

**Scripts SQL (ejecución manual):**

1. `apps/db/manual/tipo_referencia_documentos.sql`
2. `apps/db/manual/documento_emitido_referencias.sql`

---

## Estado actual

| Capa | Situación |
|------|-----------|
| **XML** | `GeneradorXml` emite `<Referencia>` entre DscRcgGlobal y TED (R2) |
| **BD** | `documento_emitido_referencias` persistido en emisión (R2) |
| **API** | Validación `referencias[]`, catálogo, búsqueda emitidos para referencia (R1 + R5) |
| **UI** | Wizard con referencias + búsqueda DTE internos + atajo desde detalle (R3 + R5) |
| **PDF** | `PresentadorDocumento` + plantilla ERB muestran referencias (R4) |

**Patrón a replicar:** descuentos/recargos globales (`documento_descuentos_recargos_globales` + `Dte::DescuentosRecargos::*` + `EmisionGlobalesEditor`).

---

## Decisiones de diseño

### 1. Tabla propia vs. reutilizar columnas existentes

| Campo actual | Uso real | ¿Servir para Referencia SII? |
|--------------|----------|------------------------------|
| `referencia_id` | Auto-referencia integración | No |
| `asociado_id` | Padre NC/ND (un solo FK) | No (una NC puede tener varias referencias; además semántica distinta) |

**Decisión:** tabla `documento_emitido_referencias` (1:N) + catálogo `tipo_referencia_documentos`.

### 2. Catálogo separado de `tipo_documentos`

`801`, `802`, documentos manuales (`30`, `50`, …) no son tipos emitibles en FacturaOn pero sí válidos como `TpoDocRef`. Catálogo dedicado evita hardcode en XML y cumple criterio 8 del prompt.

### 3. `CodRef` en factura 33

Opcional. Solo enviar en XML si el usuario lo ingresa y el tipo lo permite (`permite_codigo_referencia`). Para 33, en la práctica suele omitirse.

### 4. Multipágina (clasificador de ítems)

Cada página genera un nodo `<DTE>` con folio propio. **Decisión recomendada (Fase 2):** repetir el mismo bloque `<Referencia>` en **todas las páginas** del mismo envío (conservador para validación SII). Alternativa: solo página 1 (validar con set de pruebas).

### 5. Vínculo opcional a DTE interno

`documento_emitido_origen_id` nullable: si el usuario elige una guía 52 ya emitida en FacturaOn, prellenar folio/fecha y guardar FK. Fase 4 (mejora UX), no bloqueante para Fase 1–3.

---

## Modelo de datos

```
tipo_referencia_documentos
  codigo_sii → TpoDocRef en XML

documento_emitido_referencias
  documento_emitido_id
  nro_linea → NroLinRef
  tipo_referencia_documento_id → TpoDocRef
  folio_referencia → FolioRef (max 18)
  fecha_referencia → FchRef
  codigo_referencia → CodRef (opcional)
  razon_referencia → RazonRef (max 90)
  documento_emitido_origen_id (opcional)
  orden
```

### Límites SII (validación)

| Campo | Regla |
|-------|--------|
| Referencias por DTE | 0..40 (límite práctico; confirmar en esquema vigente) |
| `nro_linea` | 1..N correlativo, único por documento |
| `folio_referencia` | obligatorio, max 18 caracteres |
| `fecha_referencia` | obligatoria, `YYYY-MM-DD` |
| `razon_referencia` | opcional, max 90 |
| `codigo_referencia` | 1–4 si se envía; no enviar nodo vacío |

---

## Flujo de datos (target)

```
UI referencias[]
    → POST /dte/generar { ..., referencias: [...] }
    → Dte::Referencias::Validador
    → construir_estructura_dte (referencias en documento/páginas)
    → GeneradorXml#construir_referencias (después DscRcgGlobal, antes TED)
    → Firmador (sin cambio de orden)
    → PersistidorDocumento → documento_emitido_referencias
    → PresentadorDocumento → PDF
```

---

## Fases de implementación

### Fase R0 — Base de datos y modelos

**Entregable:** tablas + modelos Rails + seeds vía SQL manual.

- [x] Ejecutar `tipo_referencia_documentos.sql`
- [x] Ejecutar `documento_emitido_referencias.sql`
- [x] Modelos: `TipoReferenciaDocumento`, `DocumentoEmitidoReferencia`
- [x] `DocumentoEmitido has_many :documento_emitido_referencias`
- [x] `schema.rb` actualizado (`version: 2026_06_29_000001`)

**Esfuerzo:** S · **Riesgo:** bajo

---

### Fase R1 — API: validación y catálogo

**Entregable:** aceptar y validar `referencias` sin romper emisión sin referencias.

Archivos nuevos sugeridos:

```
app/services/dte/referencias/validador.rb
app/services/dte/referencias/normalizador.rb
app/controllers/concerns/dte_referencias_params.rb
app/controllers/api/v1/tipo_referencia_documentos_controller.rb  # GET catálogo activo
```

Cambios:

- [x] `validar_params_preparar` + validación referencias solo si array presente
- [x] `referencias_raw` en controller (como `descuentos_recargos_globales_raw`)
- [x] Reglas: tipo en catálogo activo, folio/fecha obligatorios, correlativo `nro_linea`
- [x] Para `tipo_documento == 33`: `codigo_referencia` opcional
- [x] Endpoint `GET /api/v1/tipo_referencia_documentos` (filtro `q`, `categoria`)
- [x] Script: `script/verify_referencias_r1_api.rb`

**Request ejemplo:**

```json
{
  "empresa_id": 155,
  "tipo_documento": 33,
  "receptor": { ... },
  "items": [ ... ],
  "referencias": [
    {
      "tipo_documento_referencia": "52",
      "folio_referencia": "4589",
      "fecha_referencia": "2026-06-29",
      "razon_referencia": "Facturación de guía de despacho"
    }
  ]
}
```

**Esfuerzo:** S–M · **Depende de:** R0

---

### Fase R2 — XML + persistencia + firma

**Entregable:** referencias en XML firmado y en BD.

Cambios:

- [x] `construir_estructura_dte`: incluir `referencias` normalizadas en estructura (nivel documento, propagar a `paginas`)
- [x] `GeneradorXml#construir_documento`: llamar `construir_referencias` entre globales y TED
- [x] Omitir `<CodRef>` si nil; omitir `<RazonRef>` si blank
- [x] `PersistidorDocumento`: persistir referencias por cada `documento_emitido` creado
- [x] Script verificación XML: `script/verify_referencias_r2_xml.rb`
- [x] Regresión: emitir 33 **sin** referencias sigue igual

**Esfuerzo:** M · **Depende de:** R1 · **Criterios:** 1, 4, 5, 10 del prompt

---

### Fase R3 — UI emisión factura 33

**Entregable:** editor de referencias en wizard (como globales).

Archivos sugeridos:

```
web-arribo/src/features/emision/components/EmisionReferenciasEditor.tsx
web-arribo/src/features/emision/utils/validarReferenciasEmision.ts
web-arribo/src/features/emision/services/tipoReferenciaDocumentosService.ts
```

Cambios:

- [x] Tipos `EmisionReferencia`, `EmisionReferenciaRequest` en `emision.types.ts`
- [x] `EmisionGenerarRequest.referencias?`
- [x] `useEmisionWizard`: estado `referencias[]`, incluir en `emitir()` (no en `calcular_totales`)
- [x] UI: agregar/quitar filas, select tipo (desde API), folio, fecha, razón, cod ref condicional
- [x] Validación cliente alineada con API (`validarReferenciasEmision.ts`)
- [x] Máximo de filas coherente con backend (`MAX_REFERENCIAS = 40`)

**Esfuerzo:** M · **Depende de:** R1, R2 · **Criterios:** 2, 3, 7

---

### Fase R4 — PDF y detalle documento

**Entregable:** referencias visibles post-emisión.

- [x] `PresentadorDocumento#referencias_payload` desde `documento_emitido_referencias`
- [x] Plantilla `app/views/dte/pdf/_referencias.html.erb` (tabla tipo, folio, fecha, motivo)
- [x] `documento_emitido_detail_payload`: incluir `referencias[]`
- [x] `DocumentoDetalleModal` (front): sección referencias
- [x] Script: `script/verify_referencias_r4_pdf.rb`

**Esfuerzo:** S · **Depende de:** R2 · **Criterio:** 6

---

### Fase R5 — Mejoras (opcional)

- [x] Buscar DTE interno por tipo+folio y prellenar referencia (`documento_emitido_origen_id`)
- [x] Caso DTE emitido en FacturaOn → botón “Referenciar en emisión”
- [x] Validación de vínculo origen en `Dte::Referencias::DocumentoOrigen`
- [x] Auditoría: metadata `referencias_count` en `dte.emitir`
- [x] Script: `script/verify_referencias_r5_busqueda.rb`

**Esfuerzo:** M–L

---

## Mapa de archivos a tocar

### API (por fase)

| Fase | Archivos |
|------|----------|
| R0 | `app/models/tipo_referencia_documento.rb`, `documento_emitido_referencia.rb` |
| R1 | `dte_controller.rb`, `dte_referencias_params.rb`, `referencias/validador.rb` |
| R2 | `generador_xml.rb`, `persistidor_documento.rb`, `dte_controller.rb` (`construir_estructura_dte`) |
| R4 | `presentador_documento.rb`, `documento_emitido_serializable.rb`, plantilla PDF |

### Front (por fase)

| Fase | Archivos |
|------|----------|
| R3 | `useEmisionWizard.ts`, `EmpresaEmitirWizardPage.tsx`, `emision.types.ts`, `dteService.ts` |
| R4 | `DocumentoDetalleModal.tsx`, `documentoEmitido.types.ts` |

---

## Orden recomendado y paralelización

```
R0 (BD) → R1 (API validación) → R2 (XML) ─┬→ R3 (UI emisión)
                                           └→ R4 (PDF/detalle)
R5 después
```

R3 y R4 pueden avanzar en paralelo una vez R2 esté en staging.

---

## Riesgos

| Riesgo | Mitigación |
|--------|------------|
| Firma XML inválida al insertar Referencia | Script verificación + comparar con ejemplo SII |
| Confundir `asociado_id` con referencias 33 | Documentar; no reutilizar ese campo |
| Multipágina sin referencias en todas las hojas | Decisión explícita Fase R2; test multipágina |
| Catálogo incompleto | Semilla amplia; admin futuro de `tipo_referencia_documentos` |

---

## Criterios de aceptación (checklist)

- [ ] FE 33 sin referencias
- [ ] FE 33 con una referencia (52, 801 o 802)
- [ ] FE 33 con múltiples referencias
- [ ] XML: Referencia después de DscRcgGlobal y antes de TED
- [ ] NroLinRef correlativo
- [ ] PDF con sección Referencias
- [ ] BD + XML + PDF coherentes
- [ ] CodRef omitido en 33 cuando no aplica
- [ ] Firma válida post-cambio

---

## Próximo paso al retomar

1. Ejecutar los dos SQL en orden.
2. Implementar **Fase R0 + R1** (modelos + validador + catálogo API).
3. Probar con `POST /dte/generar` manual (curl) antes de UI.

Prompt sugerido:

> Lee `api-firma/docs/REFERENCIAS_DTE_FASES.md`. SQL ya ejecutados. Implementa Fase R0 y R1.

---

## Changelog

| Fecha | Cambio |
|-------|--------|
| 2026-06-29 | Análisis inicial y scripts SQL |
