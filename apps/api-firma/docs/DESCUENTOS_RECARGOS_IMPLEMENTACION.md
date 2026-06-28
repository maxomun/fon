# Implementación: descuentos y recargos DTE

Spec de negocio: [`prompt-descuentos-y-recargos.md`](./prompt-descuentos-y-recargos.md)

## Secuencia guiada

| Fase | Estado | Entregable | Verificación |
|------|--------|------------|--------------|
| **F0** Fundamentos | ✅ | `app/services/dte/descuentos_recargos/constants.rb`, value objects | Carga Rails OK |
| **F1** Línea completa (desc/rec) | ✅ | `preparar_items`, `GeneradorXml` | `script/verify_descuentos_recargos_f1_linea.rb` |
| **F2** 3 ámbitos (no facturable) | ✅ | `ambito_monto` producto + venta_detalles | `script/verify_descuentos_recargos_f2_ambito.rb` |
| **F3** Motor aislado | ✅ | `CalculadorDocumento` | `script/verify_descuentos_recargos_standalone.rb` |
| **F4** Validaciones + contrato API | ✅ | `ParserMovimientos`, `POST /dte/calcular_totales` | `script/verify_descuentos_recargos_f4_api.rb` |
| **F5** Pipeline `generar` | ✅ | `IntegradorPagina` en `construir_estructura_dte` | `script/verify_descuentos_recargos_f5_pipeline.rb` |
| **F6** Persistencia BD | ✅ | `documento_descuentos_recargos_globales` | `script/verify_descuentos_recargos_f6_persistencia.rb` |
| **F7** XML `<DscRcgGlobal>` | ✅ | `GeneradorXml` | `script/verify_descuentos_recargos_f7_xml.rb` |
| **F8** Front wizard | ✅ | UI movimientos globales + preview API | Wizard emitir FE 33 |
| **F9** Certificación | ⏸️ Pendiente | Checklist SET BÁSICO | 4919151-1 a 4 (manual / certificación) |

**Estado actual:** F0–F8 completadas. F9 queda **pendiente a propósito** hasta ejecutar la certificación SII (SET BÁSICO atención 4919151) con emisión real, revisión de XML/PDF y checklist caso a caso. No bloquea el uso funcional de descuentos/recargos en emisión FE 33.

## Verificar F5 (pipeline emisión)

```bash
cd apps/api-firma
ruby script/verify_descuentos_recargos_f5_pipeline.rb
```

`POST /preparar`, `POST /generar_xml`, `POST /firmar_xml` y `POST /generar` usan el calculador por página. Cada página incluye:

- `totales` — post-globales (listo para `GeneradorXml`)
- `descuentos_recargos_globales` — movimientos con `monto_calculado` (serializados en XML F7)

Los globales del request se aplican **por página** sobre los ítems de esa página.

## Verificar F7 (XML DscRcgGlobal)

```bash
cd apps/api-firma
ruby script/verify_descuentos_recargos_f7_xml.rb
```

`GeneradorXml` emite un nodo `<DscRcgGlobal>` por movimiento global (después de `<Detalle>`, antes de `<TED>`):

- `NroLinDR`, `TpoMov`, `GlosaDR`, `TpoValor` (`%` / `$`), `ValorDR`
- `IndExeDR` solo si aplica a exento (`1`) o no facturable (`2`); omitido en afectos

## Verificar F8 (wizard web)

En `web-arribo`, wizard **Emitir Factura Electrónica**:

1. Sección **Descuentos / recargos globales** — agregar movimientos (tipo, glosa, %/$ , ámbito).
2. Preview de totales vía `POST /api/v1/dte/calcular_totales` (debounced al editar ítems o globales).
3. Columna **Monto calc.** muestra el valor devuelto por el servidor.
4. Al emitir, el request incluye `descuentos_recargos_globales[]`.

Archivos principales:

```
web-arribo/src/features/emision/
  components/EmisionGlobalesEditor.tsx
  hooks/useEmisionWizard.ts
  utils/calcularTotalesEmision.ts
  services/dteService.ts
```

## Verificar F6 (persistencia BD)

```bash
cd apps/api-firma
ruby script/verify_descuentos_recargos_f6_persistencia.rb
```

Tras `POST /generar`, cada `documento_emitido` persiste filas en `documento_descuentos_recargos_globales` (cascade al limpiar envío FON).

Migración manual BD:

```bash
docker compose exec -T postgres psql -U fon -d fon_dev -f - < apps/db/manual/documento_descuentos_recargos_globales.sql
```

El detalle de documento (`GET /empresas/:id/documentos_emitidos/:id`) incluye `descuentos_recargos_globales[]`.

## Verificar F4 (contrato API)

```bash
cd apps/api-firma
ruby script/verify_descuentos_recargos_f4_api.rb
```

### Endpoint preview

`POST /api/v1/dte/calcular_totales` (JWT + vínculo empresa)

