PROMPT PARA AGENTE PROGRAMADOR — REFERENCIAS EN DTE TIPO 33

Objetivo:
Implementar en la emisión de Factura Electrónica DTE Tipo 33 la capacidad de ingresar, almacenar, validar y serializar referencias en el XML del SII.

Contexto:
El DTE Tipo 33 puede contener una o varias referencias. Estas referencias permiten relacionar la factura con otros documentos, por ejemplo:

- Guía de Despacho Electrónica, Tipo 52.
- Orden de Compra, Tipo 801.
- Recepción de mercadería o servicios, Tipo 802.
- Otros DTE u otros documentos comerciales definidos por el SII.

La referencia NO debe tratarse como un simple campo de texto de la factura. Debe modelarse como una colección de referencias asociadas al DTE.

Estructura XML:
Dentro del XML del DTE 33, el nodo <Referencia> se ubica dentro de:

<DTE>
  <Documento>
    <Encabezado>
      ...
    </Encabezado>

    <Detalle>
      ...
    </Detalle>

    <DscRcgGlobal>
      ...
    </DscRcgGlobal>

    <Referencia>
      ...
    </Referencia>

    <TED>
      ...
    </TED>
  </Documento>

  <Signature>
    ...
  </Signature>
</DTE>

Ubicación:
- Después de los nodos <Detalle>.
- Después de <DscRcgGlobal>, si existen descuentos o recargos globales.
- Antes de <TED>.
- Antes de la firma XML.

Estructura de cada referencia:

<Referencia>
  <NroLinRef>1</NroLinRef>
  <TpoDocRef>52</TpoDocRef>
  <FolioRef>4589</FolioRef>
  <FchRef>2026-06-29</FchRef>
  <CodRef>1</CodRef>
  <RazonRef>Facturación de guía de despacho</RazonRef>
</Referencia>

Campos:

1) NroLinRef
Número correlativo de la referencia dentro del DTE.
Debe partir en 1 y aumentar secuencialmente.

2) TpoDocRef
Tipo de documento referenciado.
Puede ser un DTE u otro documento comercial definido por el SII.

Ejemplos frecuentes:
- 33: Factura Electrónica.
- 34: Factura Exenta Electrónica.
- 39: Boleta Electrónica.
- 41: Boleta Exenta Electrónica.
- 46: Factura de Compra Electrónica.
- 52: Guía de Despacho Electrónica.
- 56: Nota de Débito Electrónica.
- 61: Nota de Crédito Electrónica.
- 110: Factura de Exportación.
- 111: Nota de Débito de Exportación.
- 112: Nota de Crédito de Exportación.
- 801: Orden de Compra.
- 802: Nota de Pedido / Recepción de Mercadería o Servicios, según uso comercial del receptor.

3) FolioRef
Folio o número del documento referenciado.
Ejemplos:
- Folio de una guía de despacho.
- Número de orden de compra.
- Número de recepción de mercadería.
- Número de documento externo.

4) FchRef
Fecha del documento referenciado.
Formato:
YYYY-MM-DD

5) CodRef
Código de referencia.
No siempre aplica en una Factura 33.
Es más común y obligatorio en Notas de Crédito y Notas de Débito, donde indica si se anula, corrige texto o corrige montos.

Códigos comunes:
- 1: Anula documento de referencia.
- 2: Corrige texto del documento de referencia.
- 3: Corrige montos.
- 4: Anulación masiva.

Para Factura 33, este campo debe ser opcional y solo enviarse cuando corresponda según el caso de negocio y la regla SII aplicable.

6) RazonRef
Texto explicativo de la referencia.
Ejemplos:
- Facturación de guía de despacho.
- Orden de compra asociada.
- Recepción conforme de mercadería.
- Documento comercial asociado.

Modelo de datos sugerido:
El agente debe implementar una entidad/estructura asociada al DTE, por ejemplo:

DteReferencia
- id
- dte_id
- nro_linea
- tipo_documento_referencia
- folio_referencia
- fecha_referencia
- codigo_referencia
- razon_referencia
- categoria_referencia
- created_at
- updated_at

categoria_referencia puede ser útil para separar:
- DTE
- DOCUMENTO_COMERCIAL
- DOCUMENTO_INTERNO
- OTRO

Validaciones mínimas:

1) Un DTE puede tener cero, una o muchas referencias.

2) Si existen referencias:
- NroLinRef debe ser correlativo.
- TpoDocRef es obligatorio.
- FolioRef es obligatorio.
- FchRef es obligatorio.
- RazonRef debe ser opcional, pero recomendable.
- CodRef debe ser opcional para DTE 33.
- No duplicar NroLinRef.
- Mantener el orden de las referencias.

