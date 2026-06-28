# Implementación: PDF DTE

Insumos de negocio: [`prompt-para-generacion-pdf.txt`](./prompt-para-generacion-pdf.txt), [`prompt-especificacion-tamano-pdf.txt`](./prompt-especificacion-tamano-pdf.txt), [`plantilla-pdf-dte.html`](./plantilla-pdf-dte.html)

## Secuencia

| Fase | Estado | Entregable |
|------|--------|------------|
| **PDF-0** Fundamentos | ✅ | Plantilla ERB + `PresentadorDocumento` |
| **PDF-1** MVP A4 FE 33 | ✅ | Grover + Active Storage + `GET .../pdf` |
| **PDF-1b** Post-emisión | ✅ | `GeneradorLote` en `POST /dte/generar` (fallo no bloquea emisión) |
| **PDF-2** TED PDF417 | ✅ | `LectorTedXml` + `SerializadorTed` + `GeneradorPdf417` (bwip-js) |
| **PDF-3** Multipágina CSS | ✅ | Desborde: encabezado fijo, thead repetido, cierre al final |
| **PDF-4** Integración UX | ⏸️ | Auditoría ampliada, reintentos automáticos |
| **PDF-5** Ticket 80 mm | ⏸️ | Boletas 39/41 |

## Principios

- **Un PDF por `documento_emitido`** (folio), nunca por `dte_envio`.
- **No recalcular montos**: totales desde XML firmado del envío (nodo `<DTE>` del folio).
- **Líneas y globales** desde BD (`venta_detalles`, `documento_descuentos_recargos_globales`).
- **HTML + CSS → PDF** (Grover/Chromium). Prawn en `ClasificadorItems` reparte ítems en **varios DTE** al emitir; el CSS multipágina cubre el **desborde** cuando el layout HTML real excede una hoja A4 en un mismo folio.

## Multipágina por desborde (PDF-3)

En emisión normal cada `documento_emitido` debería caber en una hoja (`ClasificadorItems`). Si el PDF HTML se desborda (descripciones largas, más columnas que la simulación Prawn, etc.):

- **Encabezado reducido** (`position: fixed`) en cada hoja
- **Encabezado completo** + emisor/receptor solo al inicio
- **Columnas del detalle** repetidas (`thead { display: table-header-group }`)
- **Globales, totales, TED y pie** en bloque `.cierre-documento` solo al final

## Módulos

```
app/services/dte/pdf/
  presentador_documento.rb
  lector_totales_xml.rb
  generador.rb
  generador_lote.rb
  generador_pdf417.rb
  lector_ted_xml.rb
  serializador_ted.rb
  nombre_archivo.rb
  formateador.rb

app/views/dte/pdf/
  documento.html.erb
  _encabezado.html.erb
  _encabezado_reducido.html.erb
  _estilos.html.erb
  _detalle.html.erb
  _globales.html.erb
  _totales.html.erb
  _ted.html.erb
  _cierre_documento.html.erb
```

## Flujo post-emisión

Tras persistir el DTE y archivar el XML (`ArchivadorXml`), `POST /api/v1/dte/generar` invoca `Dte::Pdf::GeneradorLote` para cada `documento_emitido`.

- Si el PDF falla, **la emisión sigue siendo exitosa** (el DTE ya está firmado y en BD).
- Se audita el fallo (`fase: generacion_pdf`) y la respuesta incluye `advertencia` + `pdf_fallos`.
- Cada documento en la respuesta trae `pdf_disponible: true/false`.
- Reintento manual: `GET .../pdf?force=true`.

## Endpoint descarga

`GET /api/v1/empresas/:empresa_id/documentos_emitidos/:id/pdf`

Query opcional: `force=true` para regenerar.

Idempotente: si ya existe PDF adjunto y `force=false`, devuelve el existente.

## Verificar PDF-3 (multipágina / desborde)

```bash
cd apps/api-firma
bundle exec ruby script/verify_pdf_dte_multipagina.rb
```

Regenerar un PDF largo con `?force=true` y revisar visualmente que totales/TED queden en la última hoja.

## Verificar PDF-2 (TED PDF417)

```bash
cd apps/api-firma
npm install --omit=dev
ruby script/verify_pdf_dte_ted.rb
```

Regenerar PDF con timbre:

```bash
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:3026/api/v1/empresas/155/documentos_emitidos/7/pdf?force=true" \
  -o factura.pdf
```

## Verificar PDF-1

```bash
cd apps/api-firma
ruby script/verify_pdf_dte_presentador.rb
```

Con API y Chromium (Docker):

```bash
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:3026/api/v1/empresas/155/documentos_emitidos/4/pdf" \
  -o factura.pdf
```

## Docker

Grover requiere **Node.js**, **puppeteer** (`npm install`) y **Chromium** en el contenedor.

Variables:

- `GROVER_EXECUTABLE_PATH` (default `/usr/bin/chromium`)
- `GROVER_NO_SANDBOX=true`
- `PUPPETEER_SKIP_DOWNLOAD=true` (usa Chromium del sistema, no descarga otro)
- `PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium`

Tras cambiar `package.json`, reconstruir y reiniciar:

```bash
docker compose build facturaon-api
docker compose up -d facturaon-api
```

Con volumen `.:/app`, el entrypoint instala `node_modules` si falta al arrancar.

## Logo empresa (L1 + L2)

Backend para logo optimizado en PDF (front L3 ✅, PDF L4 ✅).

| Pieza | Detalle |
|-------|---------|
| Modelo | `Empresa#logo` (`has_one_attached`) + sync `archivo_logo` |
| Procesador | `Empresas::ProcesadorLogo` — PNG/JPEG/WebP, proporción 2:1–4:1, resize 540×180, ≤150 KB |
| Endpoints | `GET/POST/DELETE /api/v1/empresas/:id/logo` (POST: form-data `archivo`) |
| Payload | `empresa.logo` → `{ disponible, url, filename, content_type, byte_size }` |
| PDF | `PresentadorDocumento#logo_data_uri` → `<img>` en `_encabezado.html.erb`; sin logo = espacio vacío |

```bash
cd apps/api-firma
ruby script/verify_empresa_logo_procesador.rb

# Subir logo (admin FON)
curl -X POST -H "Authorization: Bearer $TOKEN" \
  -F "archivo=@logo.png" \
  "http://localhost:3026/api/v1/empresas/155/logo"
```

### L4 — Logo en PDF

- `Dte::Pdf::PresentadorDocumento` expone `logo_data_uri` (data URI desde Active Storage).
- `_encabezado.html.erb`: imagen si hay logo; si no, caja vacía 180×60 sin texto ni borde.

Regenerar PDF con logo:

```bash
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:3026/api/v1/empresas/155/documentos_emitidos/7/pdf?force=true" \
  -o factura.pdf
```

### L3 — Front (web-arribo)

- Sección **Logo para PDF** en editar empresa (`EmpresaLogoSection`)
- Validación cliente: formato, 5 MB, proporción ~3:1, mínimo 180×60 px
- Vista previa autenticada vía `GET /empresas/:id/logo`