Mismo body que `/preparar`, con `descuentos_recargos_globales` opcional.

Respuesta exitosa:

```json
{
  "success": true,
  "data": {
    "subtotales": {
      "AFECTO": 6832464,
      "EXENTO_NO_AFECTO": 13726,
      "NO_FACTURABLE": 0
    },
    "totales": {
      "neto_afecto": 4782725,
      "neto_exento": 13726,
      "neto_no_facturable": 0,
      "tasa_iva": 19.0,
      "iva": 908717,
      "total": 5705168
    },
    "descuentos_recargos_globales": [
      {
        "nro_linea": 1,
        "tipo_movimiento": "D",
        "glosa": "Descuento comercial",
        "tipo_valor": "PORCENTAJE",
        "valor": 30.0,
        "aplica_sobre": "AFECTO",
        "monto_calculado": 2049739,
        "orden": 1
      }
    ]
  }
}
```

Error de validación → `422` con `{ "success": false, "errors": ["..."] }`.

## Contrato `descuentos_recargos_globales`

Aceptado en `calcular_totales`, y validado estructuralmente en todos los endpoints que usan `validar_params_preparar` (`preparar`, `generar_xml`, `firmar_xml`, `generar`).

```json
{
  "empresa_id": 1,
  "tipo_documento": 33,
  "receptor": { "rut": "...", "razon_social": "...", "giro": "...", "direccion": "..." },
  "items": [{ "producto_id": 1, "cantidad": 2, "descuento_pct": 0 }],
  "descuentos_recargos_globales": [
    {
      "tipo_movimiento": "D",
      "glosa": "Descuento comercial",
      "tipo_valor": "PORCENTAJE",
      "valor": 30,
      "aplica_sobre": "AFECTO"
    }
  ]
}
```

| Campo | Requerido | Valores |
|-------|-----------|---------|
| `tipo_movimiento` | Sí | `D` (descuento), `R` (recargo) |
| `tipo_valor` | Sí | `PORCENTAJE`, `%`, `MONTO`, `$` |
| `valor` | Sí | > 0; si %, ≤ 100 |
| `aplica_sobre` | Sí | `AFECTO`, `EXENTO_NO_AFECTO`, `NO_FACTURABLE` |
| `glosa` | No | default al generar XML |

Máximo **20** movimientos por documento.

## Verificar F3 (motor global)

```bash
cd apps/api-firma
ruby script/verify_descuentos_recargos_standalone.rb
```

## Verificar F2 (clasificación ámbito)

```bash
cd apps/api-firma
ruby script/verify_descuentos_recargos_f2_ambito.rb
```

Migración manual BD:

```bash
docker compose exec -T postgres psql -U fon -d fon_dev -f - < apps/db/manual/productos_ambito_monto.sql
```

## Verificar F1 (línea desc/rec)

```bash
cd apps/api-firma
ruby script/verify_descuentos_recargos_f1_linea.rb
```

Request por ítem (API):

```json
{
  "producto_id": 1,
  "cantidad": 2,
  "descuento_pct": 10,
  "recargo_pct": 0,
  "descuento": 0,
  "recargo": 500
}
```

`descuento` / `recargo` = monto fijo; `descuento_pct` / `recargo_pct` = porcentaje sobre bruto de la línea.

## Decisiones F0

- **Paginación:** globales se aplican sobre ítems de cada página/folio.
- **No facturable:** F2 agregará clasificación; calculador ya lo soporta.
- **Glosa vacía:** default `Descuento comercial` / `Recargo`.
- **IVA:** recalculado sobre `neto_afecto` final post-globales (`.to_i` truncado, igual que hoy).

## Módulos

```
app/services/dte/descuentos_recargos/
  constants.rb
  error.rb
  clasificacion_monto.rb
  movimiento_global.rb
  linea_calculada.rb
  totales_documento.rb
  bases_documento.rb
  parser_movimientos.rb
  procesador_movimientos_globales.rb
  validador_movimientos.rb
  calculador_documento.rb
  integrador_pagina.rb

app/models/
  documento_descuento_recargo_global.rb

app/controllers/concerns/
  dte_descuentos_recargos_params.rb
```

## F9 — pendiente (certificación)

Cuando se retome:

1. Emitir desde wizard o API los casos **4919151-1** a **4919151-4** ([`docs/sii/certificacion/SIISetDePruebas120230638.txt`](./sii/certificacion/SIISetDePruebas120230638.txt)).
2. Verificar totales, `<DscRcgGlobal>` en XML (caso 4) y representación impresa.
3. Ejecutar regresión: scripts `verify_descuentos_recargos_f1_linea.rb` … `f7_xml.rb`.
4. Documentar resultados en checklist (pass/fail por caso).

Casos **4919151-5+** (NC/ND con referencias) quedan fuera del alcance de esta iteración de descuentos/recargos.