3) Validar formato de fecha:
YYYY-MM-DD

4) Validar largo máximo de textos según formato SII.

5) Validar que TpoDocRef exista en un catálogo interno de tipos de referencia.

Catálogo recomendado:
No hardcodear los tipos de referencia directamente en la lógica del XML.
Crear o utilizar un catálogo configurable:

TipoReferencia
- codigo_sii
- nombre
- categoria
- activo
- requiere_folio
- requiere_fecha
- permite_codigo_referencia
- observacion

Ejemplos de catálogo:

codigo_sii: 52
nombre: Guía de Despacho Electrónica
categoria: DTE

codigo_sii: 801
nombre: Orden de Compra
categoria: DOCUMENTO_COMERCIAL

codigo_sii: 802
nombre: Recepción de Mercadería / Servicio
categoria: DOCUMENTO_COMERCIAL

Uso típico en Factura 33:

Caso 1:
Factura emitida a partir de una Guía de Despacho.

Referencia:
- TpoDocRef: 52
- FolioRef: folio de la guía
- FchRef: fecha de la guía
- RazonRef: Facturación de guía de despacho

Caso 2:
Factura emitida contra una Orden de Compra.

Referencia:
- TpoDocRef: 801
- FolioRef: número de OC
- FchRef: fecha de OC
- RazonRef: Orden de compra del cliente

Caso 3:
Factura emitida contra una recepción conforme.

Referencia:
- TpoDocRef: 802
- FolioRef: número de recepción / HES / MIGO / documento equivalente
- FchRef: fecha de recepción
- RazonRef: Recepción conforme

UI / API:
La pantalla o endpoint de emisión de Factura 33 debe permitir ingresar múltiples referencias.

Cada referencia debe permitir:
- seleccionar tipo de documento referenciado
- ingresar folio o número
- ingresar fecha
- ingresar razón o glosa
- ingresar código de referencia solo si corresponde

Ejemplo de request conceptual:

{
  "tipo_dte": 33,
  "folio": 123,
  "receptor": { ... },
  "detalles": [ ... ],
  "referencias": [
    {
      "tipo_documento_referencia": "52",
      "folio_referencia": "4589",
      "fecha_referencia": "2026-06-29",
      "razon_referencia": "Facturación de guía de despacho"
    },
    {
      "tipo_documento_referencia": "801",
      "folio_referencia": "OC-4500123456",
      "fecha_referencia": "2026-06-20",
      "razon_referencia": "Orden de compra asociada"
    }
  ]
}

Resultado XML esperado:

<Referencia>
  <NroLinRef>1</NroLinRef>
  <TpoDocRef>52</TpoDocRef>
  <FolioRef>4589</FolioRef>
  <FchRef>2026-06-29</FchRef>
  <RazonRef>Facturación de guía de despacho</RazonRef>
</Referencia>

<Referencia>
  <NroLinRef>2</NroLinRef>
  <TpoDocRef>801</TpoDocRef>
  <FolioRef>OC-4500123456</FolioRef>
  <FchRef>2026-06-20</FchRef>
  <RazonRef>Orden de compra asociada</RazonRef>
</Referencia>

PDF:
Si el DTE tiene referencias, el PDF también debe mostrarlas en una sección llamada “Referencias” o “Documentos Referenciados”.

Columnas sugeridas:
- Tipo documento
- Folio
- Fecha
- Razón

Regla importante:
Las referencias deben quedar reflejadas tanto en:
- base de datos
- XML DTE
- PDF del DTE

No deben ser solo texto visual del PDF.

Criterios de aceptación:

1) Se puede emitir una Factura Electrónica Tipo 33 sin referencias.

2) Se puede emitir una Factura Electrónica Tipo 33 con una referencia.

3) Se puede emitir una Factura Electrónica Tipo 33 con múltiples referencias.

4) Las referencias aparecen en el XML después de los detalles y descuentos/recargos globales, y antes del TED.

5) Las referencias se numeran con NroLinRef correlativo.

6) Las referencias aparecen en el PDF.

7) El sistema permite referenciar al menos:
- Guía de Despacho Electrónica 52
- Orden de Compra 801
- Recepción de Mercadería / Servicio 802

8) El diseño debe permitir agregar nuevos tipos de referencia sin cambiar el generador XML.

9) El campo CodRef debe ser opcional para Factura 33 y no debe enviarse vacío si no corresponde.

10) El XML final debe seguir siendo firmado correctamente después de incorporar las referencias.
